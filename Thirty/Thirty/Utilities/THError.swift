//
//  THError.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

struct THError: Error {
    var localizedTitle: String
    var localizedDescription: String
    var code: Int
    
    init(errorType: THErrorType) {
        switch errorType {
        case .blankFBUserReturned:
            localizedTitle = ""
            localizedDescription = ""
            code = 001
        }
    }
}

enum THErrorType {
    case blankFBUserReturned
}
