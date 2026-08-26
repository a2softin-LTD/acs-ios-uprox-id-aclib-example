//
//  AppDelegate.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

import UIKit
import UserNotifications
import u_prox_id_lib

/// Wraps a non-`Sendable` value so it can be handed to a detached task.
/// The payloads below are only read once, from a single task, so this is safe.
private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
}

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Push token used by the library to talk to the key server.
    ///
    /// The demo registers with APNs directly. A production app that uses
    /// Firebase Cloud Messaging would feed the FCM registration token here
    /// instead (see `Messaging.messaging().fcmToken`).
    private var remoteNotifications: RemoteNotification = .init(
        token: AppPreferences.pushToken,
        env: .development
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        BackgroundOpenDoorService.onStart()
        self.configurateAppleNotification(application)
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Push notifications

    private func configurateAppleNotification(_ application: UIApplication) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setBadgeCount(0)
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("Notification authorization failed: \(error.localizedDescription)")
            } else if !granted {
                print("Notification authorization denied by the user")
            }
        }

        application.registerForRemoteNotifications()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        AppPreferences.pushToken = token
        self.remoteNotifications = .init(token: token, env: .development)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        print("Remote notification registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        let payload = UncheckedSendableBox(value: userInfo)
        let service = UncheckedSendableBox(value: self.remoteNotifications)
        let finish = UncheckedSendableBox(value: completionHandler)

        Task.detached(priority: .userInitiated) {
            var notifications = service.value
            let state = await notifications.receive(payload.value)
            print("Remote notification handled: \(state)")

            await MainActor.run { finish.value(.newData) }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}
