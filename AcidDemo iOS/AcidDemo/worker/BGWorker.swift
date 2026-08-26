//
//  BGWorker.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import CoreLocation
import Foundation
import UIKit
import u_prox_id_lib

/// Keeps the background worker in sync with the "hands free" / "turn on screen"
/// preferences. Call `onStart()` once at launch and `onRefresh()` whenever a
/// preference changes or the scene phase changes.
enum BackgroundOpenDoorService {

    private static let isRunningStorage = Storage<Bool>(
        key: "BackgroundOpenDoorService.Key",
        defaultValue: false,
        shared: .base
    )

    private static var isRunning: Bool {
        get { isRunningStorage.wrappedValue }
        set { isRunningStorage.wrappedValue = newValue }
    }

    /// `true` when at least one background unlock mode is switched on.
    static var isEnabled: Bool {
        AppPreferences.handsFreeMode || AppPreferences.turnByScreenMode
    }

    /// Starts or stops monitoring so that it matches the current preferences.
    @MainActor
    static func onRefresh() {
        switch (Self.isEnabled, Self.isRunning) {
        case (true, false):
            AppBLEBackgroundWorker.shared.startMonitoring()
            Self.isRunning = true
        case (false, true):
            AppBLEBackgroundWorker.shared.stopMonitoring()
            Self.isRunning = false
        default:
            break
        }
    }

    /// Called at launch: the process is new, so nothing is monitoring yet.
    @MainActor
    static func onStart() {
        Self.isRunning = false
        Self.onRefresh()
    }
}

// MARK: - Worker

/// Opens the door without user interaction, either when the phone comes very
/// close to a registered iBeacon ("hands free") or when the screen is switched
/// on ("turn on screen").
///
/// All mutable state lives on the main actor. `CLLocationManager` delivers its
/// callbacks on the queue it was created on — the worker is only ever created
/// from the main actor, so `MainActor.assumeIsolated` is valid in the delegate
/// methods below.
@MainActor
private final class AppBLEBackgroundWorker: NSObject {

    // MARK: - Private Enum

    private enum BgAccessRequestTaskType {
        case handsFree  // "hands free" mode is on
        case onTurnOnScreen  // "unlock on screen wake" mode is on
        case disabledAll  // everything is off
    }

    // MARK: - Singleton

    static let shared = AppBLEBackgroundWorker()

    // MARK: - Private Constants

    private let beaconRegionUUID = UUID(uuidString: "6DBA3E9E-F6E0-4B65-B6A8-1C259E306918")!
    private let minimumValidRSSIValue = -65

    // MARK: - Private Properties

    private var bleService: BluetoothService = .init()
    private let bgTask: BackgroundTask = .init()
    private let keysService: AccessKeysService = .init()
    private lazy var locationManager: CLLocationManager = CLLocationManager()

    private lazy var beaconRegion: CLBeaconRegion = CLBeaconRegion(
        uuid: self.beaconRegionUUID,
        identifier: self.beaconRegionUUID.uuidString
    )
    private lazy var beaconConstraint: CLBeaconIdentityConstraint = CLBeaconIdentityConstraint(
        uuid: self.beaconRegionUUID
    )

    /// Cached foreground flag. Reading `UIApplication.shared.applicationState`
    /// from every delegate callback is both slow and main-actor bound, so the
    /// value is kept up to date from the lifecycle notifications instead.
    private var isAppActive: Bool = true
    private var lastTypeCLProximity: CLProximity?
    private var handsFreeCommandInProcess: Bool = false
    private var beaconScannerWasStarted: Bool = false
    private var isMonitoring: Bool = false

    // MARK: - Private Init

    private override init() {
        super.init()
        self.subscribeOnNotifications()
    }

    // MARK: - Private Computed Properties

    private var bgTaskType: BgAccessRequestTaskType {
        if AppPreferences.turnByScreenMode {
            return .onTurnOnScreen
        } else if AppPreferences.handsFreeMode {
            return .handsFree
        } else {
            return .disabledAll
        }
    }

    // MARK: - Public Methods

    func startMonitoring() {
        guard !self.isMonitoring else { return }
        self.isMonitoring = true

        self.notifyLocation()
        self.locationManager.startMonitoring(for: self.configuredBeaconRegion())
        DisplayManager.methodStart()
    }

    func stopMonitoring() {
        guard self.isMonitoring else { return }
        self.isMonitoring = false

        DisplayManager.methodStop()
        self.stopBeaconsScanner()
        self.locationManager.stopMonitoring(for: self.beaconRegion)
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.stopUpdatingLocation()
        self.lastTypeCLProximity = nil
        self.handsFreeCommandInProcess = false
    }
}

// MARK: - Access request

extension AppBLEBackgroundWorker {

    /// Sends the currently selected key to the nearest reader.
    ///
    /// - Parameter timeout: delay before the BLE command is sent. The first
    ///   attempt fires almost immediately, later attempts wait longer so the
    ///   phone has time to settle next to the reader.
    private func sendCommand(_ timeout: Duration = .milliseconds(500)) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let key = await self.keysService.getKeys().first(where: { $0.isKeySelected }) else {
                self.stopBeaconsScanner()
                self.handsFreeCommandInProcess = false
                return
            }

            self.bgTask.begin()
            self.bleService.powerCorrection = AppPreferences.powerCorrection

            try? await Task.sleep(for: timeout)

            self.bleService.requestAccessBackground(keyID: key.id) { _ in
                Task { @MainActor in
                    self.bgTask.end()
                    switch self.bgTaskType {
                    case .onTurnOnScreen:
                        self.stopBeaconsScanner()
                    case .handsFree:
                        self.handsFreeCommandInProcess = false
                    case .disabledAll:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension AppBLEBackgroundWorker: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        MainActor.assumeIsolated {
            switch self.locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                self.locationManager.startMonitoringSignificantLocationChanges()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didRange beacons: [CLBeacon],
        satisfying beaconConstraint: CLBeaconIdentityConstraint
    ) {
        // `CLBeacon` is not `Sendable`; pull out the two values we need before
        // hopping onto the main actor.
        let nearest =
            beacons
            .filter { $0.proximity != .unknown }
            .map { (proximity: $0.proximity, rssi: $0.rssi) }
            .min(by: { $0.proximity.rawValue < $1.proximity.rawValue })

        MainActor.assumeIsolated {
            guard self.bgTaskType == .handsFree, !self.isAppActive else { return }
            guard let nearest else {
                self.lastTypeCLProximity = nil
                return
            }
            self.preparingToSendAccessKeyOnHandsFreeMode(nearest.proximity, rssi: nearest.rssi)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        MainActor.assumeIsolated {
            guard self.bgTaskType == .handsFree, !self.isAppActive else { return }
            switch state {
            case .inside:
                self.startBeaconsScanner()
            case .outside:
                self.lastTypeCLProximity = nil
                self.stopBeaconsScanner()
            case .unknown:
                break
            @unknown default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didStartMonitoringFor region: CLRegion
    ) {
        MainActor.assumeIsolated {
            self.locationManager.requestState(for: self.beaconRegion)
        }
    }

    /// The phone entered the area covered by beacons with the registered UUID.
    /// Fires both on entering the area and when a beacon is powered back on.
    nonisolated func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        MainActor.assumeIsolated {
            self.lastTypeCLProximity = nil
            self.startBeaconsScanner()
        }
    }

    /// The phone left the area covered by the registered beacons; ranging is
    /// stopped to save battery. Note that powering a beacon off does not fire
    /// this callback.
    nonisolated func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        MainActor.assumeIsolated {
            self.lastTypeCLProximity = nil
            self.stopBeaconsScanner()
        }
    }

    /// Decides whether the BLE unlock command should be sent to the nearest reader.
    ///
    /// The assumption is that the nearest beacon belongs to the reader we want
    /// to talk to. "Nearest" means `proximity == .immediate`.
    /// The first attempt ignores RSSI to maximise the success rate. Later
    /// attempts also require RSSI above `minimumValidRSSIValue`, so repeated
    /// commands are only sent when the phone is right next to the reader.
    ///
    /// - Parameters:
    ///   - distance: approximate distance (immediate 0…2 m, near 2…4 m, far 4 m+)
    ///   - rssi: signal strength
    private func preparingToSendAccessKeyOnHandsFreeMode(_ distance: CLProximity, rssi: Int) {
        defer { self.lastTypeCLProximity = distance }
        guard !self.handsFreeCommandInProcess, distance == .immediate else { return }

        if self.lastTypeCLProximity != .immediate {
            self.handsFreeCommandInProcess = true
            self.sendCommand(.milliseconds(500))
        } else if rssi > self.minimumValidRSSIValue {
            self.handsFreeCommandInProcess = true
            self.sendCommand(.seconds(3))
        }
    }
}

// MARK: - Core Location

extension AppBLEBackgroundWorker {

    private func notifyLocation() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
        self.locationManager.startMonitoringSignificantLocationChanges()
    }

    private func configuredBeaconRegion() -> CLBeaconRegion {
        self.beaconRegion.notifyOnEntry = true
        self.beaconRegion.notifyOnExit = true
        self.beaconRegion.notifyEntryStateOnDisplay = true
        return self.beaconRegion
    }

    private func startBeaconsScanner() {
        guard !self.beaconScannerWasStarted else { return }
        self.beaconScannerWasStarted = true
        self.locationManager.startRangingBeacons(satisfying: self.beaconConstraint)
    }

    private func stopBeaconsScanner() {
        guard self.beaconScannerWasStarted else { return }
        self.beaconScannerWasStarted = false
        self.locationManager.stopRangingBeacons(satisfying: self.beaconConstraint)
    }
}

// MARK: - Notification Center

extension AppBLEBackgroundWorker {

    private func subscribeOnNotifications() {
        let center = NotificationCenter.default
        center.addObserver(
            self, selector: #selector(applicationDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification, object: nil)
        center.addObserver(
            self, selector: #selector(applicationDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil)
        center.addObserver(
            self, selector: #selector(applicationWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil)
        center.addObserver(
            self, selector: #selector(applicationWillTerminate),
            name: UIApplication.willTerminateNotification, object: nil)

        // Posted by `DisplayManager` on the main queue.
        center.addObserver(
            self, selector: #selector(displayOn),
            name: NSNotification.Name(keyNotifDisplayOn), object: nil)
        center.addObserver(
            self, selector: #selector(displayOff),
            name: NSNotification.Name(keyNotifDisplayOff), object: nil)
    }

    @objc private func applicationWillTerminate() {
        guard self.isMonitoring, self.bgTaskType == .handsFree else { return }
        self.startBeaconsScanner()
    }

    @objc private func applicationDidBecomeActive() {
        self.isAppActive = true
    }

    @objc private func applicationDidEnterBackground() {
        self.isAppActive = false
        guard self.isMonitoring, self.bgTaskType == .handsFree else { return }
        self.startBeaconsScanner()
    }

    @objc private func applicationWillEnterForeground() {
        self.isAppActive = true
        self.lastTypeCLProximity = nil
        self.stopBeaconsScanner()
    }

    @objc private func displayOn() {
        guard self.isMonitoring else { return }
        switch self.bgTaskType {
        case .onTurnOnScreen:
            self.sendCommand()
            self.startBeaconsScanner()
        case .handsFree:
            self.startBeaconsScanner()
        case .disabledAll:
            break
        }
    }

    @objc private func displayOff() {
        self.bgTask.end()
    }
}

// MARK: - Background task

/// Thin wrapper over `UIApplication`'s background task API. Kept on the main
/// actor because `beginBackgroundTask` / `endBackgroundTask` are UIKit calls.
@MainActor
final class BackgroundTask {

    private var identifier: UIBackgroundTaskIdentifier = .invalid

    /// Buys extra background execution time. No-op when a task is already running.
    func begin() {
        guard self.identifier == .invalid else { return }
        self.identifier = UIApplication.shared.beginBackgroundTask(
            withName: Bundle.main.bundleIdentifier,
            expirationHandler: { [weak self] in
                MainActor.assumeIsolated { self?.end() }
            }
        )
    }

    /// Ends the background task. Safe to call when no task is running —
    /// passing `.invalid` to `endBackgroundTask` is an API misuse.
    func end() {
        guard self.identifier != .invalid else { return }
        UIApplication.shared.endBackgroundTask(self.identifier)
        self.identifier = .invalid
    }
}

// MARK: - Helpers

extension CLProximity {

    var description: String {
        switch self {
        case .immediate: return "Immediate"
        case .near: return "Near"
        case .far: return "Far"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}
