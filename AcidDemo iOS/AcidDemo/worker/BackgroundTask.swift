//
//  BackgroundTask.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 18.11.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import Foundation
import UIKit

public class BackgroundTask {
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    public func registerBackgroundTask() {
        DispatchQueue.global().async {
            self.backgroundTask = UIApplication.shared.beginBackgroundTask(withName: Bundle.main.bundleIdentifier, expirationHandler: {
                self.endBackgroundTask()
            })
        }
    }

    /// Ends long-running background task. Called when app comes to foreground from background
    public func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskIdentifier.invalid
    }
}
