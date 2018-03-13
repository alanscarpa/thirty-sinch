//
//  RootViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UINavigationControllerDelegate {
    
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
        view.backgroundColor = .thPrimaryPurple
        
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.delegate = self
        rootNavigationController.willMove(toParentViewController: self)
        addChildViewController(rootNavigationController)
        view.addSubview(rootNavigationController.view)
        rootNavigationController.view.backgroundColor = .thPrimaryPurple
        rootNavigationController.didMove(toParentViewController: self)
        
        rootNavigationController.view.frame = super.view.frame
        
        if let username = UserManager.shared.currentUserUsername,
            let password = UserManager.shared.currentUserPassword,
            let userId = UserManager.shared.userId {
            FirebaseManager.shared.logInUserWithUsername(username, password: password, completion: { [weak self] result in
                switch result {
                case .Success(_):
                    self?.goToHomeVC()
                case .Failure(let error):
                    print(error.localizedDescription)
                    // TODO: Present failure pop up
                    self?.goToWelcomeVC()
                }
            })
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
        rootNavigationController.setViewControllers([WelcomeViewController(), HomeTableViewController()], animated: true)
    }
    
    func pushHomeVC() {
        rootNavigationController.pushViewController(HomeTableViewController(), animated: true)
    }
    
    func pushCallVC(calleeDeviceToken: String?, call: Call?) {
        let callVC = CallViewController()
        if let calleeDeviceToken = calleeDeviceToken {
            callVC.calleeDeviceToken = calleeDeviceToken
        }
        callVC.call = call
        rootNavigationController.pushViewController(callVC, animated: true)
    }
    
}
