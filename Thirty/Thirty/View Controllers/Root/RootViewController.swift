//
//  RootViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UINavigationControllerDelegate, SinchManagerClientDelegate, SinchManagerCallClientDelegate {
    
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
        
        SinchManager.shared.callClientDelegate = self
        
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.delegate = self
        rootNavigationController.willMove(toParentViewController: self)
        addChildViewController(rootNavigationController)
        view.addSubview(rootNavigationController.view)
        rootNavigationController.didMove(toParentViewController: self)
        
        rootNavigationController.view.frame = super.view.frame
        
        if let userId = UserManager.shared.userId {
            SinchManager.shared.clientDelegate = self
            SinchManager.shared.initializeWithUserId(userId)
        } else {
            goToWelcomeVC()
        }
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

    
    // MARK: - SinchManagerCallClientDelegate
    
    func sinchClientDidReceiveIncomingCall(_ call: SINCall) {
        pushCallVCWithCall(call)
    }
    
    // MARK: - SinchManagerClientDelegate
    
    func sinchClientDidStart() {
        goToHomeVC()
    }
    
    func sinchClientDidFailWithError(_ error: Error) {
        present(UIAlertController.createSimpleAlert(withTitle: "Error Starting Sinch", message: error.localizedDescription), animated: true, completion: nil)
    }
    
}
