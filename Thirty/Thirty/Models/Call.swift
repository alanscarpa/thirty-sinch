//
//  Call.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/12/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

enum CallDirection {
    case incoming
    case outgoing
}

enum CallState: String {
    case pending
    case declined
    case ended
    case active
}

class Call {
    var uuid: UUID!
    var caller: String
    var callee: String
    var calleeDeviceToken: String?
    var direction: CallDirection
    var roomName: String {
        return caller
    }
    var state: CallState = .pending
    
    init(uuid: UUID, caller: String, callee: String, calleeDeviceToken: String?, direction: CallDirection) {
        self.uuid = uuid
        self.caller = caller
        self.callee = callee
        self.calleeDeviceToken = calleeDeviceToken
        self.direction = direction
    }
}
