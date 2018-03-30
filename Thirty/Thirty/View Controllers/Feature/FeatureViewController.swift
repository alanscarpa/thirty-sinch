//
//  FeatureViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/29/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

class FeatureViewController: UIViewController {
    
    var featuredUser: FeaturedUser
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var addUserButton: UIButton!
    
    // MARK: Init
    
    init(featuredUser: FeaturedUser) {
        self.featuredUser = featuredUser
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "30 PRESENTS..."
        photoImageView.layer.cornerRadius = photoImageView.frame.size.width / 2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showStatusBarBackground = true
        RootViewController.shared.showNavigationBar = true
    }

}
