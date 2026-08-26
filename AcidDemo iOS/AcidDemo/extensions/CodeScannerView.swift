//
//  CodeScannerView.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import AVFoundation
import SwiftUI

/// `AVCaptureSession` is not `Sendable`, but starting/stopping it off the main
/// thread is exactly what Apple asks for. The box makes that intent explicit.
private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
}

/// Wraps `AVCaptureSession` in a SwiftUI view and reports the first code it reads.
///
/// The caller is expected to have camera authorization already — see
/// `ScannerViewModel.requestCameraAccess()`.
struct CodeScannerView: UIViewControllerRepresentable {

    enum ScanError: Error {
        case badInput
        case badOutput
        case noCamera
    }

    let codeTypes: [AVMetadataObject.ObjectType]
    let completion: (Result<String, ScanError>) -> Void

    func makeCoordinator() -> ScannerCoordinator {
        ScannerCoordinator(completion: self.completion)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let viewController = ScannerViewController()
        viewController.codeTypes = self.codeTypes
        viewController.coordinator = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
}

// MARK: - Coordinator

extension CodeScannerView {

    @MainActor
    final class ScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {

        private let completion: (Result<String, ScanError>) -> Void
        private var codeFound = false

        init(completion: @escaping (Result<String, ScanError>) -> Void) {
            self.completion = completion
        }

        /// The metadata output below is configured with `DispatchQueue.main`,
        /// so this callback really does run on the main actor.
        nonisolated func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            // `AVMetadataObject` is not `Sendable`; read the string out before
            // hopping onto the main actor.
            guard
                let readableObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let stringValue = readableObject.stringValue
            else { return }

            MainActor.assumeIsolated {
                guard !self.codeFound else { return }

                // Only ever trigger one scan per presentation.
                self.codeFound = true
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                self.completion(.success(stringValue))
            }
        }

        func fail(_ reason: ScanError) {
            guard !self.codeFound else { return }
            self.completion(.failure(reason))
        }
    }
}

// MARK: - View controller

extension CodeScannerView {

    final class ScannerViewController: UIViewController {

        var codeTypes: [AVMetadataObject.ObjectType] = []
        weak var coordinator: ScannerCoordinator?

        private let captureSession = AVCaptureSession()
        private var previewLayer: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            self.view.backgroundColor = .black
            self.configureSession()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            self.startSession()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            self.stopSession()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            self.previewLayer?.frame = self.view.layer.bounds
        }

        override var prefersStatusBarHidden: Bool { true }

        // MARK: - Private

        private func configureSession() {
            guard let device = AVCaptureDevice.default(for: .video) else {
                self.coordinator?.fail(.noCamera)
                return
            }

            guard
                let input = try? AVCaptureDeviceInput(device: device),
                self.captureSession.canAddInput(input)
            else {
                self.coordinator?.fail(.badInput)
                return
            }
            self.captureSession.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            guard self.captureSession.canAddOutput(metadataOutput) else {
                self.coordinator?.fail(.badOutput)
                return
            }
            self.captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self.coordinator, queue: .main)
            metadataOutput.metadataObjectTypes = self.codeTypes

            // Added once — `viewDidAppear` used to stack a new layer on every appearance.
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer.frame = self.view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            self.view.layer.addSublayer(previewLayer)
            self.previewLayer = previewLayer
        }

        private func startSession() {
            guard !self.captureSession.isRunning else { return }
            let session = UncheckedSendableBox(value: self.captureSession)
            // `startRunning()` blocks; never call it on the main thread.
            DispatchQueue.global(qos: .userInitiated).async {
                session.value.startRunning()
            }
        }

        private func stopSession() {
            guard self.captureSession.isRunning else { return }
            let session = UncheckedSendableBox(value: self.captureSession)
            DispatchQueue.global(qos: .userInitiated).async {
                session.value.stopRunning()
            }
        }
    }
}
