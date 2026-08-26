//
//  MainViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

@preconcurrency import Combine
import Foundation
import u_prox_id_lib

/// Drives the "Standard" tab: the library picks the reader and the key on its own.
@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Properties

    @Published private(set) var keys: [AccessKey] = []
    @Published var selectedKeyIndex: Int = 0

    @Published var powerCorrection: Double
    @Published var turnOnDisplay: Bool
    @Published var handsFreeMode: Bool

    @Published private(set) var status: DemoStatus?
    @Published private(set) var isOpeningDoor: Bool = false
    @Published private(set) var isRequestingKey: Bool = false

    // MARK: - Private Properties

    private var bleService: BluetoothService = .init()
    private let keysService: AccessKeysService = .init()
    private var bag: Set<AnyCancellable> = []

    init() {
        self.powerCorrection = AppPreferences.powerCorrection
        self.turnOnDisplay = AppPreferences.turnByScreenMode
        self.handsFreeMode = AppPreferences.handsFreeMode
        self.bleService.powerCorrection = AppPreferences.powerCorrection

        // Persist the slider, otherwise the background worker keeps using the
        // previous value — it reads `AppPreferences`, not this view model.
        self.$powerCorrection
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 0.3, scheduler: RunLoop.main)
            .sink { [weak self] value in
                AppPreferences.powerCorrection = value
                self?.bleService.powerCorrection = value
            }
            .store(in: &self.bag)

        self.$turnOnDisplay
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                AppPreferences.turnByScreenMode = value
                BackgroundOpenDoorService.onRefresh()
            }
            .store(in: &self.bag)

        self.$handsFreeMode
            .dropFirst()
            .removeDuplicates()
            .sink { value in
                AppPreferences.handsFreeMode = value
                BackgroundOpenDoorService.onRefresh()
            }
            .store(in: &self.bag)

        self.$selectedKeyIndex
            .dropFirst()
            .removeDuplicates()
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.storeSelectedKey()
            }
            .store(in: &self.bag)
    }

    // MARK: - Public Methods

    func getAccessKeys() {
        Task { await self.actualizeAccessKeys() }
    }

    func openDoor() {
        guard !self.isOpeningDoor else { return }
        guard let key = self.selectedKey else {
            self.status = .info("Add a key first — the list above is empty.")
            return
        }

        self.isOpeningDoor = true
        self.status = .info("Looking for a reader…")
        self.bleService.powerCorrection = self.powerCorrection

        self.bleService.requestAccess(keyID: key.id) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                self.isOpeningDoor = false
                self.status = result.status
            }
        }
    }

    func getKeyRequest() {
        guard !self.isRequestingKey else { return }
        self.isRequestingKey = true
        self.status = .info("Waiting for a desktop reader…")

        self.bleService.requestKeyFromDesktopReader { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                if result == .success {
                    await self.actualizeAccessKeys()
                }
                self.isRequestingKey = false
                self.status = result.status
            }
        }
    }

    func selectKey(at index: Int) {
        guard self.keys.indices.contains(index) else { return }
        self.selectedKeyIndex = index
    }

    // MARK: - Private Methods

    private func actualizeAccessKeys() async {
        let list = await self.keysService.getKeys()
        self.keys = list
        self.selectedKeyIndex = list.firstIndex(where: { $0.isKeySelected }) ?? 0
    }

    private var selectedKey: AccessKey? {
        guard self.keys.indices.contains(self.selectedKeyIndex) else { return nil }
        return self.keys[self.selectedKeyIndex]
    }

    /// Makes the tapped key the one the library uses for background unlocks.
    private func storeSelectedKey() {
        // Already the default (e.g. right after a reload) — nothing to write.
        guard let key = self.selectedKey, !key.isKeySelected else { return }
        let keysService = self.keysService
        Task.detached(priority: .background) {
            await keysService.setDefaultAccessKey(key)
        }
    }
}
