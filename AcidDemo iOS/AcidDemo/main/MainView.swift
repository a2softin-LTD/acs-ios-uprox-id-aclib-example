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
        case standard = "Standard"
        case manual = "Manual"

        var id: String { self.rawValue }
    }

    @State private var selectedTab: DemoTab = .standard
    @State private var isShowingLogs: Bool = false
    @StateObject private var standardViewModel: MainViewModel = .init()
    @StateObject private var manualViewModel: ManualDemoViewModel = .init()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Demo", selection: self.$selectedTab) {
                    ForEach(DemoTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 12)

                switch self.selectedTab {
                case .standard:
                    StandardDemoView(viewModel: self.standardViewModel)
                case .manual:
                    ManualDemoView(viewModel: self.manualViewModel)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("u-prox ID")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.isShowingLogs = true
                    } label: {
                        Label("Logs", systemImage: "text.alignleft")
                    }
                }
            }
            .sheet(isPresented: self.$isShowingLogs) {
                NavigationStack {
                    TracerView()
                }
            }
        }
    }
}

// MARK: - Standard demo

/// Everything is handled by the library: it finds the nearest reader and picks
/// the key that matches it.
private struct StandardDemoView: View {

    @ObservedObject var viewModel: MainViewModel
    @State private var isShowingScanner: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                self.keysSection()
                self.actionsSection()
                self.settingsSection()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: self.$isShowingScanner) {
            QrScannerView()
                .onDisappear { self.viewModel.getAccessKeys() }
        }
        .onAppear { self.viewModel.getAccessKeys() }
    }

    // MARK: - Sections

    @ViewBuilder
    private func actionsSection() -> some View {
        DemoSection(
            title: "2 · Open a door",
            subtitle: "The library scans for readers and uses the selected key."
        ) {
            DemoButton(
                title: "Open door",
                systemImage: "lock.open",
                isLoading: self.viewModel.isOpeningDoor
            ) {
                self.viewModel.openDoor()
            }

            if let status = self.viewModel.status {
                StatusBanner(status: status)
            }
        }
    }

    @ViewBuilder
    private func keysSection() -> some View {
        DemoSection(
            title: "1 · Access keys",
            subtitle: "Tap a key to make it the default one."
        ) {
            if self.viewModel.keys.isEmpty {
                EmptyHint(text: "No keys yet. Add one from a desktop reader or by scanning a QR code.")
            } else {
                ForEach(Array(self.viewModel.keys.enumerated()), id: \.element.id) { index, key in
                    SelectionRow(
                        title: key.demoTitle,
                        subtitle: key.demoSubtitle,
                        isSelected: self.viewModel.selectedKeyIndex == index
                    ) {
                        self.viewModel.selectKey(at: index)
                    }
                }
            }

            DemoButton(
                title: "Get key from desktop reader",
                systemImage: "dot.radiowaves.left.and.right",
                style: .secondary,
                isLoading: self.viewModel.isRequestingKey
            ) {
                self.viewModel.getKeyRequest()
            }

            DemoButton(
                title: "Scan QR code",
                systemImage: "qrcode.viewfinder",
                style: .secondary
            ) {
                self.isShowingScanner = true
            }
        }
    }

    @ViewBuilder
    private func settingsSection() -> some View {
        DemoSection(
            title: "Background unlock",
            subtitle: "Both modes keep working while the app is in the background."
        ) {
            Toggle("Unlock on screen wake", isOn: self.$viewModel.turnOnDisplay)
            Toggle("Hands free", isOn: self.$viewModel.handsFreeMode)
            Divider()
            PowerCorrectionSlider(value: self.$viewModel.powerCorrection)
        }
    }
}
