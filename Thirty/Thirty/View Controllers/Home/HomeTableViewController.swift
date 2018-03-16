//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit
import SCLAlertView

class HomeTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchResultsTableViewCellDelegate {

    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    
    var searchResults = [User]()
    var isVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getContacts()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        // TODO: undo when search re-enabled
//        tableView.tableHeaderView = searchController.searchBar
//        tableView.tableHeaderView?.isHidden = true
        tableView.register(UINib(nibName: SearchResultTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SearchResultTableViewCell.nibName)
        tableView.backgroundColor = .thPrimaryPurple
        tableView.separatorInset = .zero
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
        if !UserManager.shared.hasSeenWelcomeAlertBETA {
            SCLAlertView().showInfo("HI, BETA USER!", subTitle: "Tap on a name to make your first 30!  NOTE:  If the user has not updated to the newest version of the app, the call will show error and fail.", colorStyle: UIColor.thPrimaryPurple.toHex())
            UserManager.shared.hasSeenWelcomeAlertBETA = true
        }
    }
    
    // MARK: - Setup
    
    func getContacts() {
        FirebaseManager.shared.getContacts { [weak self] result in
            switch result {
            case .Success(let user):
                print(user)
                self?.tableView.reloadData()
            case .Failure(let error):
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
                case .Success(let user):
                    // TODO: Dont populate if user is currentUsername
                    if let user = user {
                        self?.searchResults = [user]
                    } else {
                        // TODO: Show "no user" cell
                        self?.searchResults = []
                    }
                    self?.tableView.reloadData()
                case .Failure(let error):
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "Search Failed (FB)", message: error.localizedDescription)
                    self?.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    // MARK: - TableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? searchResults.count : UserManager.shared.contacts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
        cell.usernameLabel.text = isSearching ? searchResults[indexPath.row].username :
            UserManager.shared.contacts[indexPath.row].username
        cell.addButton.isHidden = isSearching ? false : true
        cell.delegate = self
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard searchResults.isEmpty else { return }
        let user = UserManager.shared.contacts[indexPath.row]
        if let deviceToken = user.deviceToken, !deviceToken.isEmpty {
            let call = Call(uuid: UUID(), caller: UserManager.shared.currentUserUsername, callee: user.username, calleeDeviceToken: deviceToken, direction: .outgoing)
            CallManager.shared.call = call
            RootViewController.shared.pushCallVCWithCall(call)
        } else {
            let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to make call", message: "Note to BETA users:  Unable to call this user at this time because of invalid device token.")
            present(alertVC, animated: true, completion: nil)
        }
    }
    
    // MARK: SearchResultTableViewCellDelegate
    
    func addButtonWasTapped(sender: SearchResultTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        let tappedUser = searchResults[indexPath.row]
        FirebaseManager.shared.addUserAsFriend(username: tappedUser.username) { [weak self] result in
            switch result {
            case .Success(_):
                UserManager.shared.contacts.append(tappedUser)
                self?.resetTableView()
            case .Failure(let error):
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
    
}
