//
//  ManualDemoView.swift
//  Acid_Demo
//
//  Created by Codex on 11.04.2024.
//

import SwiftUI
import u_prox_id_lib

struct ManualDemoView: View {
    @ObservedObject var viewModel: ManualDemoViewModel
    @State private var showScanner: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                self.powerCorrectionSection()
                Divider()
                self.addKeySection()
                Divider()
                self.keysSection()
                Divider()
                self.discoverySection()
                Divider()
                self.connectionSection()
                self.statusSection()
            }
            .padding()
        }
        .onAppear {
            self.viewModel.onAppear()
        }
        .sheet(isPresented: self.$showScanner, onDismiss: {
            self.viewModel.onAppear()
        }) {
            QrScannerView()
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private func powerCorrectionSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Power correction: \(String(format: "%.1f", self.viewModel.powerCorrection))")
                .font(.headline)
            Slider(
                value: .init(
                    get: { self.viewModel.powerCorrection },
                    set: { self.viewModel.updatePowerCorrection($0) }
                ),
                in: 0.2...1.6,
                step: 0.1
            )
        }
    }
    
    @ViewBuilder
    private func addKeySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Додати ключ")
                .font(.headline)
            
            HStack {
                self.actionButton(
                    title: "Desktop",
                    isLoading: self.viewModel.isRequestingDesktop,
                    action: { self.viewModel.requestDesktopKey() }
                )
                
                self.actionButton(
                    title: "QR scanner",
                    isLoading: false,
                    action: { self.showScanner = true }
                )
            }
            if let result = self.viewModel.desktopResult {
                self.resultLabel(self.viewModel.message(for: result))
            }
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
                ForEach(self.viewModel.keys, id: \.id) { key in
                    let isSelected = key.id == self.viewModel.selectedKeyID
                    HStack {
                        VStack(alignment: .leading) {
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
                        self.viewModel.selectKey(key.id)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func discoverySection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Пошук девайсів")
                    .font(.headline)
                Spacer()
                if self.viewModel.isSearchingDevices {
                    ProgressView()
                }
            }
            
            self.actionButton(
                title: self.viewModel.isSearchingDevices ? "Сканування..." : "Пошук",
                isLoading: self.viewModel.isSearchingDevices,
                action: { self.viewModel.searchDevices() }
            )
            
            if self.viewModel.devices.isEmpty && !self.viewModel.isSearchingDevices {
                Text("Натисніть \"Пошук\" щоб знайти рідери поблизу.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } else {
                ForEach(self.viewModel.devices, id: \.identifier) { device in
                    let isSelected = device.identifier == self.viewModel.selectedDeviceID
                    HStack {
                        VStack(alignment: .leading) {
                            Text(device.name.isEmpty ? "Без імені" : device.name)
                            Text(device.identifier.uuidString)
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
                        self.viewModel.selectDevice(device.identifier)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func connectionSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Підключення та передача ключа")
                .font(.headline)
            
            self.actionButton(
                title: self.viewModel.isConnecting ? "З’єднання..." : "Підключити і передати",
                isLoading: self.viewModel.isConnecting,
                isDisabled: self.viewModel.selectedKeyID == nil || self.viewModel.selectedDeviceID == nil,
                action: { self.viewModel.connectSelected() }
            )
            
            if let result = self.viewModel.accessResult {
                self.resultLabel(self.viewModel.message(for: result))
            }
        }
    }
    
    @ViewBuilder
    private func statusSection() -> some View {
        if !self.viewModel.statusMessage.isEmpty {
            Text(self.viewModel.statusMessage)
                .font(.footnote)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    // MARK: - Helpers
    
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
    
    @ViewBuilder
    private func resultLabel(_ text: String) -> some View {
        Text(text)
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
