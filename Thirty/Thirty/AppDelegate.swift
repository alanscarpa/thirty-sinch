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
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FIRApp.configure()

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = RootViewController.shared
        window!.makeKeyAndVisible()
        window!.backgroundColor = .thPrimaryPurple
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        
        application.registerForRemoteNotifications()
                
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = .thPrimaryPurple
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().tintColor = .white
        
        return true
    }
    
    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SinchManager.shared.client?.registerPushNotificationData(deviceToken)
        let voipRegistry = PKPushRegistry(queue: DispatchQueue.main)
        voipRegistry.desiredPushTypes = Set([PKPushType.voIP])
        voipRegistry.delegate = self
    }
    
    // MARK: - PushKit
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, forType type: PKPushType) {
        SinchManager.shared.client?.registerPushNotificationData(pushCredentials.token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Swift.Void) {
        print("did i?")
    }

}

