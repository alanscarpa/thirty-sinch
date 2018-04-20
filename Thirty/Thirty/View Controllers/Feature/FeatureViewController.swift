//
//  FeatureViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/29/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit
import MessageUI
import Kingfisher

class FeatureViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
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
        if let urlString = featuredUser.photoUrlString {
            let url = URL(string: urlString)
            photoImageView.kf.setImage(with: url)
        }
    }

    // MARK: - Actions
    
    @IBAction func addUserButtonTapped() {
        addUserButton.isEnabled = false
        FirebaseManager.shared.addUserAsFriend(username: featuredUser.username) { [weak self] result in
            switch result {
            case .success():
                self?.showShareAlert()
            case .failure(let error):
                self?.addUserButton.isEnabled = true
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to add user.", message: error.localizedDescription)
                self?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showShareAlert() {
        let alertVC = UIAlertController(title: "You're now friends with \(featuredUser.username)!", message: "Want to increase your chances of getting your personal 30 from \(featuredUser.username)?  Text our download link to a friend!", preferredStyle: .alert)
        let shareButton = UIAlertAction(title: "Text a friend", style: .cancel) { (action) in
            if MFMessageComposeViewController.canSendText() {
                let controller = MFMessageComposeViewController()
                controller.body = "hey - download this app real quick.  it's a fun way to have 30 second video chats. https://that30app.com/download"
                controller.messageComposeDelegate = self
                self.present(controller, animated: true, completion: nil)
            }
        }
        let cancelButton = UIAlertAction(title: "No thanks", style: .default)
        alertVC.addAction(cancelButton)
        alertVC.addAction(shareButton)
        present(alertVC, animated: true, completion: nil)
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
}
