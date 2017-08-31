//
//  HomeViewController.swift
//  Thirty
//
//  Created by Alan Scarpa on 2/13/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import UIKit

class HomeTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate {

    let searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    
    let mockData = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
        
        tableView.tableHeaderView = searchController.searchBar
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
    }
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        //if !searchController.isActive { resetTableView() }
        print("updateSearchResults")
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchQuery = searchBar.text else { return }
        searchForContactWithString(searchQuery)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        //if searchText.isEmpty { resetTableView() }
        print("textDidChange")
    }
    
    func searchForContactWithString(_ query: String) {
        FirebaseManager.shared.searchForUserWithUsername(query) { result in
            switch result {
            case .Success(_):
                print("REFRESHTABLEVIEW")
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
    
}
