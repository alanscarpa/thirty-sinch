//
//  THError.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

class THErrorHandler {
    class func errorInfoFromError(_ error: Error) -> (title: String, description: String) {
        if let customError = error as? THError {
            return (customError.title, customError.description)
        } else {
            return ("Error", error.localizedDescription)
        }

    }
}

struct THError: Error {
    var title: String
    var description: String
    var code: Int
    
    init(errorType: THErrorType) {
        switch errorType {
        case .blankFBUserReturned:
            title = "Blank User Error"
            description = "Unable to get your user info.  Please try again."
            code = 001
        case .usernameDoesNotExist:
            title = "Username Does Not Exist"
            description = "Incorrect username.  Please try again."
            code = 002
        }
    }
}

enum THErrorType {
    case blankFBUserReturned
    case usernameDoesNotExist
}
