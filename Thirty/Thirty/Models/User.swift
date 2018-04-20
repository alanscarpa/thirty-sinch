//
//  User.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class User {
    var username = ""
    var email = ""
    var phoneNumber = ""
    var password = ""
    var firstName = ""
    var lastName = ""
    var deviceToken: String?
    var doNotDisturb = false
    var fullName: String {
        guard !firstName.isEmpty || !lastName.isEmpty else { return username }
        return "\(firstName) \(lastName)"
    }
    
    convenience init(username: String,
                     email: String,
                     phoneNumber: String,
                     password: String,
                     deviceToken: String?,
                     firstName: String = "",
                     lastName: String = "") {
        self.init()
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.password = password
        self.deviceToken = deviceToken
        self.firstName = firstName
        self.lastName = lastName
    }
}


