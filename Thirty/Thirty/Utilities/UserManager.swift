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

    var currentUser = User()
    
    var currentUserUsername: String {
        return FirebaseManager.shared.currentUser!.displayName!
    }
    
    var hasFeaturedUsers: Bool {
        return featuredUsers.count > 0
    }
    
    var numberOfFriends: Int {
        return contacts.count
    }
    
    var hasFriends: Bool {
        return contacts.count > 0
    }
    
    var contacts: [User] {
        return rawContacts
    }
    private var rawContacts = [User]()
    
    var featuredUsers = [FeaturedUser]()
    
    func addUserAsContact(_ contact: User) {
        rawContacts.append(contact)
        rawContacts.sort(by: { $0.username.lowercased() < $1.username.lowercased() })
    }
    
    func logOut() {
        currentUser = User()
        rawContacts = [User]()
        featuredUsers = [FeaturedUser]()
    }
}
