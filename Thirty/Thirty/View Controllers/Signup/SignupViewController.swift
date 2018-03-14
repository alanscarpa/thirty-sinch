//
//  SignupViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/28/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import JHSpinner

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = true
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            signupButtonTapped()
        }
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
    
    // MARK: - Actions
    
    @IBAction func signupButtonTapped() {
        guard let credentials = validSignupCredentials() else {
            present(UIAlertController.createSimpleAlert(withTitle: "Problem Signing Up", message: "Make sure you've filled out all fields correctly, your password has at least 6 characters, and both passwords match.  Please try again!"), animated: true, completion: nil)
            return
        }
        // TODO: refactor credentials + User
        let user = User(username: credentials.username, email: credentials.email, phoneNumber: credentials.phoneNumber, password: credentials.password, deviceToken: TokenUtils.deviceToken)
        THSpinner.showSpinnerOnView(view)
        FirebaseManager.shared.createNewUser(user: user) { result in
            THSpinner.dismiss()
            switch result {
            case .Success(_):
                UserManager.shared.userId = user.username
                // Just in case there are lingering calls due to voIP pushes
                CallManager.shared.call = nil
                RootViewController.shared.goToHomeVC()
            case .Failure(let error):
                let errorInfo = THErrorHandler.errorInfoFromError(error)
                self.present(UIAlertController.createSimpleAlert(withTitle: errorInfo.title, message: errorInfo.description), animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func validSignupCredentials() -> (email: String, password: String, username: String, phoneNumber: String)? {
        if let email = emailTextField.text,
            let username = usernameTextField.text,
            let phoneNumber = phoneNumberTextField.text,
            let password = passwordTextField.text, password.count >= 6, passwordTextField.text == confirmPasswordTextField.text {
            return (email, password, username, phoneNumber)
        }
        return nil
    }
    
}
