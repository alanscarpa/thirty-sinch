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
    @IBOutlet weak var addButtonWidthConstraint: NSLayoutConstraint!
    
    weak var delegate: SearchResultsTableViewCellDelegate?
    static let nibName = "SearchResultTableViewCell"
    var addButtonIsHidden: Bool = false {
        didSet {
            addButtonWidthConstraint.constant = addButtonIsHidden ? 0 : 75
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .thPrimaryPurple
        selectionStyle = .none
        addButtonIsHidden = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        usernameLabel.adjustsFontSizeToFitWidth = false
        usernameLabel.numberOfLines = 1
        usernameLabel.textAlignment = .left
        usernameLabel.textColor = .white
        addButtonIsHidden = false
    }

    func displayNoFriendsLabel() {
        usernameLabel.textColor = .thGray
        usernameLabel.clipsToBounds = true
        usernameLabel.adjustsFontSizeToFitWidth = true
        usernameLabel.minimumScaleFactor = 0.4
        usernameLabel.numberOfLines = 2
        usernameLabel.textAlignment = .center
        usernameLabel.text = "You haven't added any friends yet.  Search for friends and add to get started!"
        addButtonIsHidden = true
    }
    
    func displayInviteButton() {
        addButtonIsHidden = false
        addButton.setTitle("Invite +", for: .normal)
    }
    
    func displayAskForContactPermission() {
        addButtonIsHidden = true
        usernameLabel.textAlignment = .center
        usernameLabel.numberOfLines = 2
        usernameLabel.text = "Click here to find your friends already using 30!"
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        delegate?.addButtonWasTapped(sender: self)
    }
    
}
