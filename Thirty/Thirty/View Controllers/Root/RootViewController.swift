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
    
    private var homeVC = HomeTableViewController()
    
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
            THSpinner.showSpinnerOnView(rootNavigationController.view)
            FirebaseManager.shared.logInUserWithUsername(username, password: password, completion: { [weak self] result in
                THSpinner.dismiss()
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
        rootNavigationController.setViewControllers([WelcomeViewController(), homeVC], animated: true)
    }
    
    func pushHomeVC() {
        rootNavigationController.pushViewController(homeVC, animated: true)
    }
    
    var homeVCIsVisible: Bool {
        return homeVC.isVisible
    }
    
    func setHomeVCIsVisible(_ isVisible: Bool) {
        homeVC.isVisible = isVisible
    }
    
    func pushCallVC(calleeDeviceToken: String?) {
        let callVC = CallViewController()
        if let calleeDeviceToken = calleeDeviceToken {
            callVC.calleeDeviceToken = calleeDeviceToken
        }
        rootNavigationController.pushViewController(callVC, animated: true) 
    }
    
}
