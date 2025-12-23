//
//  ScannerViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import u_prox_id_lib
@preconcurrency import Combine
import Foundation

@MainActor
final class ScannerViewModel: ObservableObject {

  @Published var showMessage: Bool = false
  @Published var message: String = ""

  public func handleScan(result: Result<String, CodeScannerView.ScanError>) {
    switch result {
    case .success(let data):
      self.sendCode(data)
    case .failure(let error):
      print("Scanning failed \(error)")
    }
  }

  private func sendCode(_ code: String) {
    let token = AppPreferences.firebaseToken

    Task { [weak self] in
      guard let self else { return }

      let statusMessage = await Task.detached(priority: .userInitiated) { [token, code] in
        let networker = NetworkService(env: .development)
        networker.setConfig(
          .init(
            token: token,
            baseTimeKeyServerUrl: "",
            basePermanentKeyServerUrl: "",
            applicationName: "UPROX" // If you need to set a new application name
          )
        )

        do {
          let result = try await networker.sendCodeToGetAnAccessKey(code)
          switch result {
          case .keyTypeAlreadyExists:
            return "The key is not issued due this type of already exists in the application."
          case .rejected:
            return "The key is not issued due to reject by a remote server"
          case .success:
            return "The key is successfully issued by a remote server."
          case .unknown(let error):
            return error.localizedDescription
          default:
            return "Unknown error"
          }
        } catch let error as AppError {
          return error.localizedDescription
        } catch {
          return error.localizedDescription
        }
      }.value

      self.showMessage = true
      self.message = statusMessage
    }
  }
}
