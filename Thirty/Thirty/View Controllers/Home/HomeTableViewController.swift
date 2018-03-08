//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchResultsTableViewCellDelegate {

    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    
    var searchResults = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getContacts()
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        // TODO: undo this when search is re-enabled and users are adding friends again and searching.
        tableView.tableHeaderView?.isHidden = true
        tableView.register(UINib(nibName: SearchResultTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SearchResultTableViewCell.nibName)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
    }
    
    // MARK: - Setup
    
    func getContacts() {
        FirebaseManager.shared.getContacts { [weak self] result in
            switch result {
            case .Success(let user):
                print(user)
                self?.tableView.reloadData()
            case .Failure(let error):
                // TODO: Present error
                print(error.localizedDescription)
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
                    print(error.localizedDescription)
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
        let username = UserManager.shared.contacts[indexPath.row].username
        // TODO: Need to open room and make call
        RootViewController.shared.pushCallVC()
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
                print(error.localizedDescription)
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
