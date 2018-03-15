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
        
        logIn { result in
            switch result {
            case .Success(_):
                if let call = self.callToMake {
                    RootViewController.shared.pushCallVCWithCall(call)
                } else if let call = self.callToReport {
                    self.reportIncomingCall(call)
                }
            case .Failure(let error):
                print(error.localizedDescription)
            }
        }
        
//        if let userInfo = launchOptions?[.remoteNotification] as]y] {
//            if let roomName = (userInfo["info"] as? NSDictionary)?["roomname"] as? String,
//                let uuidString = (userInfo["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
//                CallManager.shared.reportIncomingCall(uuid: uuid, roomName: roomName)
//            }
//        }
        
        return true
    }
    
    func logIn(completion: @escaping (Result<Void>) -> Void) {
        if let username = UserManager.shared.currentUserUsername,
            let password = UserManager.shared.currentUserPassword {
            THSpinner.showSpinnerOnView(RootViewController.shared.view)
            FirebaseManager.shared.logInUserWithUsername(username, password: password) { result in
                THSpinner.dismiss()
                switch result {
                case .Success(_):
                    RootViewController.shared.goToHomeVC()
                case .Failure(_):
                    RootViewController.shared.goToWelcomeVC()
                }
                completion(result)
            }
        } else {
            RootViewController.shared.goToWelcomeVC()
            completion(.Failure(THError(errorType: .noSavedCredentials)))
        }
    }
    
    var loggedIn: Bool {
        return FirebaseManager.shared.currentUserIsSignedIn
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
        // create call
        // if logged in, show push
        // if not logged in, log in, then show push
        print(payload.dictionaryPayload)
        if payload.type == .voIP {
            if let roomName = (payload.dictionaryPayload["info"] as? NSDictionary)?["roomname"] as? String,
                let uuidString = (payload.dictionaryPayload["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                // TODO: Test if this check is still necessary - push registry was called more than once in pst
                if roomName != UserManager.shared.currentUserUsername {
                    callToReport = Call(uuid: uuid, caller: roomName, callee: "", calleeDeviceToken: nil, direction: .incoming)
                    if loggedIn {
                        reportIncomingCall(callToReport!)
                    } else {
                        logIn { [weak self] result in
                            guard let strongSelf = self else { return }
                            switch result {
                            case .Success():
                                strongSelf.reportIncomingCall(strongSelf.callToReport!)
                            case .Failure(let error):
                                print(error.localizedDescription)
                            }
                        }
                    }
                }
            }
        }
        // TODO : THIS COMPLETION BLOCK SHOULD BE CALLED BUT IT BREAKS IT...
        //completion()
    }
    
    func reportIncomingCall(_ call: Call) {
        CallManager.shared.reportIncomingCall(call) { (error) in
            if error == nil {
                FirebaseManager.shared.observeStatusForCallWithRoomName(call.roomName) { callState in
                    switch callState {
                    case .pending, .declined, .active:
                    break // no-op because only this callee can decline and pending is default.
                    case .ended:
                        CallManager.shared.performEndCallAction(uuid: call.uuid)
                    }
                }
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
        
        // Find out what the intent is when tapping "30" butotn
        print(interaction)
        print(interaction.intent)
        
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
        
        if let callee = personHandle?.value {
            // if there is already an active call, then it is incoming and we are already logged in
                // push call vc
            // if it is outgoing, create the call,
                // if logged in, push callVC
                // - check if logged in, if not, log in, then go to callvc,
            let callDirection: CallDirection = CallManager.shared.call == nil ? .outgoing : .incoming
            if callDirection == .incoming {
                RootViewController.shared.pushCallVCWithCall(CallManager.shared.call!)
            } else {
                if loggedIn {
                    let call = Call(uuid: UUID(), caller: UserManager.shared.currentUserUsername!, callee: callee, calleeDeviceToken: nil, direction: .outgoing)
                    RootViewController.shared.pushCallVCWithCall(call)
                } else {
                    logIn { result in
                        switch result {
                        case .Success(_):
                            let call = Call(uuid: UUID(), caller: UserManager.shared.currentUserUsername!, callee: callee, calleeDeviceToken: nil, direction: .outgoing)
                            RootViewController.shared.pushCallVCWithCall(call)
                        case .Failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                }
            }
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
    
    // if resign active, eligible to check if call exists, then pushCallVC
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("became active")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
         print("resigned active")
        //RootViewController.shared.setHomeVCIsVisible(false)
    }
    
    // ELIGIBLE TO CHECK FOR CALLS
    func applicationDidEnterBackground(_ application: UIApplication) {
         print("entered background")
        //RootViewController.shared.setHomeVCIsVisible(false)
    }

}

