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
        setUpUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showStatusBarBackground = true
        RootViewController.shared.showNavigationBar = true
    }
    
    // MARK: - Setup
    
    func setUpUI() {
        title = "30 PRESENTS..."
        photoImageView.makeCircle()
        // TODO: Load uiimageview image from featured user.  Right now, it's a hardcoded Smallpools image.
        titleLabel.text = featuredUser.username.uppercased()
        detailsLabel.text = featuredUser.promoDetails
        addUserButton.setTitle("ADD \(featuredUser.username.uppercased())", for: .normal)
        addUserButton.setBackgroundImage(UIImage(color: .darkGray, size: addUserButton.frame.size), for: .disabled)
        addUserButton.isEnabled = UserManager.shared.contacts.filter({ $0.username == featuredUser.username }).isEmpty
    }

    // MARK: - Actions
    
    @IBAction func addUserButtonTapped() {
        addUserButton.isEnabled = false
        FirebaseManager.shared.addUserAsFriend(username: featuredUser.username) { [weak self] result in
            switch result {
            case .success():
                break // no-op
            case .failure(let error):
                self?.addUserButton.isEnabled = true
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to add user.", message: error.localizedDescription)
                self?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
}