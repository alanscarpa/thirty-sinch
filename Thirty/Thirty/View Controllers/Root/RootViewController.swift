//
//  RootViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/10/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class RootViewController: UIPageViewController, UIPageViewControllerDataSource, UINavigationControllerDelegate {
    
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
    
    var allViewControllers: [UIViewController] {
        return [rootNavigationController, SettingsTableViewController()]
    }
    
    var numberOfViewControllers: Int {
        return allViewControllers.count
    }
    private var currentVCIndex = 0
    
    required override init(transitionStyle style: UIPageViewControllerTransitionStyle, navigationOrientation: UIPageViewControllerNavigationOrientation, options: [String : Any]? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .thPrimaryPurple
        setUpPageViewController()
        setUpRootNavigationController()
        setUpAppearances()
    }
    
    // MARK: - Setup
    
    private func setUpPageViewController() {
        swipeGestureIsEnabled = false
        dataSource = self
        setViewControllers([allViewControllers.first!], direction: .forward, animated: true, completion: nil)
    }
    
    private func setUpRootNavigationController() {
        rootNavigationController.setNavigationBarHidden(true, animated: false)
        rootNavigationController.delegate = self
        rootNavigationController.view.backgroundColor = .thPrimaryPurple
        let titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: UIFont(name: "Avenir-Black", size: 18)!] as [NSAttributedStringKey : Any]
        rootNavigationController.navigationBar.titleTextAttributes = titleTextAttributes
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
        UserDefaultsManager.shared.callsMade += 1
        let callVC = CallViewController(call: call)
        present(callVC, animated: true, completion: nil)
    }
    
    func pushFeatureVCWithFeaturedUser(_ featuredUser: FeaturedUser) {
        let featureVC = FeatureViewController(featuredUser: featuredUser)
        rootNavigationController.pushViewController(featureVC, animated: true)
    }
    
    func presentLockScreenTipVC() {
        let lockScreenTipVC = LockScreenTipViewController()
        rootNavigationController.present(lockScreenTipVC, animated: true, completion: nil)
    }
    
    func logOut() {
        goToWelcomeVC()
        setViewControllers([allViewControllers.first!], direction: .reverse, animated: true, completion: nil)
    }
    
    // MARK: - UIPageViewControllerDataSource
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = indexOfViewController(viewController) else { return nil }
        let previousIndex = viewControllerIndex - 1
        guard previousIndex >= 0 && numberOfViewControllers > previousIndex else { return nil }
        currentVCIndex = previousIndex
        return allViewControllers[previousIndex]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = indexOfViewController(viewController) else { return nil }
        guard viewControllerIndex == 0, rootNavigationController.topViewController?.isKind(of: HomeTableViewController.self) == true else { return nil }
        let nextIndex = viewControllerIndex + 1
        guard numberOfViewControllers != nextIndex && numberOfViewControllers > nextIndex else { return nil }
        currentVCIndex = nextIndex
        return allViewControllers[nextIndex]
    }
    
    // MARK: - Helpers
    
    var swipeGestureIsEnabled: Bool = false {
        didSet {
            for view in view.subviews {
                if let subView = view as? UIScrollView {
                    subView.isScrollEnabled = swipeGestureIsEnabled
                }
            }
        }
    }

    private func indexOfViewController(_ viewController: UIViewController) -> Int? {
        guard let viewControllerIndex = allViewControllers.index(of: viewController) else { return nil }
        return viewControllerIndex
    }
    
}
