//
//  MainView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

enum ShowingType {
  case openWallet, openScanning, unknown, logs
}

private var type: ShowingType = .unknown

struct MainView: View {

  @ObservedObject var viewModel: MainViewModel = .init()
  @State var showing: Bool = false

  var body: some View {
    Form {

      Section {
        Toggle(
          "Turn on display - \(self.viewModel.turnOnDisplay ? "YES" : "NO")",
          isOn: self.$viewModel.turnOnDisplay)

        Toggle(
          "Hands Free Mode - \(self.viewModel.handsFreeMode ? "YES" : "NO")",
          isOn: self.$viewModel.handsFreeMode)

        Text("Max possible distance to reader \(self.viewModel.sensitivity)m.")
        Slider(
          value: self.$viewModel.sensitivity, in: .init(uncheckedBounds: (lower: 0.2, upper: 1.5)))
      }

      Section {
        MainSceneRow(title: "Get access key from reader", process: self.$viewModel.inProcessGetKey)
        {
          self.viewModel.getKeyRequest()
        }
        MainSceneRow(title: "Open Door", process: self.$viewModel.inProcessOpen) {
          self.viewModel.openDoor()
        }
      }

      Section {
        MainSceneRow(title: "Open Wallet", process: .constant(false)) {
          self.showing = true
          type = .openWallet
        }
        MainSceneRow(title: "Open Qr scanner", process: .constant(false)) {
          self.showing = true
          type = .openScanning
        }
      }
    }
    .overlay(
      self.logsButtonView().padding(),
      alignment: .bottomTrailing
    )

    .sheet(isPresented: self.$showing) {
      if type == .openWallet {
        WalletView()
      }
      if type == .openScanning {
        QrScannerView()
      }
      if type == .logs {
        LogsListView(task: self.$viewModel.taks)
      }

    }

    .alert(isPresented: self.$viewModel.showError) { () -> Alert in
      Alert(
        title: Text("Error!!!"),
        message: Text(self.viewModel.errorMessage),
        dismissButton: .cancel())
    }
  }

  private func logsButtonView() -> some View {
    Circle()
      .frame(width: 50, height: 50)
      .foregroundColor(.orange)
      .overlay(Text("Logs"))
      .onTapGesture {
        self.showing = true
        type = .logs
      }
  }
}
