//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import SCLAlertView
import AVFoundation

class HomeTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchResultsTableViewCellDelegate {

    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    
    var searchResults = [User]()
    var isVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getContacts()
        setUpSearchController()
        setUpTableView()
        FirebaseManager.shared.updateDeviceToken()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
        RootViewController.shared.showStatusBarBackground = true
        requestCameraAndMicrophonePermissions()
    }
    
    // MARK: - Setup
    
    func setUpTableView() {
        // This prevents the gray view from being seen when user exposes the bounce area.
        let backgroundView = UIView()
        backgroundView.backgroundColor = .thPrimaryPurple
        tableView.backgroundView = backgroundView
        tableView.register(UINib(nibName: FeaturedTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: FeaturedTableViewCell.nibName)
        tableView.register(UINib(nibName: SearchResultTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SearchResultTableViewCell.nibName)
        tableView.backgroundColor = .thPrimaryPurple
        tableView.separatorInset = .zero
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func setUpSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .gray
        let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .white
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }
    
    func getContacts() {
        FirebaseManager.shared.getContacts { [weak self] result in
            switch result {
            case .success():
                FirebaseManager.shared.getFeaturedUsers { [weak self] result in
                    self?.tableView.reloadData()
                    switch result {
                    case .success():
                        break // no-op
                    case .failure(let error):
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to get featured users.", message: error.localizedDescription)
                        self?.present(alertVC, animated: true, completion: nil)
                    }
                }
            case .failure(let error):
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to get contacts.", message: error.localizedDescription)
                self?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        if !searchController.isActive { resetTableView() }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchQuery = searchBar.text else { return }
        searchForContactWithString(searchQuery)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearching = true
        // This fires when user taps "x" and clears search field.
        if searchText.isEmpty { resetTableView() }
    }
    
    func searchForContactWithString(_ query: String) {
        isSearching = true
        guard query != UserManager.shared.currentUserUsername else {
            tableView.reloadData()
            return
        }
        if let alreadyFriendedUser = UserManager.shared.contacts.filter({ $0.username == query }).first {
            searchResults = [alreadyFriendedUser]
            // Hacky way of hiding add button when reloading data.  Faster than querying entire contacts array for each cell though.
            isSearching = false
            tableView.reloadData()
        } else {
            FirebaseManager.shared.searchForUserWithUsername(query) { [weak self] result in
                switch result {
                case .success(let user):
                    // TODO: Dont populate if user is currentUsername
                    if let user = user {
                        self?.searchResults = [user]
                    } else {
                        // TODO: Show "no user" cell
                        self?.searchResults = []
                    }
                    self?.tableView.reloadData()
                case .failure(let error):
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "Search Failed (FB)", message: error.localizedDescription)
                    self?.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return UserManager.shared.hasFeaturedUsers ? 2 : 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFeaturedSection(section) {
            return UserManager.shared.featuredUsers.count
        } else {
            return isSearching ? searchResults.count : UserManager.shared.contacts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isFeaturedSection(indexPath.section) {
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedTableViewCell.nibName, for: indexPath) as! FeaturedTableViewCell
            let featuredUser = UserManager.shared.featuredUsers[indexPath.row]
            cell.setUpForFeaturedUser(featuredUser)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
            cell.usernameLabel.text = isSearching ? searchResults[indexPath.row].username :
                UserManager.shared.contacts[indexPath.row].username
            cell.addButton.isHidden = isSearching ? false : true
            cell.delegate = self
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard searchResults.isEmpty else { return }
        if isFeaturedSection(indexPath.section) {
            let featuredUser = UserManager.shared.featuredUsers[indexPath.row]
            RootViewController.shared.pushFeatureVCWithFeaturedUser(featuredUser)
        } else {
            let user = UserManager.shared.contacts[indexPath.row]
            if let deviceToken = user.deviceToken, !deviceToken.isEmpty {
                if AVCaptureDevice.authorizationStatus(for: .video) != .authorized || AVAudioSession.sharedInstance().recordPermission() != .granted  {
                    requestCameraAndMicrophonePermissions()
                } else {
                    let call = Call(uuid: UUID(), caller: UserManager.shared.currentUserUsername, callee: user.username, calleeDeviceToken: deviceToken, direction: .outgoing)
                    CallManager.shared.call = call
                    DispatchQueue.main.async {
                        RootViewController.shared.pushCallVCWithCall(call)
                    }
                }
            } else {
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to make call", message: "Note to BETA users:  Unable to call this user at this time because of invalid device token.")
                DispatchQueue.main.async {
                    self.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if isFeaturedSection(indexPath.section) {
            return 125
        } else {
            return 64
        }
    }
    
    // MARK: SearchResultTableViewCellDelegate
    
    func addButtonWasTapped(sender: SearchResultTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        let tappedUser = searchResults[indexPath.row]
        FirebaseManager.shared.addUserAsFriend(username: tappedUser.username) { [weak self] result in
            switch result {
            case .success(_):
                UserManager.shared.contacts.append(tappedUser)
                self?.resetTableView()
            case .failure(let error):
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to add user.", message: error.localizedDescription)
                self?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UIResponder
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        let touch = event?.allTouches?.first
        if touch?.view?.isKind(of: UITextField.self) == false {
            view.endEditing(true)
        }
    }
    
    // MARK: - Helpers
    
    func resetTableView() {
        searchResults = []
        isSearching = false
        tableView.reloadData()
    }
    
    private func requestCameraAndMicrophonePermissions() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
            if granted {
                AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                    if !granted {
                        DispatchQueue.main.async {
                            SCLAlertView().showError("Please enable microphone permission", subTitle: "You won't be able to 30 unlesss you enable microphone permissions.  Go to Settings > Privacy > Microphone and please enable.", colorStyle: UIColor.thPrimaryPurple.toHex())
                        }
                    }
                })
            } else {
                DispatchQueue.main.async {
                    SCLAlertView().showError("Please enable video permission", subTitle: "You won't be able to  30 unlesss you enable video permissions.  Go to Settings > Privacy > Camera and please enable.", colorStyle: UIColor.thPrimaryPurple.toHex())
                }
            }
        }
    }
    
    private func isFeaturedSection(_ section: Int) -> Bool {
        return UserManager.shared.hasFeaturedUsers && section == 0
    }
    
}
