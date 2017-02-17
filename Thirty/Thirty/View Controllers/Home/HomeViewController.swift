//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, SINClientDelegate, SINCallClientDelegate, UITextFieldDelegate {

    @IBOutlet weak var calleeTextField: UITextField!
    
    @IBOutlet weak var debugLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if SinchClientManager.shared.client == nil {
            if let userId = UserManager.shared.userId {
                SinchClientManager.shared.initializeWithUserId(userId, delegate: self)
                SinchClientManager.shared.client?.call().delegate = self
                calleeTextField.delegate = self
                debugLabel.text = "Client initialized"
            } else {
                handleClientDidFail()
            }
        }
        if SinchClientManager.shared.client?.delegate == nil {
            SinchClientManager.shared.client?.delegate = self
            debugLabel.text = "delegate set"
        }
    }
    
    // MARK: - SINClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        // no-op
        // debugLabel.text = "Client did start"
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        debugLabel.text = "Client did fail"
        handleClientDidFail()
    }
    
    // MARK: - SINCallClientDelegate
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        debugLabel.text = "Received incoming call"
        RootViewController.shared.pushCallVCWithCall(call)
    }
    
    func client(_ client: SINCallClient!, localNotificationForIncomingCall call: SINCall!) -> SINLocalNotification! {
        let notification = SINLocalNotification()
        notification.alertAction = "Answer"
        notification.alertBody = "Incoming call from \(call.remoteUserId)"
        return notification
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
