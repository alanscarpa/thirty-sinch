//
//  WelcomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import SCLAlertView

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
            SCLAlertView().showNotice("You must sign up for a NEW account", subTitle: "We're sorry about that.  As we are fixing bugs and working out kinks, things like this might happen.  You can sign up with the same info as last time.  Hopefully this is the last time!  Thank you.", colorStyle: UIColor.thPrimaryPurple.toHex())
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
