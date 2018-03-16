//
//  WelcomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController, UITextFieldDelegate {
    
    var hasBetaMessage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
        if hasBetaMessage {
            let alertVC = UIAlertController.createSimpleAlert(withTitle: "You must create a NEW account", message: "We're sorry about that.  As we are fixing bugs and working out kinks, things like this might happen.  You can sign up with the same username as last time.  Hopefully this is the last time!  Thank you.")
            present(alertVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        RootViewController.shared.goToLoginVC()
    }
    
    @IBAction func signupButtonTapped() {
        RootViewController.shared.goToSignupVC()
    }
    
}
