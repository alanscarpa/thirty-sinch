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
    private var loggedIn: Bool { return FirebaseManager.shared.currentUserIsLoggedIn }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        CallManager.shared.configure()
        FirebaseApp.configure()

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = RootViewController.shared
        window!.makeKeyAndVisible()
        window!.backgroundColor = .thPrimaryPurple
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().enableAutoToolbar = false
        
        setUpLocalNotification()
        
        // TODO: Set up when we have reason for remote notifications
        //setUpRemoteNotificationsForApplication(application)
        
        let registry = PKPushRegistry(queue: nil)
        registry.delegate = self
        registry.desiredPushTypes = [PKPushType.voIP]
        
        if loggedIn {
            RootViewController.shared.goToHomeVC()
        } else {
            RootViewController.shared.goToWelcomeVC()
        }
        
        return true
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if type == PKPushType.voIP {
            let tokenData = pushCredentials.token
            let voipPushToken = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
            TokenUtils.deviceToken = voipPushToken
            if FirebaseManager.shared.currentUserIsLoggedIn {
                FirebaseManager.shared.updateDeviceToken()
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // TODO: MAKE SURE NO PUSHES ARE RECEIVED WHEN APP IS DELETED
        print(payload.dictionaryPayload)
        if payload.type == .voIP {
            if let roomName = (payload.dictionaryPayload["info"] as? NSDictionary)?["roomname"] as? String,
                let callerFullName = (payload.dictionaryPayload["info"] as? NSDictionary)?["callerFullName"] as? String,
                let uuidString = (payload.dictionaryPayload["info"] as? NSDictionary)?["uuid"] as? String, let uuid = UUID(uuidString: uuidString) {
                // TODO: Test if this check is still necessary - push registry was called more than once in pst
                if roomName != UserManager.shared.currentUserUsername {
                    let call = Call(uuid: uuid, caller: roomName, callerFullName: callerFullName, callee: "", calleeDeviceToken: nil, direction: .incoming)
                    reportIncomingCall(call)
                }
            }
        }
        // TODO : THIS COMPLETION BLOCK SHOULD BE CALLED BUT IT BREAKS IT...
        //completion()
    }
    
    private func reportIncomingCall(_ call: Call) {
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
    
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {
        print(userActivity)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard let interaction = userActivity.interaction else {
            return false
        }
        var personHandle: INPersonHandle?
        if let startVideoCallIntent = interaction.intent as? INStartVideoCallIntent {
            personHandle = startVideoCallIntent.contacts?[0].personHandle
        }
        if let personHandle = personHandle?.value {
            let callDirection: CallDirection = CallManager.shared.call == nil ? .outgoing : .incoming
            if callDirection == .outgoing {
                if loggedIn  {
                    FirebaseManager.shared.getCurrentUserDetails { result in
                        switch result {
                        case .success:
                            let call = Call(uuid: UUID(), caller: UserManager.shared.currentUserUsername, callerFullName: UserManager.shared.currentUser.fullName, callee: personHandle, calleeDeviceToken: nil, direction: .outgoing)
                            CallManager.shared.call = call
                            RootViewController.shared.pushCallVCWithCall(call)
                        case .failure(_):
                            RootViewController.shared.goToHomeVC()
                        }
                    }
                } else {
                    RootViewController.shared.goToWelcomeVC()
                }
            } else {
                if CallManager.shared.call?.state != .active  {
                    RootViewController.shared.pushCallVCWithCall(CallManager.shared.call!)
                } else {
                    
                }
            }
        }
        return true
    }
    
    // MARK: - Notifications
    
    func setUpLocalNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        let options: UNAuthorizationOptions = [.alert, .sound]
        center.requestAuthorization(options: options) {
            (granted, error) in
            if !granted {
                print("Permission not granted")
            }
        }
        center.getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                // Notifications not allowed
            }
        }
    }
    
    func sendLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Tap \"Start 30\" button to accept the call!"
        content.sound = UNNotificationSound.default()
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1,
                                                        repeats: false)
        let identifier = "LocalNotification"
        let request = UNNotificationRequest(identifier: identifier,
                                            content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
            if let error = error {
                print(error.localizedDescription)
            }
        })
    }
    
    func removeLocalNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - UNUserNotificationCenterDelegate

    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert,.sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Determine the user action
        switch response.actionIdentifier {
        case UNNotificationDismissActionIdentifier:
            break
        case UNNotificationDefaultActionIdentifier:
            print("Default")
        default:
            print("Unknown action")
        }
        completionHandler()
    }
    
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
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        print("became active")
        removeLocalNotifications()
        if let call = CallManager.shared.call, call.state != .active {
            RootViewController.shared.pushCallVCWithCall(call)
        }
    }
}

