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
    
    var showStatusBarBackground = true {
        didSet {
            let statusBar: UIView = UIApplication.shared.value(forKey: "statusBar") as! UIView
            statusBar.backgroundColor = showStatusBarBackground  ? .thPrimaryPurple : .clear
        }
    }
    
    var showToolBar = false {
        didSet {
            rootNavigationController.setToolbarHidden(!showToolBar, animated: true)
        }
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
        setUpRootNavigationController()
        setUpAppearances()
    }
    
    // MARK: - Setup
    
    private func setUpRootNavigationController() {
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.delegate = self
        rootNavigationController.view.backgroundColor = .thPrimaryPurple
        let titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "Avenir-Black", size: 18)!] as [NSAttributedStringKey : Any]
        rootNavigationController.navigationBar.titleTextAttributes = titleTextAttributes
        // We can make custom back button and apply it if needed instead.
        UIBarButtonItem.appearance().setTitleTextAttributes(titleTextAttributes, for: .normal)
        thAddChildViewController(rootNavigationController)
    }
    
    private func setUpAppearances() {
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().barTintColor = .thPrimaryPurple
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().tintColor = .white
    }
    
    // MARK: - Navigation
    
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
    
    func pushFeatureVCWithFeaturedUser(_ featuredUser: FeaturedUser) {
        let featureVC = FeatureViewController(featuredUser: featuredUser)
        rootNavigationController.pushViewController(featureVC, animated: true)
    }
    
}
