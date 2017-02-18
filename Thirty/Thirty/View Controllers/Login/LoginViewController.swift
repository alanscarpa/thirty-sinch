//
//  LoginViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var loginTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginTextField.delegate = self
    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        if let userId = loginTextField.text, !userId.isEmpty {
            UserManager.shared.userId = loginTextField.text
            SinchClientManager.shared.initializeWithUserId(userId)
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
}
