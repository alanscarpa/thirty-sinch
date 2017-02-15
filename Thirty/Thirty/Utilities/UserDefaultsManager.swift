//
//  UserDefaultsManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/15/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    
    let UserIdKey = "UserIdKey"
    
    var userId: String? {
        get {
            return UserDefaults.standard.string(forKey: UserIdKey)
        }
        set {
            UserDefaults.standard.set(userId, forKey: UserIdKey)
            UserDefaults.standard.synchronize()
        }
    }
}
