//
//  UIViewController+Thirty.swift
//  Thirty
//
//  Created by Tom OMalley on 3/22/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

extension UIViewController {
    func thAddChildViewController(_ childVC: UIViewController) {
        childVC.willMove(toParentViewController: self)
        addChildViewController(childVC)
        view.addSubview(childVC.view)
        childVC.view.frame = view.frame
        childVC.didMove(toParentViewController: self)
    }
}
