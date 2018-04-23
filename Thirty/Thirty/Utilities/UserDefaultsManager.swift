//
//  UserDefaultsManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/22/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private init(){}
    
    private let hasLaunchedAppKey = "hasLaunchedAppKey"
    
    var hasLaunchedApp: Bool {
        get {
            return UserDefaults.standard.bool(forKey: hasLaunchedAppKey)
        } set {
            UserDefaults.standard.set(newValue, forKey: hasLaunchedAppKey)
        }
    }
    
}
