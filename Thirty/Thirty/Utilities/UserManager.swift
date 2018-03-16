//
//  UserManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/16/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class UserManager {
    static let shared = UserManager()
    private init(){}

    private let UserIdKey = "UserIdKey"
    private let UsernameKey = "UsernameKey"
    private let UserPasswordKey = "UserPasswordKey"
    private let HasSeenWelcomeAlertKey = "HasSeenWelcomeAlertKey"
    private let HasLaunchedApp = "HasLaunchedApp"
    
    var hasLaunchedAppBETA: Bool {
        get {
            return UserDefaults.standard.bool(forKey: HasLaunchedApp)
        }
        set {
            UserDefaults.standard.set(true, forKey: HasLaunchedApp)
            UserDefaults.standard.synchronize()
        }
    }
    
    var hasSeenWelcomeAlertBETA: Bool {
        get {
            return UserDefaults.standard.bool(forKey: HasSeenWelcomeAlertKey)
        }
        set {
            UserDefaults.standard.set(true, forKey: HasSeenWelcomeAlertKey)
            UserDefaults.standard.synchronize()
        }
    }
        
    var currentUserUsername: String {
        return FirebaseManager.shared.currentUser!.displayName!
    }
    
    var contacts = [User]()
}
