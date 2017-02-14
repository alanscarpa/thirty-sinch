//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, SINCallClientDelegate {

    @IBOutlet weak var calleeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        SinchClientManager.shared.client?.call().delegate = self
    }
    
    // MARK: - SINCallClientDelegate
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        // TODO: create call vc
        performSegue(withIdentifier: "callView", sender: call)
    }
    
    // MARK: - Actions
    
    @IBAction func callButtonTapped() {
        if let calleeId = calleeTextField.text, !calleeId.isEmpty {
            if SinchClientManager.shared.client?.isStarted() == true {
                let call = SinchClientManager.shared.client?.call().callUserVideo(withId: calleeId)
                performSegue(withIdentifier: "callView", sender: call)
                let callViewController = segue.destination as! CallViewController
                callViewController.call = sender as! SINCall?
            }
        } else {
            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter the username of who you want to call.")
            present(alert, animated: true, completion: nil)
        }
    }
    
}
