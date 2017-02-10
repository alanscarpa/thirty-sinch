//
//  SinchClientManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/9/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class SinchClientManager {
    static let shared = SinchClientManager()
    var client: SINClient?
    
    private init(){}
}
