//
//  User.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class User {
    var username: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var password: String = ""
    var userNameLowercased: String {
        return username.lowercased()
    }
    var doNotDisturb = false
    var deviceToken: String?
    
    convenience init(username: String, email: String, phoneNumber: String, password: String, deviceToken: String?) {
        self.init()
        self.username = username
        self.email = email
        self.phoneNumber = phoneNumber
        self.password = password
        self.deviceToken = deviceToken
    }
}

