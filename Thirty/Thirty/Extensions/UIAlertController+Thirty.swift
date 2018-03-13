//
//  UIAlertController+Thirty.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//


import UIKit

extension UIAlertController {
    static func createSimpleAlert(withTitle title: String, message: String, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: handler)
        alertController.addAction(action)
        return alertController
    }
}
