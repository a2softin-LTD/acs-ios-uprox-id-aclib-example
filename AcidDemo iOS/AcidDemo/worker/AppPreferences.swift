//
//  AppWorker.swift
//  Acid_Demo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import Foundation

struct AppPreferences {

  @Storage(key: "Firebase Token", defaultValue: "", shared: .base)
  static var firebaseToken: String

  @Storage(key: "Turn by screen mode", defaultValue: false, shared: .base)
  static var turnByScreenMode: Bool

  @Storage(key: "Hands Free Mode", defaultValue: false, shared: .base)
  static var handsFreeMode: Bool
    
  @Storage(key: "PowerCorrection.key", defaultValue: 0.8, shared: .base)
  static var powerCorrection: Double
}
