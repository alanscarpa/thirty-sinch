//
//  ContactTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/20/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

protocol ContactTableViewCellDelegate: class {
    func addButtonWasTapped(sender: ContactTableViewCell)
}

class ContactTableViewCell: UITableViewCell {
    static let nibName = "ContactTableViewCell"

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var noFriendsLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    
    weak var delegate: ContactTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .thPrimaryPurple
        selectionStyle = .none
    }
    
    func setUpForUser(_ user: User) {
        usernameLabel.text = user.username
        fullNameLabel.text = user.fullName
        noFriendsLabel.isHidden = true
        usernameLabel.isHidden = false
        fullNameLabel.isHidden = false
        addButton.isHidden = UserManager.shared.contacts.contains(where: { $0.username == user.username })
    }

    func displayNoFriendsLabel() {
        noFriendsLabel.text = "You haven't added any friends yet.  Search for friends and add to get started!"
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
        delegate?.addButtonWasTapped(sender: self)
    }
}
