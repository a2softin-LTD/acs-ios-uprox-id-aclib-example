//
//  AppWorker.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import Foundation

struct AppPreferences {

  private static let firebaseTokenStorage = Storage<String>(key: "Firebase Token", defaultValue: "", shared: .base)
  nonisolated(unsafe) static var firebaseToken: String {
    get { firebaseTokenStorage.wrappedValue }
    set { firebaseTokenStorage.wrappedValue = newValue }
  }

  private static let turnByScreenModeStorage = Storage<Bool>(key: "Turn by screen mode", defaultValue: false, shared: .base)
  nonisolated(unsafe) static var turnByScreenMode: Bool {
    get { turnByScreenModeStorage.wrappedValue }
    set { turnByScreenModeStorage.wrappedValue = newValue }
  }

  private static let handsFreeModeStorage = Storage<Bool>(key: "Hands Free Mode", defaultValue: false, shared: .base)
  nonisolated(unsafe) static var handsFreeMode: Bool {
    get { handsFreeModeStorage.wrappedValue }
    set { handsFreeModeStorage.wrappedValue = newValue }
  }

  private static let powerCorrectionStorage = Storage<Double>(key: "PowerCorrection.key", defaultValue: 0.8, shared: .base)
  nonisolated(unsafe) static var powerCorrection: Double {
    get { powerCorrectionStorage.wrappedValue }
    set { powerCorrectionStorage.wrappedValue = newValue }
  }
} 
