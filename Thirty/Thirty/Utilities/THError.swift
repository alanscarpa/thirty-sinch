//
//  THError.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

enum THError: Error {
    case blankFBUserReturned
    case usernameDoesNotExist
    case usernameAlreadyExists
    case noCurrentUser
    case unableToGetDeviceToken
    case blankFBCallStatusReturned
    case noSavedCredentials
    
    var title: String {
        switch self {
        case .blankFBUserReturned:
            return "Blank User Error"
        case .usernameDoesNotExist:
            return "Username Does Not Exist"
        case .usernameAlreadyExists:
            return "Username Already Exists"
        case .noCurrentUser:
            return "No Current User"
        case .unableToGetDeviceToken:
            return "Unable to get device token."
        case .blankFBCallStatusReturned:
            return "Unable to get FB Call Status."
        case .noSavedCredentials:
            return "Unable to log in."
        }
    }
    
    var description: String {
        switch self {
        case .blankFBUserReturned:
            return "Unable to get your user info.  Please try again."
        case .usernameDoesNotExist:
            return "Incorrect username.  Please try again."
        case .usernameAlreadyExists:
            return "That username is already taken.  Please try another."
        case .noCurrentUser:
            return "You've been logged out.  Please log in."
        case .unableToGetDeviceToken:
            return "Please try again later."
        case .blankFBCallStatusReturned:
            return "Please try again later."
        case .noSavedCredentials:
            return "No previously saved credentials."
        }
    }
    
    var code: Int {
        switch self {
        case .blankFBUserReturned:
            return 001
        case .usernameDoesNotExist:
            return 002
        case .usernameAlreadyExists:
            return 003
        case .noCurrentUser:
            return 004
        case .unableToGetDeviceToken:
            return 005
        case .blankFBCallStatusReturned:
            return 006
        case .noSavedCredentials:
            return 007
        }
    }
}
