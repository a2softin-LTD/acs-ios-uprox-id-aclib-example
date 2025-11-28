//
//  ScannerViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import u_prox_id_lib
import Combine
import Foundation

final class ScannerViewModel: ObservableObject {

  @Published var showMessage: Bool = false
  @Published var message: String = ""

  private var networker: NetworkService

  init() {
      self.networker = .init(env: .development)
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
      Task {
          do {
              self.networker.setConfig(
                  .init(
                      token: AppPreferences.firebaseToken,
                      baseTimeKeyServerUrl: "",
                      basePermanentKeyServerUrl: "",
                      applicationName: "UPROX" // If you need to set a new application name
                  )
              )
              let result = try await self.networker.sendCodeToGetAnAccessKey(code)
              
              await MainActor.run {
                  self.showMessage = true
                  switch result {
                  case .keyTypeAlreadyExists:
                      self.message = "The key is not issued due this type of already exists in the application."
                  case .rejected:
                      self.message = "The key is not issued due to reject by a remote server"
                  case .success:
                      self.message = "The key is successfully issued by a remote server."
                  case .unknown(let error):
                      self.message = error.localizedDescription
                  default:
                      self.message = "Невідома помилка"
                  }
              }
              
          } catch let error as AppError {
              await MainActor.run {
                  self.showMessage = true
                  self.message = error.localizedDescription
              }
          }
      }
  }
}
