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

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        delegate?.addButtonWasTapped(sender: self)
    }
    
    
}
