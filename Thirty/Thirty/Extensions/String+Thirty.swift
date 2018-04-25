//
//  String+Thirty.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/24/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
    }
}
