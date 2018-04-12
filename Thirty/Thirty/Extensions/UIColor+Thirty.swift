//
//  UIColor+Thirty.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

extension UIColor {
    
    static var thPrimaryPurple: UIColor {
        return UIColor(red: 101.0 / 255.0, green: 0.0 / 255.0, blue: 225.0 / 255.0, alpha: 1)
    }
    
    static var thSecondaryPurple: UIColor {
        return UIColor(red: 137.0 / 255.0, green: 0.0 / 255.0, blue: 208.0 / 255.0, alpha: 1)
    }
    
    static var thBlack: UIColor {
        return UIColor(red: 40.0 / 255.0, green: 40.0 / 255.0, blue: 40.0 / 255.0, alpha: 1)
    }
    
    static var thGray: UIColor {
        return UIColor(red: 178.0 / 255.0, green: 178.0 / 255.0, blue: 178.0 / 255.0, alpha: 1)
    }
    
    func toHex() -> UInt {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        let stringHex = String(format:"0x%06x", rgb)
        return UInt(String(stringHex.suffix(6)), radix: 16)!
    }
}
