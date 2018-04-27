//
//  SettingsTableViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 4/18/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit
import SafariServices

enum Setting {
    case username
    case firstName
    case lastName
    case phoneNumber
    case termsOfService
    case privacyPolicy
    case logout
}

class SettingsTableViewController: UITableViewController, SettingsTableViewCellDelegte {
    
    let settings: [Setting] = [.username,
                               .firstName,
                               .lastName,
                               .phoneNumber,
                               .termsOfService,
                               .privacyPolicy,
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
    
    func didTapSettingButton(_ setting: Setting) {
        switch setting {
        case .username, .firstName, .lastName, .phoneNumber:
            break // no-op
        case .termsOfService:
            guard let url = URL(string: "https://that30app.com/terms-of-service") else { return }
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true)
        case .privacyPolicy:
            guard let url = URL(string: "https://that30app.com/privacy-policy") else { return }
            let vc = SFSafariViewController(url: url, entersReaderIfAvailable: true)
            vc.modalPresentationStyle = .overFullScreen
            present(vc, animated: true)
        case .logout:
            FirebaseManager.shared.logOutCurrentUser { result in
                switch result {
                case .success(_):
                    UserManager.shared.logOut()
                    RootViewController.shared.logOut()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}
