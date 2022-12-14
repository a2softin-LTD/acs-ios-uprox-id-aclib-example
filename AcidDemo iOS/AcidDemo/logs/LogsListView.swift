//
//  LogsListView.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 12.04.2021.
//  Copyright © 2021 Yevhen Khyzhniak. All rights reserved.
//

import AcidLibrary
import SwiftUI

@available(iOS 13.0.0, *)
struct LogsListView: View {

  @ObservedObject private var logsManager: LogsManager = .shared

  @Binding private var task: BluetoothService
  @State private var isEnabledLogs: Bool = false {
    willSet {
      self.task.isLogsEnabled = newValue
    }
  }

  init(task: Binding<BluetoothService>) {
    self._task = task
    self._isEnabledLogs = .init(initialValue: task.wrappedValue.isLogsEnabled)
  }

  var body: some View {
    List(self.logsManager.logs, id: \.self) { log in
      self.logRowView(log)
    }

    .overlay(
      HStack {
        RoundedRectangle(cornerRadius: 10)
          .frame(width: 100, height: 50)
          .foregroundColor(.red)
          .overlay(
            Text("Удалить логи")
              .font(.footnote)
              .multilineTextAlignment(.center)
          )
          .padding()
          .onTapGesture {
            self.logsManager.removeLogs()
          }
        Circle()
          .frame(width: 50, height: 50)
          .foregroundColor(self.task.isLogsEnabled ? .blue : .orange)
          .overlay(
            Text(self.isEnabledLogs ? "Логи вкл" : "Логи выкл")
              .font(.footnote)
              .multilineTextAlignment(.center)
          )
          .padding()
          .onTapGesture {
            self.isEnabledLogs.toggle()
          }
      }, alignment: .bottom
    )
    .onAppear {
      self.logsManager.loadLogs()
    }
  }

  private func formatterDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = DateFormatter.Style.long  //Set time style
    return formatter.string(from: date)
  }

  private func logRowView(_ model: LogModel) -> some View {
    VStack {
      HStack {
        Text(model.message)
          .bold()
          .font(.footnote)
          .multilineTextAlignment(.leading)
          .font(.headline)
        Spacer()
        Text(formatterDate(model.date))
          .bold()
          .font(.footnote)
          .multilineTextAlignment(.trailing)
          .font(.headline)
      }
      //.frame(minHeight: 100)

      if let devices = model.devices,
        !devices.isEmpty
      {
        VStack {
          Divider()
          ForEach(devices, id: \.self) { device in
            HStack {
              Text(device.name)
                .bold()
                .font(.footnote)
                .multilineTextAlignment(.leading)
              Divider()
              Text("\(device.deviceType)")
                .font(.footnote)
                .multilineTextAlignment(.center)
              Divider()
              Text("\(device.distance)")
                .font(.footnote)
                .multilineTextAlignment(.trailing)
              Spacer()
            }
            .frame(height: 60)
          }
        }
      }
    }
    .background(generateColor(type: model.type))
  }

  private func generateColor(type: LogMessageType) -> Color {
    switch type {
    case .base:
      return .gray
    case .warning:
      return .orange
    case .finishScanning:
      return .purple
    case .finishScanningAndFiltered:
      return .accentColor
    case .startScanning:
      return .blue
    case .startConnect:
      return Color(.magenta)
    case .prepareConnect:
      return .green
    case .finishConnect:
      return Color(.link)
    case .error:
      return .red
    @unknown default:
      return .gray
    }
  }
}
