//
//  AppDelegate.swift
//  AcidDemo
//
//  Created by Yevhen Khyzhniak on 03.06.2020.
//  Copyright © 2020 Yevhen Khyzhniak. All rights reserved.
//

//import Firebase
//import FirebaseMessaging
import UIKit
import UserNotifications
import u_prox_id_lib

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    lazy private var remoteNotifications: RemoteNotification = .init(
        token: AppPreferences.firebaseToken,
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
        _ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(
            name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    fileprivate func configurateAppleNotification(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in })
        
        application.registerForRemoteNotifications()
    }
    
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task {
            var remoteNotifications = self.remoteNotifications
            _ = await remoteNotifications.receive(userInfo)
            completionHandler(.newData)
        }
    }
}

extension RemoteNotification: @unchecked @retroactive Sendable {}
