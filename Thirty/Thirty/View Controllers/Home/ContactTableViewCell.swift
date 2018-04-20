//
//  ContactTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/20/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

class ContactTableViewCell: UITableViewCell {
    static let nibName = "ContactTableViewCell"

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var noFriendsLabel: UILabel!
    
    func setUpForUser(_ user: User) {
        usernameLabel.text = user.username
        fullNameLabel.text = user.fullName
        noFriendsLabel.isHidden = true
        usernameLabel.isHidden = false
        fullNameLabel.isHidden = false
    }

    func displayNoFriendsLabel() {
        noFriendsLabel.text = "You haven't added any friends yet.  Search for friends and add to get started!"
        noFriendsLabel.isHidden = false
        usernameLabel.isHidden = true
        fullNameLabel.isHidden = true
    }
    
}
