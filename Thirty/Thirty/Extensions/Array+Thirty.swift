//
//  Array+Thirty.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/25/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import Foundation

extension Array {
    mutating func remove(at indexes: [Int]) {
        var lastIndex: Int? = nil
        for index in indexes.sorted(by: >) {
            guard lastIndex != index else {
                continue
            }
            remove(at: index)
            lastIndex = index
        }
    }
}
