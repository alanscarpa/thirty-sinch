//
//  Platform.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/8/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

struct PlatformUtils {
    static let isSimulator: Bool = {
        var isSim = false
        #if arch(i386) || arch(x86_64)
            isSim = true
        #endif
        return isSim
    }()
}
