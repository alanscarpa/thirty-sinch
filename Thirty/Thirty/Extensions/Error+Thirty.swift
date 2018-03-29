//
//  Error+Thirty.swift
//  Thirty
//
//  Created by Tom OMalley on 3/23/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

extension Error {
    typealias ErrorAlertInfo = (title: String, description: String)
    var alertInfo: ErrorAlertInfo {
        guard let thError = self as? THError else { return ("Error", localizedDescription) }
        return (thError.title, thError.description)
    }
}
