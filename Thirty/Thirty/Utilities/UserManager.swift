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

    let UserIdKey = "UserIdKey"
    let UsernameKey = "UsernameKey"
    let UserPasswordKey = "UserPasswordKey"
    
    var userId: String? {
        get {
            return UserDefaults.standard.string(forKey: UserIdKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserIdKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var currentUserUsername: String? {
        get {
            return UserDefaults.standard.string(forKey: UsernameKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UsernameKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var currentUserPassword: String? {
        get {
            return UserDefaults.standard.string(forKey: UserPasswordKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserPasswordKey)
            UserDefaults.standard.synchronize()
        }
    }
    
    var contacts = [User]()
}
