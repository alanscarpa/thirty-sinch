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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    private func updateUI() {
        let currentUser = FirebaseManager.shared.currentUser
        switch setting! {
        case .firstName:
            titleLabel.text = "First Name"
            //detailLabel.text = 
        case .lastName:
            break
        case .username:
            break
        case .phoneNumber:
            break
        case .logout:
            break
        }
    }
    
}
