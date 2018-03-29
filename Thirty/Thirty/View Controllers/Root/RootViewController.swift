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
        setUpRootNavigationController()
    }
    
    private func setUpRootNavigationController() {
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.delegate = self
        rootNavigationController.view.backgroundColor = .thPrimaryPurple
        thAddChildViewController(rootNavigationController)
    }
    
    func popViewController() {
        rootNavigationController.popViewController(animated: true)
    }
    
    func goToWelcomeVC() {
        rootNavigationController.setViewControllers([WelcomeViewController()], animated: true)
    }
    
    func goToWelcomeVCWithBetaMessage() {
        let welcomeVC = WelcomeViewController()
        welcomeVC.hasBetaMessage = true
        rootNavigationController.setViewControllers([welcomeVC], animated: true)
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
    
    func pushCallVCWithCall(_ call: Call) {
        let callVC = CallViewController(call: call)
        rootNavigationController.pushViewController(callVC, animated: true)
    }
    
}
