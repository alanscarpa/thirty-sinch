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
    
    var userId: String? {
        get {
            return UserDefaults.standard.string(forKey: UserIdKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserIdKey)
            UserDefaults.standard.synchronize()
        }
    }
}
