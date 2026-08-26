//
//  ManualDemoView.swift
//  Acid_Demo
//
//  Created by Codex on 11.04.2024.
//

import SwiftUI

struct ManualDemoView: View {

    @ObservedObject var viewModel: ManualDemoViewModel
    @State private var isShowingScanner: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                self.addKeySection()
                self.keysSection()
                self.discoverySection()
                self.connectionSection()
                self.settingsSection()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .onAppear { self.viewModel.onAppear() }
        .sheet(isPresented: self.$isShowingScanner, onDismiss: { self.viewModel.onAppear() }) {
            QrScannerView()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func addKeySection() -> some View {
        DemoSection(
            title: "1 · Add a key",
            subtitle: "From a desktop reader over BLE, or from a QR code."
        ) {
            HStack(spacing: 10) {
                DemoButton(
                    title: "Desktop",
                    systemImage: "dot.radiowaves.left.and.right",
                    style: .secondary,
                    isLoading: self.viewModel.isRequestingDesktop
                ) {
                    self.viewModel.requestDesktopKey()
                }

                DemoButton(
                    title: "QR code",
                    systemImage: "qrcode.viewfinder",
                    style: .secondary
                ) {
                    self.isShowingScanner = true
                }
            }
        }
    }

    @ViewBuilder
    private func keysSection() -> some View {
        DemoSection(title: "2 · Pick a key") {
            if self.viewModel.keys.isEmpty {
                EmptyHint(text: "No keys yet — add one in step 1.")
            } else {
                ForEach(self.viewModel.keys, id: \.id) { key in
                    SelectionRow(
                        title: key.demoTitle,
                        subtitle: key.demoSubtitle,
                        isSelected: key.id == self.viewModel.selectedKeyID
                    ) {
                        self.viewModel.selectKey(key.id)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func discoverySection() -> some View {
        DemoSection(
            title: "3 · Find a reader",
            accessory: self.viewModel.isSearchingDevices ? AnyView(ProgressView()) : nil
        ) {
            DemoButton(
                title: self.viewModel.isSearchingDevices ? "Scanning…" : "Scan",
                systemImage: "antenna.radiowaves.left.and.right",
                style: .secondary,
                isLoading: self.viewModel.isSearchingDevices
            ) {
                self.viewModel.searchDevices()
            }

            if self.viewModel.devices.isEmpty {
                if !self.viewModel.isSearchingDevices {
                    EmptyHint(text: "Tap Scan to look for readers nearby.")
                }
            } else {
                ForEach(self.viewModel.devices, id: \.identifier) { device in
                    SelectionRow(
                        title: device.demoTitle,
                        subtitle: device.demoSubtitle,
                        isSelected: device.identifier == self.viewModel.selectedDeviceID
                    ) {
                        self.viewModel.selectDevice(device.identifier)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func connectionSection() -> some View {
        DemoSection(
            title: "4 · Connect and send the key",
            subtitle: "Needs a key from step 2 and a reader from step 3."
        ) {
            DemoButton(
                title: self.viewModel.isConnecting ? "Connecting…" : "Connect and send",
                systemImage: "lock.open",
                isLoading: self.viewModel.isConnecting,
                isEnabled: self.viewModel.canConnect
            ) {
                self.viewModel.connectSelected()
            }

            if let status = self.viewModel.status {
                StatusBanner(status: status)
            }
        }
    }

    @ViewBuilder
    private func settingsSection() -> some View {
        DemoSection(title: "Settings") {
            PowerCorrectionSlider(value: self.$viewModel.powerCorrection)
        }
    }
}
