//
//  WelcomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, UITextFieldDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        RootViewController.shared.goToLoginVC()
    }
    
    @IBAction func signupButtonTapped() {
        RootViewController.shared.goToSignupVC()
    }
    
}
