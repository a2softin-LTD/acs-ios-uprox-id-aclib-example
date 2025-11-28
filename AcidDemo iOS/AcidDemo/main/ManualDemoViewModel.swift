//
//  ManualDemoViewModel.swift
//  Acid_Demo
//
//  Created by Codex on 11.04.2024.
//

import Combine
import Foundation
import u_prox_id_lib

final class ManualDemoViewModel: ObservableObject {
    @Published var powerCorrection: Double = AppPreferences.powerCorrection
    @Published var keys: [AccessKey] = []
    @Published var selectedKeyID: UUID?
    @Published var qrInput: String = ""
    @Published var isRequestingDesktop: Bool = false
    @Published var desktopResult: RequestKeyFromDesktopReaderResult?
    @Published var devices: [AccessPoint] = []
    @Published var selectedDeviceID: UUID?
    @Published var isSearchingDevices: Bool = false
    @Published var isConnecting: Bool = false
    @Published var accessResult: RequestAccessResult?
    @Published var statusMessage: String = ""

    private var bleService: BluetoothService = .init()
    private let keysService: AccessKeysService = .init()
    private var discoveredPoints: [AccessPoint] = []

    private let minPowerCorrection: Double = 0.2
    private let maxPowerCorrection: Double = 1.6

    init() {
        self.bleService.powerCorrection = self.powerCorrection
    }

    func onAppear() {
        Task { await self.loadKeys() }
    }

    func updatePowerCorrection(_ value: Double) {
        let bounded = min(max(value, self.minPowerCorrection), self.maxPowerCorrection)
        self.powerCorrection = bounded
        AppPreferences.powerCorrection = bounded
        self.bleService.powerCorrection = bounded
    }

    func requestDesktopKey() {
        guard !self.isRequestingDesktop else { return }
        self.isRequestingDesktop = true
        self.desktopResult = nil
        self.statusMessage = "Запит до desktop рідера..."

        DispatchQueue.global(qos: .userInitiated).async {
            self.bleService.requestKeyFromDesktopReader { [weak self] result in
                guard let self else { return }
                Task { await self.handleDesktopResult(result) }
            }
        }
    }

    func searchDevices() {
        guard !self.isSearchingDevices else { return }
        self.isSearchingDevices = true
        self.devices = []
        self.discoveredPoints = []
        self.selectedDeviceID = nil
        self.statusMessage = "Сканування..."

        self.bleService.discoverAccessPoints { [weak self] points in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isSearchingDevices = false
                self.discoveredPoints = points
                self.devices = points
                self.statusMessage = points.isEmpty ? "Девайси не знайдені" : "Знайдено \(points.count)"
            }
        }
    }

    func connectSelected() {
        guard let key = self.selectedKey else {
            self.statusMessage = "Оберіть ключ"
            return
        }
        guard let point = self.discoveredPoints.first(where: { $0.identifier == self.selectedDeviceID }) else {
            self.statusMessage = "Оберіть девайс"
            return
        }
        guard !self.isConnecting else { return }

        self.isConnecting = true
        self.accessResult = nil
        self.statusMessage = "Підключення..."

        self.bleService.connect(
            to: point,
            key: key,
            completion: { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isConnecting = false
                    self.accessResult = result
                    self.statusMessage = self.message(for: result)
                }
            }
        )
    }

    func selectKey(_ id: UUID) {
        self.selectedKeyID = id
    }

    func selectDevice(_ id: UUID) {
        self.selectedDeviceID = id
    }

    private var selectedKey: AccessKey? {
        guard let id = self.selectedKeyID else { return nil }
        return self.keys.first(where: { $0.id == id })
    }

    private func loadKeys() async {
        let list = await self.keysService.getKeys()
        await MainActor.run {
            self.keys = list
            if self.selectedKeyID == nil {
                self.selectedKeyID = list.first?.id
            }
        }
    }

    @MainActor
    private func handleDesktopResult(_ result: RequestKeyFromDesktopReaderResult) async {
        self.isRequestingDesktop = false
        self.desktopResult = result
        self.statusMessage = self.message(for: result)
        if result == .success {
            await self.loadKeys()
        }
    }

    func message(for result: RequestAccessResult) -> String {
        switch result {
        case .granted: return "Доступ надано"
        case .accepted: return "Запит прийнято"
        case .denied: return "Доступ відхилено"
        case .timeout: return "Час очікування вийшов"
        case .noAccessKeyForReader: return "Немає ключа для цього рідера"
        case .bluetoothPowerOff: return "Bluetooth вимкнено"
        case .unidentified: return "Невідомий статус"
        case .error: return "Помилка з’єднання"
        default: return "Невідома помилка"
        }
    }

    func message(for result: RequestKeyFromDesktopReaderResult) -> String {
        switch result {
        case .success: return "Ключ додано з desktop рідера"
        case .rejected: return "Відмовлено рідером"
        case .keyTypeAlreadyExists: return "Такий ключ вже існує"
        case .noKeyLeft: return "Немає ключів"
        case .noMasterCard: return "Покладіть мастер-карту"
        case .bluetoothPowerOff: return "Bluetooth вимкнено"
        case .unknown: return "Невідомий статус"
        default: return "Невідома помилка"
        }
    }

    func message(for result: RequestKeyFromServerResult) -> String {
        switch result {
        case .success: return "Ключ додано за QR"
        case .rejected: return "QR відхилено"
        case .keyTypeAlreadyExists: return "Такий ключ вже існує"
        case let .unknown(error): return error.localizedDescription
        default: return "Невідома помилка"
        }
    }
}
