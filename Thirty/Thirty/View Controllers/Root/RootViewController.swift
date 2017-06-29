//
//  RootViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UINavigationControllerDelegate, SINClientDelegate, SINCallClientDelegate {
    
    static let shared = RootViewController()
    
    private let rootNavigationController = UINavigationController()

    var showNavigationBar = false {
        didSet {
            rootNavigationController.setNavigationBarHidden(!showNavigationBar, animated: true)
        }
    }
    
    var showToolBar = false {
        didSet {
            rootNavigationController.setToolbarHidden(!showToolBar, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .blue
        
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.delegate = self
        rootNavigationController.willMove(toParentViewController: self)
        addChildViewController(rootNavigationController)
        view.addSubview(rootNavigationController.view)
        rootNavigationController.didMove(toParentViewController: self)
        
        rootNavigationController.view.frame = super.view.frame
    }
    
    func popViewController() {
        rootNavigationController.popViewController(animated: true)
    }
    
    func goToWelcomeVC() {
        rootNavigationController.setViewControllers([WelcomeViewController()], animated: true)
    }
    
    func goToLoginVC() {
        rootNavigationController.pushViewController(LoginViewController(), animated: true)
    }
    
    func goToSignupVC() {
        rootNavigationController.pushViewController(SignupViewController(), animated: true)
    }
    
    func goToHomeVC() {
        rootNavigationController.setViewControllers([WelcomeViewController(), HomeViewController()], animated: true)
    }
    
    func pushHomeVC() {
        rootNavigationController.pushViewController(HomeViewController(), animated: true)
    }
    
    func pushCallVCWithCall(_ call: SINCall) {
        let callVC = CallViewController()
        callVC.call = call
        rootNavigationController.pushViewController(callVC, animated: true)
    }
    
    // MARK: - SINClientDelegate
    
    func clientDidStart(_ client: SINClient!) {
        goToHomeVC()
    }
    
    func clientDidFail(_ client: SINClient!, error: Error!) {
        let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Unable to log in.  Please try again.")
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - SINCallClientDelegate
    
    func client(_ client: SINCallClient!, didReceiveIncomingCall call: SINCall!) {
        pushCallVCWithCall(call)
    }
    
    func client(_ client: SINCallClient!, localNotificationForIncomingCall call: SINCall!) -> SINLocalNotification! {
        let notification = SINLocalNotification()
        notification.alertAction = "Answer"
        notification.alertBody = "Incoming call from \(call.remoteUserId)"
        return notification
    }
}
