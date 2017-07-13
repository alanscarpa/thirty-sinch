//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
    }

    // MARK: - Actions
    
//    @IBAction func callButtonTapped() {
//        guard SinchManager.shared.clientIsStarted else {
//            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Problem with call client. Please try again.")
//            present(alert, animated: true, completion: nil)
//            return
//        }
//        if let calleeId = calleeTextField.text, !calleeId.isEmpty,
//            let call = SinchManager.shared.callUserWithId(calleeId) {
//                RootViewController.shared.pushCallVCWithCall(call)
//        } else {
//            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter the username of who you want to call.")
//            present(alert, animated: true, completion: nil)
//        }
//    }
    
    // MARK: - UIResponder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = event?.allTouches?.first
        if touch?.view?.isKind(of: UITextField.self) == false {
            view.endEditing(true)
        }
    }
    
}
