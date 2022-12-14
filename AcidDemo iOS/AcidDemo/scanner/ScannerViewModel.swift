//
//  ScannerViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import AcidLibrary
import Combine
import Foundation

final class ScannerViewModel: ObservableObject {

  @Published var showMessage: Bool = false
  @Published var message: String = ""

  private var networker: NetworkService

  init() {
      self.networker = .init()
  }

  public func handleScan(result: Result<String, CodeScannerView.ScanError>) {
    switch result {
    case .success(let data):
      self.sendCode(data)
    case .failure(let error):
      print("Scanning failed \(error)")
    }
  }

  private func sendCode(_ code: String) {
      self.networker.sendCodeToGetAnAccessKey(code) { [weak self] state in
          switch state {
          case .keyTypeAlreadyExists:
              self?.message = "The key is not issued due this type of already exists in the application."
          case .rejected:
              self?.message = "The key is not issued due to reject by a remote server"
          case .success:
              self?.message = "The key is successfully issued by a remote server."
          case .unknown(let msg):
              self?.message = msg
          default:
               break
          }
      }
  }
}
