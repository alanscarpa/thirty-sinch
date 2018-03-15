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
import Intents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, PKPushRegistryDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        CallManager.shared.configure()
        FIRApp.configure()

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
        
        if launchOptions?[.userActivityDictionary] != nil {
            print("we are launching from recents + killed state")
            // TODO: First login and if successful, make the call
        } else {
            print("we are launching from something else")
            // if launched from incoming voip, wait to login before acting on it
            // if launched by default, login like normal
        }
        
        if let username = UserManager.shared.currentUserUsername,
            let password = UserManager.shared.currentUserPassword {
            THSpinner.showSpinnerOnView(RootViewController.shared.view)
            FirebaseManager.shared.logInUserWithUsername(username, password: password, completion: { result in
                THSpinner.dismiss()
                switch result {
                case .Success(_):
                    self.loginComplete()
                    if let call = self.callToMake {
                        CallManager.shared.call = call
                        RootViewController.shared.pushCallVC(calleeDeviceToken: nil)
                    } else if let call = self.callToReport {
                        self.reportCall(call)
                    }
                case .Failure(let error):
                    print(error.localizedDescription)
                    // TODO: Present failure pop up
                    self.loginFailed()
                }
            })
        } else {
            loginFailed()
        }
        
//        if let userInfo = launchOptions?[.remoteNotification] as]y] {
//            if let roomName = (userInfo["info"] as? NSDictionary)?["roomname"] as? String,
//                let uuidString = (userInfo["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
//                CallManager.shared.reportIncomingCall(uuid: uuid, roomName: roomName)
//            }
//        }
        
        return true
    }
    
    func loginComplete() {
        RootViewController.shared.goToHomeVC()
    }
    
    func loginFailed() {
        RootViewController.shared.goToWelcomeVC()
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if type == PKPushType.voIP {
            let tokenData = pushCredentials.token
            let voipPushToken = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            TokenUtils.deviceToken = voipPushToken
            // Token is sent to server on login
        }
    }
    
    var callToReport: Call?
    var callToMake: Call?
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print(payload.dictionaryPayload)
        if payload.type == .voIP {
            if let roomName = (payload.dictionaryPayload["info"] as? NSDictionary)?["roomname"] as? String,
                let uuidString = (payload.dictionaryPayload["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                if roomName != UserManager.shared.currentUserUsername {
                    callToReport = Call(uuid: uuid, roomName: roomName, callee: "", direction: .incoming)
                    if FirebaseManager.shared.currentUserIsSignedIn {
                        reportCall(callToReport!)
                    }
                }
            }
        }
        // TODO : THIS COMPLETION BLOCK SHOULD BE CALLED BUT IT BREAKS IT...
        //completion()
    }
    
    func reportCall(_ call: Call) {
        CallManager.shared.reportIncomingCall(uuid: call.uuid, roomName: call.roomName)
        FirebaseManager.shared.observeStatusForCallWithRoomName(call.roomName) { callState in
            switch callState {
            case .pending, .declined, .active:
            break // no-op because only this callee can decline and pending is default.
            case .ended:
                CallManager.shared.performEndCallAction(uuid: call.uuid)
            }
        }
    }

    func application(_ application: UIApplication, willContinueUserActivityWithType userActivityType: String) -> Bool {
        // TODO: Maybe show loading screen?
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let interaction = userActivity.interaction else {
            return false
        }
        
        var personHandle: INPersonHandle?
        
        if let startVideoCallIntent = interaction.intent as? INStartVideoCallIntent {
            personHandle = startVideoCallIntent.contacts?[0].personHandle
        }
        
        // ALL VIDEO BUTTON`
        //    handle when coming from recents - killed state
        //   handle coming from recents - bg state
        //   handle coming from lock screen video button killed
        //   handle when app is on screen and receiving call
        //   handle when app is on screen and locked video button
        //   handle when app is in bg and unlocked WITH NO BRAKPOINTS
        //   handle when app is in bg and locked WITH NO BRAKPOINTS
        
        // 30 BUTTON TAPS
        //   handle when app is on screen and locked 30 button
        
        if let personHandle = personHandle {
            let callDirection: CallDirection = CallManager.shared.call == nil ? .outgoing : .incoming
            if callDirection == .outgoing {
                let roomName = callDirection == .outgoing ? UserManager.shared.currentUserUsername! : personHandle.value!
                let callee = callDirection == .outgoing ? personHandle.value! : UserManager.shared.currentUserUsername!
                let call = Call(uuid: UUID(), roomName: roomName, callee: callee, direction: callDirection)
                callToMake = call
                
                //RootViewController.shared.goToHomeVC()
               // RootViewController.shared.pushCallVC(calleeDeviceToken: nil)
            }
//            if RootViewController.shared.homeVCIsVisible {
//                RootViewController.shared.pushCallVC(calleeDeviceToken: nil)
//            }
        }
        return true
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
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                } else {
                    // TODO: Present screen asking to turn on notifications
                }
            })
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // TODO: Present screen asking to turn on notifications
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        //
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("entering foreground")
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("became active")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
         print("resigned active")
        //RootViewController.shared.setHomeVCIsVisible(false)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
         print("entered background")
        //RootViewController.shared.setHomeVCIsVisible(false)
    }

}

