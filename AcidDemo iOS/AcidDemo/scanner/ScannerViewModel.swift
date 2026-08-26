//
//  ScannerViewModel.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import AVFoundation
import Foundation
import u_prox_id_lib

@MainActor
final class ScannerViewModel: ObservableObject {

    enum CameraState {
        case unknown
        case authorized
        case denied
    }

    @Published private(set) var cameraState: CameraState = .unknown
    @Published private(set) var status: DemoStatus?
    @Published private(set) var isSending: Bool = false
    /// Set once the server has issued a key — the sheet closes on this.
    @Published private(set) var didIssueKey: Bool = false

    private var handledCode: String?

    // MARK: - Camera

    func requestCameraAccess() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.cameraState = .authorized
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            self.cameraState = granted ? .authorized : .denied
        default:
            self.cameraState = .denied
        }
    }

    // MARK: - Scanning

    func handleScan(result: Result<String, CodeScannerView.ScanError>) {
        switch result {
        case .success(let code):
            self.sendCode(code)
        case .failure(let error):
            self.status = .failure("Scanning failed: \(error)")
        }
    }

    private func sendCode(_ code: String) {
        // The capture session can report the same code more than once.
        guard !self.isSending, self.handledCode != code else { return }
        self.handledCode = code
        self.isSending = true
        self.status = .info("Sending the code to the server…")

        let token = AppPreferences.pushToken

        Task { [weak self] in
            let result = await Self.requestKey(code: code, token: token)

            guard let self else { return }
            self.isSending = false
            self.status = result
            if result.kind == .success {
                self.didIssueKey = true
            } else {
                // Let the user try again with another code.
                self.handledCode = nil
            }
        }
    }

    private static func requestKey(code: String, token: String) async -> DemoStatus {
        await Task.detached(priority: .userInitiated) {
            let networker = NetworkService(env: .development)
            networker.setConfig(
                .init(
                    token: token,
                    baseTimeKeyServerUrl: "",
                    basePermanentKeyServerUrl: "",
                    applicationName: "UPROX"  // set this if you need a custom application name
                )
            )

            do {
                return try await networker.sendCodeToGetAnAccessKey(code).status
            } catch let error as AppError {
                return .failure(error.localizedDescription)
            } catch {
                return .failure(error.localizedDescription)
            }
        }.value
    }
}
