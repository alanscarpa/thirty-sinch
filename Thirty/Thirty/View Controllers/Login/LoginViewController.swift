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
        view.backgroundColor = .thPrimaryPurple
        SinchManager.shared.clientDelegate = self
        usernameTextField.delegate = self
        passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = true
    }

    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        // TODO: Check for username in Firebase, grab email, and then log in with associated email
        if let userId = usernameTextField.text, let password = passwordTextField.text, !userId.isEmpty, !password.isEmpty {
            THSpinner.showSpinnerOnView(view)
            FirebaseManager.shared.logInUserWithUsername(userId, password: password) { [weak self] result in
                switch result {
                case .Success(_):
                    // Spinner dismissed in delegate call of successful Sinch client initializtion
                    UserManager.shared.userId = self?.usernameTextField.text
                    SinchManager.shared.initializeWithUserId(userId)
                case .Failure(let error):
                    THSpinner.dismiss()
                    let errorInfo = THErrorHandler.errorInfoFromError(error)
                    let alert = UIAlertController.createSimpleAlert(withTitle: errorInfo.title, message: errorInfo.description)
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
    
    // MARK: - SinchManagerClientDelegate
    
    func sinchClientDidStart() {
        THSpinner.dismiss()
        RootViewController.shared.goToHomeVC()
    }
    
    func sinchClientDidFailWithError(_ error: Error) {
        present(UIAlertController.createSimpleAlert(withTitle: "Error Starting Sinch", message: error.localizedDescription), animated: true, completion: nil)
    }

}
