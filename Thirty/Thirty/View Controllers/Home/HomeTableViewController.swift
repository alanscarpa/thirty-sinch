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
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
        
        tableView.register(UINib(nibName: SearchResultTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SearchResultTableViewCell.nibName)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
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
        // This fires when user taps "x" and clears search field.
        if searchText.isEmpty { resetTableView() }
    }
    
    func searchForContactWithString(_ query: String) {
        FirebaseManager.shared.searchForUserWithUsername(query) { [weak self] result in
            switch result {
            case .Success(let user):
                // TODO: Dont populate if user is currentUsername
                self?.searchResults = [user]
                self?.tableView.reloadData()
            case .Failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - TableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
        cell.usernameLabel.text = searchResults[indexPath.row].username
        cell.delegate = self
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    // MARK: SearchResultTableViewCellDelegate
    
    func addButtonWasTapped(sender: SearchResultTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        let tappedUser = searchResults[indexPath.row]
        FirebaseManager.shared.addUserAsFriend(username: tappedUser.username) { [weak self] result in
            switch result {
            case .Success(_):
                self?.resetTableView()
            case .Failure(let error):
                print(error.localizedDescription)
            }
        }
    }

    // MARK: - Actions
    
//    @IBAction func callButtonTapped() {
//        guard SinchManager.shared.clientIsStarted else {
//            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Problem with call client. Please try again.")
//            present(alert, animated: true, completion: nil)
//            return
//        }
//        if let calleeId = calleeTextField.text, !calleeId.isEmpty,
//            let call = SinchManager.shared.callUserWithId(calleeId) {
//                RootViewController.shared.pushCallVCWithCall(call)
//        } else {
//            let alert = UIAlertController.createSimpleAlert(withTitle: "Error", message: "Please enter the username of who you want to call.")
//            present(alert, animated: true, completion: nil)
//        }
//    }
    
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
        tableView.reloadData()
    }
    
}
