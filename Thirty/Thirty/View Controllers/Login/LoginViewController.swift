//
//  LoginViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/27/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate, SinchManagerClientDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SinchManager.shared.clientDelegate = self
        usernameTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = true
    }

    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        // TODO: Add PW field and check for accuracy
        // TODO: add loading spinner
        // TODO: Check for username in Firebase, grab email, and then log in with associated email
        if let userId = usernameTextField.text, !userId.isEmpty {
            THSpinner.showSpinnerOnView(view)
            UserManager.shared.userId = usernameTextField.text
            SinchManager.shared.initializeWithUserId(userId)
        } else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter your username.")
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loginButtonTapped()
        return false
    }
    
    // MARK: - UIResponder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = event?.allTouches?.first
        if touch?.view?.isKind(of: UITextField.self) == false {
            view.endEditing(true)
        }
    }
    
    // MARK: - SinchManagerClientDelegate
    
    func sinchClientDidStart() {
        THSpinner.dismiss()
        RootViewController.shared.goToHomeVC()
    }
    
    func sinchClientDidFailWithError(_ error: Error) {
        present(UIAlertController.createSimpleAlert(withTitle: "Error Starting Sinch", message: error.localizedDescription), animated: true, completion: nil)
    }

}
