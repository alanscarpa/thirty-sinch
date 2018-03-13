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

struct Call {
    var uuid = UUID()
    var roomName = ""
    var direction = CallDirection.incoming
}
