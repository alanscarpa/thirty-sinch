//
//  SearchResultTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 8/30/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

protocol SearchResultsTableViewCellDelegate: class {
    func addButtonWasTapped(sender: SearchResultTableViewCell)
}

class SearchResultTableViewCell: UITableViewCell {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    weak var delegate: SearchResultsTableViewCellDelegate?
    
    static let nibName = "SearchResultTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .thPrimaryPurple
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        usernameLabel.adjustsFontSizeToFitWidth = false
        usernameLabel.numberOfLines = 1
        usernameLabel.textAlignment = .left
        usernameLabel.textColor = .white
    }

    func displayNoFriendsLabel() {
        usernameLabel.textColor = .thGray
        usernameLabel.clipsToBounds = true
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.minimumScaleFactor = 0.4
        usernameLabel.numberOfLines = 2
        usernameLabel.textAlignment = .center
        usernameLabel.text = "You haven't added any friends yet.  Search for friends and add to get started!"
        addButton.isHidden = true
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        delegate?.addButtonWasTapped(sender: self)
    }
    
    
}
