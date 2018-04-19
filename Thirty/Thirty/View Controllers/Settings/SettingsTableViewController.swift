//
//  SettingsTableViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/18/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

enum Setting {
    case username
    case firstName
    case lastName
    case phoneNumber
    case logout
}

class SettingsTableViewController: UITableViewController, SettingsTableViewCellDelegte {
    
    let settings: [Setting] = [.username,
                               .firstName,
                               .lastName,
                               .phoneNumber,
                               .logout]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // This prevents the gray view from being seen when user exposes the bounce area.
        let backgroundView = UIView()
        backgroundView.backgroundColor = .thPrimaryPurple
        tableView.backgroundView = backgroundView
        tableView.register(UINib(nibName: SettingsTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SettingsTableViewCell.nibName)
        tableView.backgroundColor = .thPrimaryPurple
        tableView.separatorInset = .zero
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SettingsTableViewCell.nibName, for: indexPath) as! SettingsTableViewCell
        cell.setting = settings[indexPath.row]
        cell.delegate = self
        return cell
    }
    
    // MARK: - SettingsTableViewCellDelegate
    
    func didTapLogoutButton() {
        print("logout")
    }
    
}
