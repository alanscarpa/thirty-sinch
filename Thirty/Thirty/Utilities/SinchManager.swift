//
//  SinchClientManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/9/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

protocol SinchManagerClientDelegate: class {
    func sinchClientDidStart()
    func sinchClientDidFailWithError(_ error: Error)
}

protocol SinchManagerCallClientDelegate: class {
    func sinchClientDidReceiveIncomingCall(_ call: SINCall)
}

class SinchManager: NSObject, SINManagedPushDelegate, SINClientDelegate, SINCallClientDelegate {
    static let shared = SinchManager()
    
    weak var clientDelegate: SinchManagerClientDelegate?
    weak var callClientDelegate: SinchManagerCallClientDelegate?
    
    fileprivate var client: SINClient?
    
    var clientIsStarted: Bool {
        return client?.isStarted() ?? false
    }
    
    var clientAudioController: SINAudioController? {
        return client?.audioController()
    }
    
    var clientVideoController: SINVideoController? {
        return client?.videoController()
    }
    
    // TODO: change to production when ready
    // try _isDebugAssertConfiguration() to assert is debug
    let push = Sinch.managedPush(with: .production)
    
    // TODO: Verify password on Firebase before initializing
    func initializeWithUserId(_ userId: String) {
        // TODO: Changehost to env host
        // TODO: Change authorization so app secret and key not used
        client = Sinch.client(withApplicationKey: SinchAppKey, applicationSecret: SinchSecret, environmentHost: SinchEnvHost, userId: userId)
        client?.delegate = self
        client?.call().delegate = self
        client?.setSupportCalling(true)
        client?.enableManagedPushNotifications()
        client?.start()
        client?.startListeningOnActiveConnection()
        
        push?.delegate = self
        push?.setDesiredPushTypeAutomatically()
        push?.setDisplayName("\(userId) wants to 30. Tap to answer!")
    }
    
    // MARK: - SINManagedPushDelegate
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        handleRemoteNotification(userInfo: payload)
    }
    
    // MARK: - SINClient
    
    func callUserWithId(_ id: String) -> SINCall? {
        return client?.call().callUserVideo(withId: id)
    }
    
    // MARK: - SINClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        clientDelegate?.sinchClientDidStart()
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        clientDelegate?.sinchClientDidFailWithError(error)
    }
    
    // MARK: - SINCallClientDelegate
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        callClientDelegate?.sinchClientDidReceiveIncomingCall(call)
    }
    
    func client(_ client: SINCallClient!, localNotificationForIncomingCall call: SINCall!) -> SINLocalNotification! {
        let notification = SINLocalNotification()
        notification.alertAction = "Answer"
        // TODO: remoteUserId should be display name.
        notification.alertBody = "Incoming call from \(call.remoteUserId ?? "")"
        return notification
    }
    
    // MARK: - Helpers
    
    func handleRemoteNotification(userInfo: Dictionary<AnyHashable, Any>) {
        if let userId = UserManager.shared.userId, client == nil {
            initializeWithUserId(userId)
        }
        _ = client?.relayRemotePushNotification(userInfo)
    }
    
    // TODO: add LOGOUT functionality and unregisterPushNotificationDeviceToken
    // https://www.sinch.com/docs/video/ios/
    
}
