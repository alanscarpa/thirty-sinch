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
    
    var hasSeenWelcomeAlert: Bool {
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
