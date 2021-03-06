//
//  LoginViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/27/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = true
    }

    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        guard usernameTextField.text?.contains("@") == false else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please sign in with your username, not your email.")
            present(alert, animated: true, completion: nil)
            return
        }
        if let userId = usernameTextField.text, let password = passwordTextField.text, !userId.isEmpty, !password.isEmpty {
            THSpinner.showSpinnerOnView(view)
            FirebaseManager.shared.logInUserWithUsername(userId, password: password) { [weak self] result in
                THSpinner.dismiss()
                switch result {
                case .success(_):
                    RootViewController.shared.goToHomeVC()
                case .failure(let error):
                    let errorInfo = error.alertInfo
                    let alert = UIAlertController.createSimpleAlert(withTitle: errorInfo.title, message: errorInfo.description, handler: nil)
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter your username and password.")
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview?.viewWithTag(nextTag) {
            nextResponder.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            loginButtonTapped()
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

}
