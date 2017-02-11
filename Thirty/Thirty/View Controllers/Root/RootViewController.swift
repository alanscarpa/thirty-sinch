//
//  RootViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class RootViewController: UIViewController, UINavigationControllerDelegate {
    
    static let sharedInstance = RootViewController()
    
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
    
    func goToLoginVC() {
        rootNavigationController.setViewControllers([LoginViewController()], animated: true)
    }
    
// TODO: Just for reference. Will delete.
//    func goToHomeVC() {
//        rootNavigationController.setViewControllers([LoginViewController(), HomeViewController()], animated: true)
//    }
    
//    func pushSnoopersVC() {
//        rootNavigationController.pushViewController(SnoopersViewController(), animated: true)
//    }
}

