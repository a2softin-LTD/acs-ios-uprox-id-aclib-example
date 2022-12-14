//
//  WalletViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import AcidLibrary
import Combine
import Foundation

final class WalletViewModel: ObservableObject {

  @Published var keys: [AccessKey] = []

  private let keysService: AccessKeysService

  public init() {
    self.keysService = .init()
  }

  public func fetchAccessKeys() {
    self.keysService.getKeys { [weak self] keys in
      self?.keys = keys
    }
  }

  public func setSelectedKey(_ key: AccessKey) {
    self.keysService.setDefaultAccessKey(key) { [weak self] updated in
      self?.keys = updated
    }
  }

}
