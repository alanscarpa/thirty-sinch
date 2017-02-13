//
//  SinchClientManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/9/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class SinchClientManager {
    static let shared = SinchClientManager()
    var client: SINClient?
    
    private init(){}
    
    func initializeWithUserId(_ userId: String, delegate: SINClientDelegate) {
        // TODO: Changehost to env host
        // TODO: Change authorization so app secret and key not used
        SinchClientManager.shared.client = Sinch.client(withApplicationKey: SinchAppKey, applicationSecret: SinchSecret, environmentHost: SinchEnvHost, userId: userId)
        SinchClientManager.shared.client?.delegate = delegate
        SinchClientManager.shared.client?.setSupportCalling(true)
        SinchClientManager.shared.client?.enableManagedPushNotifications()
        SinchClientManager.shared.client?.start()
        SinchClientManager.shared.client?.startListeningOnActiveConnection()
    }
}
