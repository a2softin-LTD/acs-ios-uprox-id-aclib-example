//
//  MainView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct MainView: View {
    
    enum DemoTab: String, CaseIterable, Identifiable {
        case standard = "Стандарт"
        case manual = "Manual"
        
        var id: String { self.rawValue }
    }
    
    @State private var selectedTab: DemoTab = .standard
    @StateObject private var standardViewModel: MainViewModel = .init()
    @StateObject private var manualViewModel: ManualDemoViewModel = .init()
    
    var body: some View {
        VStack {
            Picker("Demo", selection: self.$selectedTab) {
                ForEach(DemoTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            switch self.selectedTab {
            case .standard:
                StandardDemoView(viewModel: self.standardViewModel)
            case .manual:
                ManualDemoView(viewModel: self.manualViewModel)
            }
        }
    }
}

private struct StandardDemoView: View {
    enum ShowingType: Int, Identifiable {
        case openScanning = 1
        case logs = 2
        
        var id: Int { self.rawValue }
    }
    
    @ObservedObject var viewModel: MainViewModel
    @State private var onShow: ShowingType? = nil
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                self.settingsSection()
                Divider()
                self.keysSection()
                Divider()
                self.actionsSection()
                Divider()
                self.scannerSection()
            }
            .padding()
        }
        .overlay(
            self.logsButtonView().padding(),
            alignment: .bottomTrailing
        )
        .sheet(item: self.$onShow) { item in
            switch item {
            case .openScanning:
                QrScannerView()
                    .onDisappear {
                        self.viewModel.getAccessKeys()
                    }
            case .logs:
                TracerView()
            }
        }
        .alert(isPresented: self.$viewModel.showMessage) { () -> Alert in
            Alert(
                title: Text("Result"),
                message: Text(self.viewModel.message),
                dismissButton: .cancel())
        }
        .onAppear {
            self.viewModel.getAccessKeys()
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func settingsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Налаштування")
                .font(.headline)
            Toggle(
                "Turn on display - \(self.viewModel.turnOnDisplay ? "YES" : "NO")",
                isOn: self.$viewModel.turnOnDisplay)
            Toggle(
                "Hands Free Mode - \(self.viewModel.handsFreeMode ? "YES" : "NO")",
                isOn: self.$viewModel.handsFreeMode)
            Text("Power correction: \(String(format: "%.1f", self.viewModel.powerCorrection))")
                .font(.subheadline)
            Slider(
                value: self.$viewModel.powerCorrection,
                in: 0.2...1.6,
                step: 0.1
            )
        }
    }
    
    @ViewBuilder
    private func keysSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Список ключів")
                .font(.headline)
            if self.viewModel.keys.isEmpty {
                Text("Ключів немає")
            } else {
                ForEach(Array(self.viewModel.keys.enumerated()), id: \.element) { index, key in
                    let isSelected = self.viewModel.initialKeyIndex == index
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(key.displayedName.isEmpty ? "Без назви" : key.displayedName)
                            Text("Тип: \(key.keyType)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.green : Color.gray.opacity(0.3)))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.viewModel.initialKeyIndex = index
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func actionsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Дії")
                .font(.headline)
            self.actionButton(
                title: "Get access key from reader",
                isLoading: self.viewModel.inProcessGetKey
            ) {
                self.viewModel.getKeyRequest()
            }
            self.actionButton(
                title: "Open Door",
                isLoading: self.viewModel.inProcessOpen
            ) {
                self.viewModel.openDoor()
            }
        }
    }
    
    @ViewBuilder
    private func scannerSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Scanner")
                .font(.headline)
            self.actionButton(title: "Open Qr scanner") {
                self.onShow = .openScanning
            }
        }
    }
    
    // MARK: - Helpers
    
    private func logsButtonView() -> some View {
        Circle()
            .frame(width: 50, height: 50)
            .foregroundColor(.orange)
            .overlay(Text("Logs"))
            .onTapGesture {
                self.onShow = .logs
            }
    }
    
    @ViewBuilder
    private func actionButton(
        title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
                Text(title).foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(isDisabled ? Color.gray : Color.blue))
        }
        .disabled(isDisabled || isLoading)
    }
}
