//
//  MainViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 29.05.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import AcidLibrary
import Combine
import Foundation

final class MainViewModel: ObservableObject {

  @Published var sensitivity: Double = 0.0
  @Published var turnOnDisplay: Bool = false
  @Published var handsFreeMode: Bool = false

  @Published var showError: Bool = false
  @Published var inProcessOpen: Bool = false
  @Published var inProcessGetKey: Bool = false
  @Published var errorMessage: String = ""

  var taks: BluetoothService
  private var bag: Set<AnyCancellable> = []

  init() {
    self.taks = BluetoothService.init()
    self.sensitivity = self.taks.sensitivity
    self.turnOnDisplay = AppPreferences.turnByScreenMode
    self.handsFreeMode = AppPreferences.handsFreeMode

    self.sensitivityChecker
      .sink { [weak self] value in
        self?.taks.sensitivity = value
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
  }

  deinit {
    self.bag.removeAll()
  }

  public func openDoor() {
    self.inProcessOpen = true
      self.taks.requestAccess { [weak self] state in
          DispatchQueue.main.async {
              self?.inProcessOpen = false
              self?.showError = true
              self?.errorMessage = "\(state.self)"
          }
      }
  }

  public func getKeyRequest() {
    self.inProcessGetKey = true
      self.taks.requestKeyFromDesktopReader { [weak self] state in
          DispatchQueue.main.async {
              self?.inProcessGetKey = false
              self?.showError = true
              self?.errorMessage = "\(state.self)"
          }
      }
  }

  private var sensitivityChecker: AnyPublisher<Double, Never> {
    self.$sensitivity
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
