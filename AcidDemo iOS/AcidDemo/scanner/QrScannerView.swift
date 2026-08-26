//
//  QrScannerView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import SwiftUI

struct QrScannerView: View {

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ScannerViewModel = .init()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch self.viewModel.cameraState {
                case .unknown:
                    ProgressView().tint(.white)
                case .authorized:
                    CodeScannerView(codeTypes: [.qr], completion: self.viewModel.handleScan)
                        .ignoresSafeArea(edges: .bottom)
                        .overlay(self.reticle)
                case .denied:
                    self.cameraDeniedView
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let status = self.viewModel.status {
                    StatusBanner(status: status)
                        .padding()
                        .background(.ultraThinMaterial)
                }
            }
            .navigationTitle("Scan QR code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { self.dismiss() }
                }
            }
        }
        .task { await self.viewModel.requestCameraAccess() }
        .onChange(of: self.viewModel.didIssueKey) { didIssue in
            guard didIssue else { return }
            self.dismiss()
        }
    }

    private var reticle: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .strokeBorder(Color.white.opacity(0.85), lineWidth: 3)
            .frame(width: 240, height: 240)
            .shadow(radius: 8)
            .allowsHitTesting(false)
    }

    private var cameraDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.largeTitle)
            Text("Camera access is off")
                .font(.headline)
            Text("Enable the camera for AcidDemo in Settings to scan QR codes.")
                .font(.footnote)
                .multilineTextAlignment(.center)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link("Open Settings", destination: url)
                    .padding(.top, 4)
            }
        }
        .foregroundStyle(.white)
        .padding(32)
    }
}
