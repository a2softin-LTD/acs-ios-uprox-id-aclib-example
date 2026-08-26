//
//  DemoFormatting.swift
//  AcidDemo
//
//  Maps library result types onto something the demo UI can show.
//

import Foundation
import u_prox_id_lib

// MARK: - Status

/// A single piece of user facing feedback: what happened, and how it went.
struct DemoStatus: Equatable, Identifiable {

    enum Kind: Equatable {
        case info
        case success
        case failure
    }

    let id: UUID = .init()
    let kind: Kind
    let text: String

    static func info(_ text: String) -> DemoStatus { .init(kind: .info, text: text) }
    static func success(_ text: String) -> DemoStatus { .init(kind: .success, text: text) }
    static func failure(_ text: String) -> DemoStatus { .init(kind: .failure, text: text) }

    static func == (lhs: DemoStatus, rhs: DemoStatus) -> Bool {
        lhs.kind == rhs.kind && lhs.text == rhs.text
    }
}

// MARK: - Library results

extension RequestAccessResult {

    var status: DemoStatus {
        switch self {
        case .granted: return .success("Access granted")
        case .accepted: return .success("Request accepted by the reader")
        case .denied: return .failure("Access denied")
        case .timeout: return .failure("Timed out — no reader answered")
        case .noAccessKeyForReader: return .failure("No key matches this reader")
        case .bluetoothPowerOff: return .failure("Bluetooth is switched off")
        case .unidentified: return .failure("Unidentified reader response")
        case .error: return .failure("Connection error")
        @unknown default: return .failure("Unknown result")
        }
    }
}

extension RequestKeyFromDesktopReaderResult {

    var status: DemoStatus {
        switch self {
        case .success: return .success("Key issued by the desktop reader")
        case .rejected: return .failure("Rejected by the reader")
        case .keyTypeAlreadyExists: return .failure("A key of this type already exists")
        case .noKeyLeft: return .failure("The reader has no keys left")
        case .noMasterCard: return .failure("Put the master card on the reader")
        case .bluetoothPowerOff: return .failure("Bluetooth is switched off")
        case .unknown: return .failure("Unknown reader response")
        @unknown default: return .failure("Unknown result")
        }
    }
}

extension RequestKeyFromServerResult {

    var status: DemoStatus {
        switch self {
        case .success: return .success("Key issued by the server")
        case .rejected: return .failure("The server rejected this code")
        case .keyTypeAlreadyExists: return .failure("A key of this type already exists")
        case .unknown(let error): return .failure(error.localizedDescription)
        @unknown default: return .failure("Unknown result")
        }
    }
}

// MARK: - Access keys

extension MobileAccessKeyType {

    var displayName: String {
        switch self {
        case .personal: return "Personal"
        case .encrypted: return "Encrypted"
        case .network: return "Network"
        case .company: return "Company"
        case .time: return "Time"
        case .remote: return "Remote"
        case .customer: return "Customer"
        case .unknown: return "Unknown"
        @unknown default: return "Unknown"
        }
    }
}

extension AccessKey {

    /// Name to show in a list, never empty.
    var demoTitle: String {
        self.displayedName.isEmpty ? "Untitled key" : self.displayedName
    }

    /// Key type plus, when present, the validity window.
    var demoSubtitle: String {
        var parts = [self.keyType.displayName]
        if let from = self.displayedEntryTime, let till = self.displayedExitTime {
            parts.append("\(from) – \(till)")
        }
        if self.isKeyExpired {
            parts.append("expired")
        }
        return parts.joined(separator: " · ")
    }
}

extension AccessPoint {

    var demoTitle: String {
        self.name.isEmpty ? "Unnamed reader" : self.name
    }

    var demoSubtitle: String {
        self.identifier.uuidString
    }
}
