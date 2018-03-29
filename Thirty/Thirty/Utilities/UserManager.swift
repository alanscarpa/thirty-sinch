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

    var currentUserUsername: String {
        return FirebaseManager.shared.currentUser!.displayName!
    }
    
    var contacts = [User]()
}
