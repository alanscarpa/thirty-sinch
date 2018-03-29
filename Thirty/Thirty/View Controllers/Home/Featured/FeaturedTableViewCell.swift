//
//  FeaturedTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/29/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

class FeaturedTableViewCell: UITableViewCell {

    static let nibName = "FeaturedTableViewCell"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .thPrimaryPurple
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = photoImageView.frame.size.width / 2
    }
    
    func setUpForFeaturedUser(_ featuredUser: FeaturedUser) {
        titleLabel.text = featuredUser.username.uppercased()
    }

}
