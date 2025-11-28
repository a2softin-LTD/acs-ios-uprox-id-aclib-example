//
//  MainViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import u_prox_id_lib
import Combine
import Foundation

final class MainViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published private(set) var keys: [AccessKey] = []
    @Published var initialKeyIndex: Int = 0
    
    @Published var powerCorrection: Double = 0.0
    @Published var turnOnDisplay: Bool = false
    @Published var handsFreeMode: Bool = false
    
    @Published var showMessage: Bool = false
    @Published var inProcessOpen: Bool = false
    @Published var inProcessGetKey: Bool = false
    @Published private(set) var message: String = ""
    
    // MARK: - Private Properties
    
    private var bleService: BluetoothService
    private var bag: Set<AnyCancellable> = []
    private let keysService: AccessKeysService
    
    init() {
        self.bleService = BluetoothService.init()
        self.powerCorrection = AppPreferences.powerCorrection
        self.turnOnDisplay = AppPreferences.turnByScreenMode
        self.handsFreeMode = AppPreferences.handsFreeMode
        self.keysService = .init()
        
        self.powerCorrectionChecker
            .sink { [weak self] value in
                self?.bleService.powerCorrection = value
            }
            .store(in: &self.bag)
        
        self.turnOnDisplayChecker
            .sink {
                AppPreferences.turnByScreenMode = $0
            }
            .store(in: &self.bag)
        
        self.handsFreeModeChecker
            .sink {
                AppPreferences.handsFreeMode = $0
            }
            .store(in: &self.bag)
        
        self.$initialKeyIndex
            .removeDuplicates()
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .sink { [weak self] newValue in
                guard let self = self else { return }
                self.actualizeSelectedKeyOnStorage()
            }
            .store(in: &self.bag)
    }
    
    deinit {
        self.bag.removeAll()
    }
    
    // MARK: - Public Methods
    
    public func getAccessKeys() {
        Task {
            await self.actualizeAccessKeys()
        }
    }
    
    public func openDoor() {
        guard !self.inProcessOpen else { return }
        self.inProcessOpen = true
        self.bleService.powerCorrection = self.powerCorrection
        if let key = self.getCurrentSelectedKey() {
            DispatchQueue.global(qos: .userInitiated).async {
                self.bleService.requestAccess(keyID: key.id) { [weak self] result in
                    guard let self = self else { return }
                    DispatchQueue.main.async {
                        self.inProcessOpen = false
                        self.showMessage = true
                        self.message = "\(result.self)"
                        
                        print(result)
                    }
                }
            }
        }
    }
    
    public func getKeyRequest() {
        self.inProcessGetKey = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.bleService.requestKeyFromDesktopReader { [weak self] result in
                guard let self = self else { return }
                if result == .success {
                    Task {
                        await self.actualizeAccessKeys()
                    }
                }
                DispatchQueue.main.async {
                    self.inProcessGetKey = false
                    self.showMessage = true
                    self.message = "\(result.self)"
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func actualizeAccessKeys() async {
        let list = await self.keysService.getKeys()
        let initialKeyIndex = await self.calculateInitialSelectedKeyIndex(list)
        await MainActor.run {
            self.initialKeyIndex = initialKeyIndex
            self.keys = list
        }
    }
    
    private func getCurrentSelectedKey() -> AccessKey? {
        guard !keys.isEmpty else { return nil }
        guard self.initialKeyIndex <= keys.count - 1 else { return nil }
        return keys[self.initialKeyIndex]
    }
    
    private func actualizeSelectedKeyOnStorage() {
        guard let currentKey = self.getCurrentSelectedKey() else { return }
        Task(priority: .background) {
            await self.keysService.setDefaultAccessKey(currentKey)
        }
    }
    
    private func calculateInitialSelectedKeyIndex(_ list: [AccessKey]) async -> Int {
        guard !list.isEmpty else { return 0 }
        if let index = list.firstIndex(where: {$0.isKeySelected}) {
            return index
        }
        return 0
    }
    
    // MARK: - Private Computed Properties
    
    private var powerCorrectionChecker: AnyPublisher<Double, Never> {
        self.$powerCorrection
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var turnOnDisplayChecker: AnyPublisher<Bool, Never> {
        self.$turnOnDisplay
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    private var handsFreeModeChecker: AnyPublisher<Bool, Never> {
        self.$handsFreeMode
            .debounce(for: 1.0, scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
