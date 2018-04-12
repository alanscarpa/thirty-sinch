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
import Contacts

class HomeTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchResultsTableViewCellDelegate {

    var searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    var searchResults = [User]()
    var isVisible = false
    var hasLoaded = false
    var loadingView = UIView()
    let numberOfFriendsNeededToHideAddressBook = 5
    private let headerInSectionHeight: CGFloat = 24
    let contactStore = CNContactStore()
    var foundAddressBookContacts = [CNContact]()
    lazy var allAddressBookContacts: [CNContact] = {
        let contactStore = CNContactStore()
        let keysToFetch = [CNContactGivenNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching results for container")
            }
        }
        return results
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLoaderView()
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
    
    func setUpLoaderView() {
        loadingView = UIView(frame: navigationController!.view.frame)
        loadingView.backgroundColor = .thPrimaryPurple
        THSpinner.showSpinnerOnView(loadingView)
        navigationController?.view.addSubview(loadingView)
    }
    
    func tearDownLoaderView() {
        THSpinner.dismiss()
        UIView.animate(withDuration: 0.5, animations: {
            self.loadingView.alpha = 0
        }) { complete in
            if complete {
                self.loadingView.removeFromSuperview()
            }
        }
    }
    
    func setUpSearchController() {
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .gray
        searchController.searchBar.backgroundColor  = .thPrimaryPurple
        let textFieldInsideSearchBar = searchController.searchBar.value(forKey: "searchField") as? UITextField
        textFieldInsideSearchBar?.textColor = .white
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        definesPresentationContext = true
    }
    
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
    
    func getContacts() {
        FirebaseManager.shared.getContacts { [weak self] result in
            switch result {
            case .success():
                FirebaseManager.shared.getFeaturedUsers { [weak self] result in
                    self?.hasLoaded = true
                    self?.tearDownLoaderView()
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
    
    // MARK: - TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching {
            return foundAddressBookContacts.count > 0 ? 2 : 1
        } else if UserManager.shared.numberOfFriends < numberOfFriendsNeededToHideAddressBook {
            return UserManager.shared.hasFeaturedUsers ? 3 : 2
        } else {
            return UserManager.shared.hasFeaturedUsers ? 2 : 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionType(section) {
        case .searching:
            return searchResults.count + foundAddressBookContacts.count
        case .featured:
            return UserManager.shared.featuredUsers.count
        case .friends:
            return UserManager.shared.hasFriends ? UserManager.shared.numberOfFriends : 1
        case .addressBook:
            return allAddressBookContacts.count
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch sectionType(section) {
        case .searching, .addressBook, .friends:
            return headerInSectionHeight
        case .featured:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: headerInSectionHeight))
        let label = UILabel(frame: CGRect(x: 10, y: 0, width: tableView.frame.size.width, height: headerInSectionHeight))
        label.font = UIFont(name: "Avenir-Black", size: 12)!
        label.textColor = .thPrimaryPurple
        view.addSubview(label)
        view.backgroundColor = .white
        switch sectionType(section) {
        case .featured:
            return nil
        case .searching:
            label.text = "SEARCH RESULTS"
        case .friends:
            label.text = "FRIENDS"
        case .addressBook:
            label.text = "ADDRESS BOOK"
        }
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = sectionType(indexPath.section)
        print(indexPath.section)
        switch section {
        case .searching:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
            cell.usernameLabel.text = searchResults[indexPath.row].username
            cell.addButton.isHidden = false
            cell.delegate = self
            return cell
        case .featured:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedTableViewCell.nibName, for: indexPath) as! FeaturedTableViewCell
            let featuredUser = UserManager.shared.featuredUsers[indexPath.row]
            cell.setUpForFeaturedUser(featuredUser)
            return cell
        case .friends:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
            if !UserManager.shared.hasFriends {
                cell.displayNoFriendsLabel()
            } else {
                cell.usernameLabel.text = UserManager.shared.contacts[indexPath.row].username
                cell.addButton.isHidden = true
                cell.delegate = self
            }
            return cell
        case .addressBook:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
            let contact =  allAddressBookContacts[indexPath.row]
            cell.usernameLabel.text = contact.givenName + " " + contact.familyName
            cell.addButton.isHidden = false
            cell.delegate = self
            return cell
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if isFeaturedSection(indexPath.section) {
            let featuredUser = UserManager.shared.featuredUsers[indexPath.row]
            RootViewController.shared.pushFeatureVCWithFeaturedUser(featuredUser)
        } else if UserManager.shared.hasFriends && !isSearching {
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
    
    // MARK: - UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        if !searchController.isActive && searchController.searchBar.text?.isEmpty == false { resetTableView() }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchQuery = searchBar.text else { return }
        searchForContactWithString(searchQuery)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        isSearching = true
        // This fires when user taps "x" and clears search field.
        if searchText.isEmpty {
            resetTableView(searchControllerIsActive: true)
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard searchController.searchBar.text?.isEmpty == false else { return }
        resetTableView()
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
            // isSearching = false
            tableView.reloadData()
        } else {
            FirebaseManager.shared.searchForUserWithUsername(query) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .success(let user):
                    // TODO: Dont populate if user is currentUsername
                    if let user = user {
                        strongSelf.searchResults = [user]
                    } else {
                        // TODO: Show "no user" cell
                        strongSelf.searchResults = []
                        do {
                            strongSelf.foundAddressBookContacts = try strongSelf.contactsFromAddressBook(query)
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    strongSelf.tableView.reloadData()
                case .failure(let error):
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "Search Failed (FB)", message: error.localizedDescription)
                    strongSelf.present(alertVC, animated: true, completion: nil)
                }
            }
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
    
    // MARK: - Contacts Search
    
    fileprivate func contactsFromAddressBook(_ query: String) throws -> [CNContact] {
        var foundContacts = [CNContact]()
        do {
            if let contactsFromName = try contactsFromNameQuery(query) {
                foundContacts.append(contentsOf: contactsFromName)
            }
            if let contactsFromPhoneNumber = contactsFromPhoneNumberQuery(query) {
                foundContacts.append(contentsOf: contactsFromPhoneNumber)
            }
            if let contactsFromEmail = contactsFromEmailQuery(query) {
                foundContacts.append(contentsOf: contactsFromEmail)
            }
            return Array(Set(foundContacts)).sorted(by: { (c1, c2) -> Bool in
                c1.givenName < c2.givenName
            })
        } catch {
            throw error
        }
    }
    
    fileprivate func contactsFromNameQuery(_ query: String) throws -> [CNContact]? {
        let predicate = CNContact.predicateForContacts(matchingName: query)
        let keys = [CNContactGivenNameKey, CNContactEmailAddressesKey, CNContactPhoneNumbersKey, CNContactFamilyNameKey]
        var contacts = [CNContact]()
        do {
            contacts = try contactStore.unifiedContacts(matching: predicate, keysToFetch: keys as [CNKeyDescriptor])
            return !contacts.isEmpty ? contacts : nil
        } catch {
            throw error
        }
    }
    
    fileprivate func contactsFromPhoneNumberQuery(_ query: String) -> [CNContact]? {
        var phoneNumberResults: [CNContact] = []
        for contact in allAddressBookContacts {
            if (!contact.phoneNumbers.isEmpty) {
                let phoneNumberToCompareAgainst = query.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                for phoneNumber in contact.phoneNumbers {
                    let phoneNumberStruct = phoneNumber.value
                    let phoneNumberString = phoneNumberStruct.stringValue
                    let phoneNumberToCompare = phoneNumberString.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                    if phoneNumberToCompare == phoneNumberToCompareAgainst {
                        phoneNumberResults.append(contact)
                    }
                }
            }
        }
        return !phoneNumberResults.isEmpty ? phoneNumberResults : nil
    }
    
    fileprivate func contactsFromEmailQuery(_ query: String) -> [CNContact]? {
        var emailResults: [CNContact] = []
        for contact in allAddressBookContacts {
            if (!contact.emailAddresses.isEmpty) {
                let emailToCompareAgainst = query.lowercased().components(separatedBy: NSCharacterSet.alphanumerics.inverted).joined(separator: "")
                for email in contact.emailAddresses {
                    let emailString = email.value.lowercased
                    let emailToCompare = emailString.components(separatedBy: NSCharacterSet.alphanumerics.inverted).joined(separator: "")
                    if emailToCompare == emailToCompareAgainst {
                        emailResults.append(contact)
                    }
                }
            }
        }
        return !emailResults.isEmpty ? emailResults : nil
    }
    
    // MARK: - Helpers
    
    func resetTableView(searchControllerIsActive: Bool = false) {
        searchResults = []
        isSearching = false
        searchController.isActive = searchControllerIsActive
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
    
    enum SectionType {
        case featured
        case friends
        case addressBook
        case searching
    }
    
    private func sectionType(_ section: Int) -> SectionType {
        if isSearching {
            return SectionType.searching
        } else if isFeaturedSection(section) {
            return SectionType.featured
        } else if isFriendsSection(section) {
            return SectionType.friends
        } else {
            return SectionType.addressBook
        }
    }
    
    private func isFeaturedSection(_ section: Int) -> Bool {
        guard !isSearching else { return false }
        return UserManager.shared.hasFeaturedUsers && section == 0
    }
    
    private func isFriendsSection(_ section: Int) -> Bool {
        if isSearching {
            return section == 0
        } else if UserManager.shared.hasFeaturedUsers {
            return section == 1
        } else {
            return section == 0
        }
    }
    
    private func isAddressBookSection(_ section: Int) -> Bool {
        guard section > 0 else { return false }
        if UserManager.shared.hasFeaturedUsers {
            return section == 2
        } else {
            return section == 1
        }
    }
    
}
