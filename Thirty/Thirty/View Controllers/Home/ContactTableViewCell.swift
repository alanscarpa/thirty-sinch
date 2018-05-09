//
//  ContactTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/20/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit
import SwipeCellKit

protocol ContactTableViewCellDelegate: class {
    func addButtonWasTapped(sender: ContactTableViewCell)
}

class ContactTableViewCell: SwipeTableViewCell {
    static let nibName = "ContactTableViewCell"

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var noFriendsLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    weak var contactDelegate: ContactTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .thPrimaryPurple
        selectionStyle = .none
        addButton.setButtonStyle()
    }
    
    func setUpForUser(_ user: User) {
        usernameLabel.text = user.username.lowercased()
        fullNameLabel.text = user.fullName
        noFriendsLabel.isHidden = true
        usernameLabel.isHidden = false
        fullNameLabel.isHidden = false
        addButton.isHidden = UserManager.shared.contacts.contains(where: { $0.username == user.username })
    }

    func displayNoFriendsLabel() {
        noFriendsLabel.text = "You haven't added any friends yet.  Search for friends above and add to get started!"
        noFriendsLabel.isHidden = false
        usernameLabel.isHidden = true
        fullNameLabel.isHidden = true
        addButton.isHidden = true
    }
    
    func displayNoResultsLabel() {
        noFriendsLabel.text = "Unable to find user on 30 ☹️"
        noFriendsLabel.isHidden = false
        usernameLabel.isHidden = true
        fullNameLabel.isHidden = true
        addButton.isHidden = true
    }
    
    @IBAction func tappedAddButton() {
        contactDelegate?.addButtonWasTapped(sender: self)
    }
}
