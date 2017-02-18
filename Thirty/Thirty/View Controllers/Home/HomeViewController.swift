//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var calleeTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        calleeTextField.delegate = self
    }

    // MARK: - Actions
    
    @IBAction func callButtonTapped() {
        guard SinchClientManager.shared.client?.isStarted() == true else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Problem with call client. Please try again.")
            present(alert, animated: true, completion: nil)
            return
        }
        if let calleeId = calleeTextField.text, !calleeId.isEmpty,
            let call = SinchClientManager.shared.client?.call().callUserVideo(withId: calleeId) {
                RootViewController.shared.pushCallVCWithCall(call)
        } else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter the username of who you want to call.")
            present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        callButtonTapped()
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
    
    // MARK: - Helpers
    
    func handleClientDidFail() {
        let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Unable to log in.  Please try again.")
        present(alert, animated: true, completion: nil)
        RootViewController.shared.popViewController()
    }
    
}
