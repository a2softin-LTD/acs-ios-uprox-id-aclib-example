//
//  AppPreferences.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import Foundation

/// User defaults backed settings shared by the UI and the background worker.
enum AppPreferences {

    /// Push token handed to the library. Stored under the legacy "Firebase Token"
    /// key so existing installs keep working.
    private static let pushTokenStorage = Storage<String>(
        key: "Firebase Token", defaultValue: "", shared: .base)
    nonisolated(unsafe) static var pushToken: String {
        get { pushTokenStorage.wrappedValue }
        set { pushTokenStorage.wrappedValue = newValue }
    }

    /// Unlock the door when the screen is switched on.
    private static let turnByScreenModeStorage = Storage<Bool>(
        key: "Turn by screen mode", defaultValue: false, shared: .base)
    nonisolated(unsafe) static var turnByScreenMode: Bool {
        get { turnByScreenModeStorage.wrappedValue }
        set { turnByScreenModeStorage.wrappedValue = newValue }
    }

    /// Unlock the door as soon as the phone is next to a registered beacon.
    private static let handsFreeModeStorage = Storage<Bool>(
        key: "Hands Free Mode", defaultValue: false, shared: .base)
    nonisolated(unsafe) static var handsFreeMode: Bool {
        get { handsFreeModeStorage.wrappedValue }
        set { handsFreeModeStorage.wrappedValue = newValue }
    }

    /// BLE transmit power multiplier — lower means the reader must be closer.
    static let powerCorrectionRange: ClosedRange<Double> = 0.2...1.6

    private static let powerCorrectionStorage = Storage<Double>(
        key: "PowerCorrection.key", defaultValue: 0.8, shared: .base)
    nonisolated(unsafe) static var powerCorrection: Double {
        get { powerCorrectionStorage.wrappedValue }
        set { powerCorrectionStorage.wrappedValue = newValue.clamped(to: powerCorrectionRange) }
    }
}

extension Comparable {

    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
