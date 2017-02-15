//
//  LoginViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, SINClientDelegate, UITextFieldDelegate {

    @IBOutlet weak var loginTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginTextField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        if let userId = loginTextField.text, !userId.isEmpty {
            initializeSinchClientWithUserId(userId)
        } else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter your username.")
            present(alert, animated: true, completion: nil)
        }
    }
    
    func initializeSinchClientWithUserId(_ userId: String) {
        SinchClientManager.shared.initializeWithUserId(userId, delegate: self)
    }
    
    // MARK: - SINClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        RootViewController.shared.pushHomeVC()
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Unable to log in.  Please try again.")
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loginButtonTapped()
        return false
    }
}
