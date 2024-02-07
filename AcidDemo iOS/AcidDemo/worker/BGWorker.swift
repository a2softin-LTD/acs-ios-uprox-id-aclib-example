//
//  BGWorker.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import u_prox_id_lib
import CoreLocation
import Foundation
import UIKit


final class BackgroundOpenDoorService {
    
    @Storage(key: "BackgroundOpenDoorService.Key", defaultValue: false, shared: .base)
    private static var onStarted: Bool
    
    static func onRefresh() {
        guard !Self.onStarted else { return }
        if AppPreferences.handsFreeMode || AppPreferences.turnByScreenMode {
            AppBLEBackgroundWorker.shared.startMonitoring()
            Self.onStarted = true
        }
    }
    
    static func onStart() {
        Self.onStarted = false
        Self.onRefresh()
    }
}

fileprivate final class AppBLEBackgroundWorker: NSObject {

  //MARK: - Private Enum

  private enum BgAccessRequestTaskType {
    case handsFree  // увімкнено режим вільні руки
    case onTurnOnScreen  // увімкнено режим по вкл екрану
    case disabledAll  // вимкнено все
  }

  //MARK: - Singleton

  public static let shared = AppBLEBackgroundWorker()

  //MARK: - Private Constants

  private let beaconRegionUUID = "6DBA3E9E-F6E0-4B65-B6A8-1C259E306918"
  private let minimumValidRSSIValue = -65

  //MARK: - Private Properties

  private var bleService: BluetoothService
  private let bgTask: BackgroundTask = .init()
  private var keysService: AccessKeysService
  private lazy var locationManager: CLLocationManager = CLLocationManager()
  private lazy var regions: [CLBeaconRegion] = []

  //private var isAppWorkingInBackgroud: Bool = false  // перевірка чи додаток знаходиться в background
  private var lastTypeCLProximity: CLProximity?  // останнє збережене значення дистанції до маячка
  private var handsFreeCommandInProcess: Bool = false  // в процесі виконнаня команди на відкривання дверей
  private var beaconScannerWasStarted: Bool = false

  //MARK:  - Private Init

  private override init() {
    self.bleService = .init()
    self.keysService = .init()
    super.init()
      if AppPreferences.handsFreeMode || AppPreferences.turnByScreenMode {
          self.notifyLocation()
          self.updateBeaconRegionArray()
          self.stopBeaconsScanner()
          self.subscribeOnNotifications()
      }
  }

  //MARK: - Private Computed Properties

  private var bgTaskType: BgAccessRequestTaskType {
    if AppPreferences.turnByScreenMode {
      return .onTurnOnScreen
    } else if AppPreferences.handsFreeMode {
      return .handsFree
    } else {
      return .disabledAll
    }
  }

  //MARK: - Public Methods

  public func startMonitoring() {
    self.subscribeOnDisplayStatus()
  }
}

extension AppBLEBackgroundWorker {

  //MARK: - Private Methods (AcidRequestTask)

    private func sendCommand(_ timeout: Double = 0.5) {
        Task {
            let selected = await self.keysService.getKeys().filter { $0.isKeySelected }
            if selected.isEmpty {
                self.stopBeaconsScanner()
                self.handsFreeCommandInProcess = false
            } else {
                self.bgTask.registerBackgroundTask()
                self.bleService.powerCorrection = AppPreferences.powerCorrection
                DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { [ weak self] in
                    guard let self = self else { return }
                    self.bleService.requestAccessBackground(keyID: selected.first!.id) { [weak self] result in
                        guard let self = self else { return }
                        self.bgTask.endBackgroundTask()
                        switch self.bgTaskType {
                        case .onTurnOnScreen:
                          self.stopBeaconsScanner()
                        case .handsFree:
                          self.handsFreeCommandInProcess = false
                        default:
                          break
                        }
                    }
                }
            }
        }
  }
}

extension AppBLEBackgroundWorker: CLLocationManagerDelegate {

  public func locationManager(
    _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
  ) {
    //print("status changed")
    if status == .authorizedAlways || status == .authorizedWhenInUse {
      //print("we got permission")
      //self.isEnabled = true
      self.locationManager.startMonitoringSignificantLocationChanges()
    } else {
      //self.isEnabled = false
      //print("nope")
    }
  }
}

extension AppBLEBackgroundWorker {

  func locationManager(
    _ manager: CLLocationManager,
    didRangeBeacons beacons: [CLBeacon],
    in region: CLBeaconRegion
  ) {
    guard self.bgTaskType == .handsFree && UIApplication.shared.applicationState != .active else {
      return
    }
    // Перевірка на результат сканування, дається 5 спроб, якщо після 5ти викликів не знайдено необхідних маячків - зупиняємо сканування beacon
    // до наступного виклику didEnterRegion
    guard !beacons.isEmpty else {
      //Log.write("(Hands Free Mode) No iBeacons registered found")
      self.lastTypeCLProximity = nil
      return
    }
    self.preparationForFindingRighBeacon(beacons: beacons, region: region)
  }

  func locationManager(
    _ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion
  ) {
    if self.bgTaskType == .handsFree
      && UIApplication.shared.applicationState != .active
    {
      switch state {
      case .inside:
        //Log.write("(Hands Free Mode) Located in the area of the registered iBeacon")
        self.startBeaconsScanner()
      case .outside:
        self.lastTypeCLProximity = nil
        //Log.write("(Hands Free Mode) Went out of the area of the registered iBeacon")
        self.stopBeaconsScanner()
      default:
        break
      }
    }
  }

  /// Метод слугує для перевірки результату сканування ibeacons маячків
  /// здійснюється фільтрування на валідність маячків, та сортування за дистанцією
  /// - Parameters:
  ///   - beacons: отриманий масив маяків від рузультату сканування
  ///   - region: регіон для спрацювання
  private func preparationForFindingRighBeacon(beacons: [CLBeacon], region: CLBeaconRegion) {
    if self.bgTaskType == .handsFree,
      UIApplication.shared.applicationState != .active
    {
      if self.regions.contains(region) {
        let sortedBeacons =
          beacons
          .filter { $0.proximity != .unknown }
          .sorted(by: { ($0.proximity.rawValue < $1.proximity.rawValue) })
        if let findedBeacon = sortedBeacons.first {
          self.preparingToSendAccessKeyOnHandsFreeMode(
            findedBeacon.proximity,
            rssi: findedBeacon.rssi
          )
        }
      }
    }
  }

  /// Підготовка для відправки BLE команди до найближчого зчитувача
  /// припускається що при знаходженні найближчого маяка - буде зчитувач з яким потрібно встановити з'єднання.
  /// Найближчим маяком рахується той маяк, в якого значення distance == immediate.
  /// Для першої спроби не враховується rssi значення - для збільшення проценту вдалого виконання команди.
  /// Для наступних спроб, щоби відсіяти зайві спрацювання зчитувача, до перевірки включається значення rssi
  /// воно повинне бути не менше -60 dbi, за такого способу наступні рази команда на BLE буде відправлятись тільки, коли телефон знаходиться впритул до зчитувача
  /// - Parameters:
  ///   - distance: приблизна відстань до маяка (immediate 0...2 метрів, near  2...4 метра,  far 4> метрів)
  ///   - rssi: значення рівня потужності сигналу
  private func preparingToSendAccessKeyOnHandsFreeMode(_ distance: CLProximity, rssi: Int) {
    if !self.handsFreeCommandInProcess {
      if self.lastTypeCLProximity != .immediate
        && distance == .immediate
      {
        self.handsFreeCommandInProcess = true
        //Log.write(String(format: "%@ [distance - %@, rssi - %d]", "Founded iBeacon, first try", distance.description, rssi))
        self.sendCommand(0.5)
      } else if distance == .immediate && rssi > self.minimumValidRSSIValue {
        self.handsFreeCommandInProcess = true
        //Log.write(String(format: "%@ [distance - %@, min rssi - %d, rssi - %d]", "Founded iBeacon, second try", distance.description, minimumValidRSSIValue, rssi))
        self.sendCommand(3.0)
      }
    }
    self.lastTypeCLProximity = distance
  }
}

extension AppBLEBackgroundWorker {

  //MARK: - Public Methods (Core Location)

  /// Підписка на геолокацію
  public func notifyLocation() {
    self.locationManager.requestAlwaysAuthorization()
    self.locationManager.delegate = self
    self.locationManager.startUpdatingLocation()
    self.locationManager.startMonitoringSignificantLocationChanges()
    self.locationManager.allowsBackgroundLocationUpdates = true
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
  }

  //MARK: - Private Methods (Core Location)

  func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
    locationManager.requestState(for: region)
  }

  /// Нотифікує про вхід телефону в зону дії маяків з однаковим UUID і після запускає сканування маяків
  /// Нотифікація відбувається і при умові покидання зони дії маяка і коли здійснили перемикання живлення маяка
  func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
    self.lastTypeCLProximity = nil
    self.startBeaconsScanner()
    //Log.write("(Hands Free Mode) Located in the area of the registered iBeacon")
  }

  /// Нотифікує про вихід телефону з зони дії маяків з однаковим UUID і після зупиняє сканування маяків
  /// Це необхідно для зменшення споживання заряду телефону
  /// Нотифікація відбувається тільки при умові покидання зони дії маяка, якщо вимкнути живлення маяку - ніяких нотифікацій не буде
  func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
    self.lastTypeCLProximity = nil
    self.stopBeaconsScanner()
    //Log.write("(Hands Free Mode) Went out of the area of the registered iBeacon")
  }

}

extension AppBLEBackgroundWorker {

  //MARK: - Private Methods (IBeacon)

  /// Додавання потрібного регіону для подальшого сканування потрібних маяків
  private func updateBeaconRegionArray() {
    let uuid: UUID = UUID(uuidString: self.beaconRegionUUID)!
    let clBeaconRegion: CLBeaconRegion = CLBeaconRegion(
      proximityUUID: uuid, identifier: uuid.uuidString)
    self.regions.append(clBeaconRegion)
  }

  /// Запуск сканування маяків та підписка на нотифікації по входу/виходу з регіону
  private func startBeaconsScanner() {
    guard !self.beaconScannerWasStarted else { return }
    self.beaconScannerWasStarted = true
    for region in regions {
      region.notifyOnEntry = true
      region.notifyOnExit = true
      region.notifyEntryStateOnDisplay = true
      locationManager.startMonitoring(for: region)
      locationManager.startRangingBeacons(in: region)
    }
  }

  //Зупинення сканування маяків
  private func stopBeaconsScanner() {
    self.beaconScannerWasStarted = false
    for region in regions {
      locationManager.stopRangingBeacons(in: region)
    }
  }

}

extension AppBLEBackgroundWorker {

  //MARK: - Private Methods (Notification Center)

  /// Підписка на отримання Дарвін нотифікацій про вкл/викл екрану телефону
  private func subscribeOnDisplayStatus() {
    DisplayManager.methodStart()
  }

  private func subscribeOnNotifications() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(applicationDidEnterBackgroundActive(_:)),
      name: UIApplication.didEnterBackgroundNotification, object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(applicationWillEnterForegroundActive(_:)),
      name: UIApplication.willEnterForegroundNotification, object: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(willTerminateNotification(_:)),
      name: UIApplication.willTerminateNotification, object: nil)

    NotificationCenter.default.addObserver(
      self, selector: #selector(displayOn), name: NSNotification.Name(keyNotifDisplayOn),
      object: nil)
    NotificationCenter.default.addObserver(
      self, selector: #selector(displayOff), name: NSNotification.Name(keyNotifDisplayOff),
      object: nil)
  }

  @objc private func willTerminateNotification(_ notification: Notification) {
    if self.bgTaskType == .handsFree {
      self.startBeaconsScanner()
        self.writeLog(m: "App will terminate notification")
    }
  }

  @objc private func applicationDidEnterBackgroundActive(_ notification: Notification) {
    if self.bgTaskType == .handsFree {
      self.startBeaconsScanner()
    }
  }

  @objc private func applicationWillEnterForegroundActive(_ notification: Notification) {
    self.lastTypeCLProximity = nil
    self.stopBeaconsScanner()
  }

  @objc private func displayOn(_ notification: Notification) {
    switch self.bgTaskType {
    case .onTurnOnScreen:
      self.sendCommand()
      self.startBeaconsScanner()
    case .handsFree:
      self.startBeaconsScanner()
    default:
      break
    }
  }

  @objc private func displayOff(_ notification: Notification) {
    self.bgTask.endBackgroundTask()
  }

  private func writeLog(m: String) {
      //Log.write(m)
  }
}

extension CLProximity {
  var description: String {
    switch self.rawValue {
    case 1: return "Immediate"
    case 2: return "Near"
    case 3: return "Far"
    default: return "Unknown"
    }
  }
}


public class BackgroundTask {
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    public func registerBackgroundTask() {
        DispatchQueue.global().async {
            self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: Bundle.main.bundleIdentifier, expirationHandler: {
                self.endBackgroundTask()
            })
        }
    }

    /// Ends long-running background task. Called when app comes to foreground from background
    public func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
    }
}
