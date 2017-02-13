//
//  LoginViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, SINClientDelegate {

    @IBOutlet weak var loginTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    // MARK: - Actions
    
    @IBAction func loginButtonTapped() {
        if let userId = loginTextField.text {
            initializeSinchClientWithUserId(userId)
        } else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter your username.")
            present(alert, animated: true, completion: nil)
        }
    }
    
    func initializeSinchClientWithUserId(_ userId: String) {
        // TODO: Changehost to env host
        // TODO: Change authorization so app secret and key not used
        SinchClientManager.shared.client = Sinch.client(withApplicationKey: SinchAppKey, applicationSecret: SinchSecret, environmentHost: SinchEnvHost, userId: userId)
        SinchClientManager.shared.client?.delegate = self
        SinchClientManager.shared.client?.setSupportCalling(true)
        SinchClientManager.shared.client?.enableManagedPushNotifications()
        SinchClientManager.shared.client?.start()
        SinchClientManager.shared.client?.startListeningOnActiveConnection()
    }
    
    // MARK: - SINClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        print("Sinch client started.")
        RootViewController.shared.pushHomeVC()
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Unable to log in.  Please try again.")
        present(alert, animated: true, completion: nil)
    }
}
