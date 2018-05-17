//
//  FeaturedTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/29/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit
import Kingfisher

class FeaturedTableViewCell: UITableViewCell {

    static let nibName = "FeaturedTableViewCell"
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .thPrimaryPurple
        selectionStyle = .none
        photoImageView.makeCircle()
    }
    
    func setUpForFeaturedUser(_ featuredUser: FeaturedUser) {
        titleLabel.text = featuredUser.displayName.uppercased()
        if let urlString = featuredUser.photoUrlString {
            let url = URL(string: urlString)
            photoImageView.kf.setImage(with: url)
        }
    }

}
