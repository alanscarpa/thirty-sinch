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
import SVProgressHUD

class SignupViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    let databaseRef = FIRDatabase.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        SVProgressHUD.show()
        FIRAuth.auth()?.createUser(withEmail: credentials.email, password: credentials.password) { (user, error) in
            if let error = error {
                SVProgressHUD.dismiss()
                self.present(UIAlertController.createSimpleAlert(withTitle: "Error", message: error.localizedDescription), animated: true, completion: nil)
            } else {
                FIRAuth.auth()?.signIn(withEmail: credentials.email, password: credentials.password, completion: { (user, error) in
                    if let error = error {
                        SVProgressHUD.dismiss()
                        self.present(UIAlertController.createSimpleAlert(withTitle: "Error", message: error.localizedDescription), animated: true, completion: nil)
                    } else {
                        // TODO: get rid of explicit unwrapping
                        self.databaseRef.child("users")
                            .child(user!.uid).setValue(["phone-number": credentials.phoneNumber, "username": credentials.username, "email": credentials.email], withCompletionBlock: { (error, ref) in
                                SVProgressHUD.dismiss()
                                if let error = error {
                                    print(error.localizedDescription)
                                } else {
                                    print("Success")
                                    RootViewController.shared.goToHomeVC()
                                }
                            })
                    }
                })
            }
        }
    }
    
    // MARK: - Helpers
    
    private func validSignupCredentials() -> (email: String, password: String, username: String, phoneNumber: String)? {
        if let email = emailTextField.text,
            let username = usernameTextField.text,
            let phoneNumber = phoneNumberTextField.text,
            let password = passwordTextField.text, password.characters.count >= 6, passwordTextField.text == confirmPasswordTextField.text {
            return (email, password, username, phoneNumber)
        }
        return nil
    }
    
}
