//
//  SignupViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/28/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class SignupViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = true
    }

}
