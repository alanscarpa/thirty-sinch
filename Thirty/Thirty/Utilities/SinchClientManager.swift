//
//  SinchClientManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/9/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class SinchClientManager: NSObject, SINManagedPushDelegate {
    static let shared = SinchClientManager()
    var client: SINClient?
    // TODO: change to production when ready
    let push = Sinch.managedPush(with: SINAPSEnvironment.development)
    
    // TODO: Verify password on Firebase before initializing
    func initializeWithUserId(_ userId: String) {
        // TODO: Changehost to env host
        // TODO: Change authorization so app secret and key not used
        client = Sinch.client(withApplicationKey: SinchAppKey, applicationSecret: SinchSecret, environmentHost: SinchEnvHost, userId: userId)
        client?.delegate = RootViewController.shared
        client?.call().delegate = RootViewController.shared
        client?.setSupportCalling(true)
        client?.enableManagedPushNotifications()
        client?.start()
        client?.startListeningOnActiveConnection()
        
        push?.delegate = self
        push?.setDesiredPushTypeAutomatically()
        push?.setDisplayName("\(userId) is 30'ing! Tap to answer!")
    }
    
    // MARK: - SINManagedPushDelegate
    
    func managedPush(_ managedPush: SINManagedPush!, didReceiveIncomingPushWithPayload payload: [AnyHashable : Any]!, forType pushType: String!) {
        handleRemoteNotification(userInfo: payload)
    }
    
    // MARK: - Helpers
    
    func handleRemoteNotification(userInfo: Dictionary<AnyHashable, Any>) {
        if let userId = UserManager.shared.userId, client == nil {
            initializeWithUserId(userId)
        }
        _ = client?.relayRemotePushNotification(userInfo)
    }
}
