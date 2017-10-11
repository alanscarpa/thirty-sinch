//
//  SinchCallManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 10/11/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation

class SinchCallManager {
    static let shared = SinchCallManager()
    private init(){}
    
    var currentCall: SINCall?
}
