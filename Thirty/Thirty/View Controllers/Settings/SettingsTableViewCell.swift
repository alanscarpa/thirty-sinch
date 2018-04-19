//
//  SettingsTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/18/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    static let nibName = "SettingsTableViewCell"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var genericButton: UIButton!
    
    var setting: Setting? {
        didSet {
            updateUI()
        }
    }
    
    override func prepareForReuse() {
        genericButton.isHidden = true
        titleLabel.isHidden = false
        detailLabel.isHidden = false
    }
    
    private func updateUI() {
        let currentUser = UserManager.shared.currentUser
        switch setting! {
        case .firstName:
            titleLabel.text = "First Name"
            detailLabel.text = currentUser.firstName
        case .lastName:
            titleLabel.text = "Last Name"
            detailLabel.text = currentUser.lastName
        case .username:
            titleLabel.text = "Username"
            detailLabel.text = currentUser.username
        case .phoneNumber:
            titleLabel.text = "Phone Number"
            detailLabel.text = currentUser.phoneNumber
        case .logout:
            genericButton.setTitle("Log Out", for: .normal)
            showGenericButton()
        }
    }
    
    private func showGenericButton() {
        genericButton.isHidden = false
        titleLabel.isHidden = true
        detailLabel.isHidden = true
    }
    
}
