//
//  AppDelegate.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/8/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import UserNotifications
import PushKit
import IQKeyboardManagerSwift
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FIRApp.configure()
        CallManager.shared.configure()

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = RootViewController.shared
        window!.makeKeyAndVisible()
        window!.backgroundColor = .thPrimaryPurple
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        
        setUpRemoteNotificationsForApplication(application)
                
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = .thPrimaryPurple
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().tintColor = .white
        
        let registry = PKPushRegistry(queue: nil)
        registry.delegate = self
        registry.desiredPushTypes = [PKPushType.voIP]
        
        if let userInfo = launchOptions?[.remoteNotification] as? [AnyHashable : Any] {
            if let roomName = (userInfo["info"] as? NSDictionary)?["roomname"] as? String,
                let uuidString = (userInfo["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                CallManager.shared.reportIncomingCall(uuid: uuid, roomName: roomName)
            }
        }
        
        return true
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if type == PKPushType.voIP {
            let tokenData = pushCredentials.token
            let voipPushToken = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            TokenUtils.deviceToken = voipPushToken
            // Token is sent to server on login
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print(payload.dictionaryPayload)
        if payload.type == .voIP {
            if let roomName = (payload.dictionaryPayload["info"] as? NSDictionary)?["roomname"] as? String,
                let uuidString = (payload.dictionaryPayload["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                CallManager.shared.reportIncomingCall(uuid: uuid, roomName: roomName)
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Swift.Void) {
        // let userInfo = response.notification.request.content.userInfo
    }
    
    // MARK: - Notifications
    
    func setUpRemoteNotificationsForApplication(_ application: UIApplication) {
        if !application.isRegisteredForRemoteNotifications {
            let center = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.badge, .sound, .alert], completionHandler: { (granted, error) in
                if granted {
                    application.registerForRemoteNotifications()
                } else {
                    // TODO: Present screen asking to turn on notifications
                }
            })
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // TODO: Present screen asking to turn on notifications
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("entering foreground")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("became active")
    }

}

