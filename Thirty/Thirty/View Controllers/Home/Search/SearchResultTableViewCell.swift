//
//  SearchResultTableViewCell.swift
//  Thirty
//
//  Created by Alan Scarpa on 8/30/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

protocol SearchResultsTableViewCellDelegate: class {
    func inviteButtonWasTapped(sender: SearchResultTableViewCell)
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
        addButton.setButtonStyle()
    }
    
    func displayAskForContactPermission() {
        addButtonIsHidden = true
        usernameLabel.textAlignment = .center
        usernameLabel.numberOfLines = 2
        usernameLabel.text = "Click here to find your friends already using 30!"
    }
    
    func setUpForContactName(_ contactName: String) {
        usernameLabel.text = contactName
        usernameLabel.textAlignment = .left
        addButtonIsHidden = false
    }
    
    @IBAction func inviteButtonTapped() {
        delegate?.inviteButtonWasTapped(sender: self)
    }
}
