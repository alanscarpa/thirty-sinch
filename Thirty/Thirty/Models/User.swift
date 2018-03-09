//
//  User.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

struct User {
    var username: String = ""
    var email: String = ""
    var phoneNumber: String = ""
    var password: String = ""
    var userNameLowercased: String {
        return username.lowercased()
    }
    var uuid: UUID {
        return UUID()
    }
}

