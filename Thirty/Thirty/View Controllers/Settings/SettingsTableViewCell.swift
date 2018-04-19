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
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
