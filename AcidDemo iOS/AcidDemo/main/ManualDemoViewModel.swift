//
//  ManualDemoViewModel.swift
//  Acid_Demo
//
//  Created by Codex on 11.04.2024.
//

import Combine
import Foundation
import u_prox_id_lib

/// Drives the "Manual" tab: every step (discover, pick a reader, pick a key,
/// connect) is done explicitly instead of letting the library decide.
@MainActor
final class ManualDemoViewModel: ObservableObject {

    // MARK: - Properties

    @Published var powerCorrection: Double = AppPreferences.powerCorrection

    @Published private(set) var keys: [AccessKey] = []
    @Published private(set) var selectedKeyID: UUID?
    @Published private(set) var isRequestingDesktop: Bool = false

    @Published private(set) var devices: [AccessPoint] = []
    @Published private(set) var selectedDeviceID: UUID?
    @Published private(set) var isSearchingDevices: Bool = false

    @Published private(set) var isConnecting: Bool = false
    @Published private(set) var status: DemoStatus?

    // MARK: - Private Properties

    private var bleService: BluetoothService = .init()
    private let keysService: AccessKeysService = .init()
    private var bag: Set<AnyCancellable> = []

    var canConnect: Bool {
        self.selectedKeyID != nil && self.selectedDeviceID != nil
    }

    init() {
        self.bleService.powerCorrection = self.powerCorrection

        self.$powerCorrection
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] value in
                AppPreferences.powerCorrection = value
                self?.bleService.powerCorrection = value
            }
            .store(in: &self.bag)
    }

    // MARK: - Public Methods

    func onAppear() {
        Task { await self.loadKeys() }
    }

    func requestDesktopKey() {
        guard !self.isRequestingDesktop else { return }
        self.isRequestingDesktop = true
        self.status = .info("Waiting for a desktop reader…")

        self.bleService.requestKeyFromDesktopReader { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isRequestingDesktop = false
                self.status = result.status
                if result == .success {
                    await self.loadKeys()
                }
            }
        }
    }

    func searchDevices() {
        guard !self.isSearchingDevices else { return }
        self.isSearchingDevices = true
        self.devices = []
        self.selectedDeviceID = nil
        self.status = .info("Scanning for readers…")

        self.bleService.discoverAccessPoints { [weak self] points in
            Task { @MainActor in
                guard let self else { return }
                self.isSearchingDevices = false
                self.devices = points
                self.status =
                    points.isEmpty
                    ? .failure("No readers found")
                    : .success("Found \(points.count) reader(s)")
            }
        }
    }

    func connectSelected() {
        guard !self.isConnecting else { return }
        guard let key = self.selectedKey else {
            self.status = .info("Select a key first")
            return
        }
        guard let point = self.devices.first(where: { $0.identifier == self.selectedDeviceID }) else {
            self.status = .info("Select a reader first")
            return
        }

        self.isConnecting = true
        self.status = .info("Connecting to \(point.demoTitle)…")

        self.bleService.connect(to: point, key: key) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isConnecting = false
                self.status = result.status
            }
        }
    }

    func selectKey(_ id: UUID) {
        self.selectedKeyID = id
    }

    func selectDevice(_ id: UUID) {
        self.selectedDeviceID = id
    }

    // MARK: - Private Methods

    private var selectedKey: AccessKey? {
        guard let id = self.selectedKeyID else { return nil }
        return self.keys.first(where: { $0.id == id })
    }

    private func loadKeys() async {
        let list = await self.keysService.getKeys()
        self.keys = list
        if self.selectedKeyID == nil || !list.contains(where: { $0.id == self.selectedKeyID }) {
            self.selectedKeyID = list.first(where: { $0.isKeySelected })?.id ?? list.first?.id
        }
    }
}
