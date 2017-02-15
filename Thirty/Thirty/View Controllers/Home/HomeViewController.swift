//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, SINCallClientDelegate, UITextFieldDelegate {

    @IBOutlet weak var calleeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SinchClientManager.shared.client?.call().delegate = self
        calleeTextField.delegate = self
    }
    
    // MARK: - SINCallClientDelegate
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        RootViewController.shared.pushCallVCWithCall(call)
    }
    
    // MARK: - Actions
    
    @IBAction func callButtonTapped() {
        if let calleeId = calleeTextField.text,
            !calleeId.isEmpty,
            let call = SinchClientManager.shared.client?.call().callUserVideo(withId: calleeId),
            SinchClientManager.shared.client?.isStarted() == true {
            if SinchClientManager.shared.client?.isStarted() == true {
                RootViewController.shared.pushCallVCWithCall(call)
            }
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
    
}
