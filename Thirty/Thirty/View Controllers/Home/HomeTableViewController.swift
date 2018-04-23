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
import MessageUI

class HomeTableViewController: UITableViewController, UISearchResultsUpdating, UISearchBarDelegate, SearchResultsTableViewCellDelegate, MFMessageComposeViewControllerDelegate, ContactTableViewCellDelegate {
    
    var searchController = UISearchController(searchResultsController: nil)
    var isSearching = false
    var searchResults = [User]()
    var isVisible = false
    var loadingView = UIView()
    let numberOfFriendsNeededToHideAddressBook = 15
    private let headerInSectionHeight: CGFloat = 24
    
    let contactStore = CNContactStore()
    var foundAddressBookContacts = [CNContact]()
    lazy var allAddressBookContacts: [CNContact] = {
        guard CNContactStore.authorizationStatus(for: .contacts) == .authorized else { return [CNContact]() }
 
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
        return results.sorted(by: { $0.givenName < $1.givenName })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpLoaderView()
        getData()
        setUpSearchController()
        setUpTableView()
        FirebaseManager.shared.updateDeviceToken()
        if !UserDefaultsManager.shared.hasLaunchedApp {
            RootViewController.shared.presentLockScreenTipVC()
            UserDefaultsManager.shared.hasLaunchedApp = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        RootViewController.shared.showNavigationBar = false
        RootViewController.shared.showStatusBarBackground = true
        tableView.reloadData()
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
        tableView.keyboardDismissMode = .onDrag
        // This prevents the gray view from being seen when user exposes the bounce area.
        let backgroundView = UIView()
        backgroundView.backgroundColor = .thPrimaryPurple
        tableView.backgroundView = backgroundView
        tableView.register(UINib(nibName: FeaturedTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: FeaturedTableViewCell.nibName)
        tableView.register(UINib(nibName: SearchResultTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: SearchResultTableViewCell.nibName)
        tableView.register(UINib(nibName: ContactTableViewCell.nibName, bundle: nil), forCellReuseIdentifier: ContactTableViewCell.nibName)
        tableView.backgroundColor = .thPrimaryPurple
        tableView.separatorInset = .zero
        tableView.tableHeaderView = searchController.searchBar
    }
    
    func getData() {
        FirebaseManager.shared.getCurrentUserDetails { [weak self] result in
            switch result {
            case .success():
                FirebaseManager.shared.getContacts { [weak self] result in
                    switch result {
                    case .success():
                        FirebaseManager.shared.getFeaturedUsers { [weak self] result in
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
                        self?.tearDownLoaderView()
                        let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to get contacts.", message: error.localizedDescription)
                        self?.present(alertVC, animated: true, completion: nil)
                    }
                }
            case .failure(let error):
                self?.tearDownLoaderView()
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to get current user.", message: error.localizedDescription)
                self?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - TableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching {
            return foundAddressBookContacts.count > 0 ? 2 : 1
        } else if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
            return UserManager.shared.hasFeaturedUsers ? 3 : 2
        } else if CNContactStore.authorizationStatus(for: .contacts) == .authorized {
            if UserManager.shared.numberOfFriends < numberOfFriendsNeededToHideAddressBook {
                return UserManager.shared.hasFeaturedUsers ? 3 : 2
            } else {
                return UserManager.shared.hasFeaturedUsers ? 2 : 1
            }
        } else {
            return UserManager.shared.hasFeaturedUsers ? 2 : 1
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sectionType(section) {
        case .searching:
            return searchResults.isEmpty ? 1 : searchResults.count
        case .featured:
            return UserManager.shared.featuredUsers.count
        case .friends:
            return UserManager.shared.hasFriends ? UserManager.shared.numberOfFriends : 1
        case .addressBook:
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                return 1
            } else {
                return isSearching ? foundAddressBookContacts.count : allAddressBookContacts.count
            }
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
        switch section {
        case .searching:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.nibName, for: indexPath) as! ContactTableViewCell
            cell.delegate = self
            if searchResults.count > 0 {
                cell.setUpForUser(searchResults[indexPath.row])
            } else {
                cell.displayNoResultsLabel()
            }
            return cell
        case .featured:
            let cell = tableView.dequeueReusableCell(withIdentifier: FeaturedTableViewCell.nibName, for: indexPath) as! FeaturedTableViewCell
            let featuredUser = UserManager.shared.featuredUsers[indexPath.row]
            cell.setUpForFeaturedUser(featuredUser)
            return cell
        case .friends:
            let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.nibName, for: indexPath) as! ContactTableViewCell
            cell.delegate = self
            if UserManager.shared.hasFriends {
                cell.setUpForUser(UserManager.shared.contacts[indexPath.row])
            } else {
                 cell.displayNoFriendsLabel()
            }
            return cell
        case .addressBook:
            let cell = tableView.dequeueReusableCell(withIdentifier: SearchResultTableViewCell.nibName, for: indexPath) as! SearchResultTableViewCell
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                cell.displayAskForContactPermission()
                return cell
            } else {
                let contact = isSearching ? foundAddressBookContacts[indexPath.row] : allAddressBookContacts[indexPath.row]
                cell.setUpForContactName(contact.givenName + " " + contact.familyName)
                cell.delegate = self
                return cell
            }
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sectionType(indexPath.section) {
        case .addressBook:
            if CNContactStore.authorizationStatus(for: .contacts) == .notDetermined {
                CNContactStore().requestAccess(for: .contacts) { (granted, _) in
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        case .searching:
            let user = searchResults[indexPath.row]
            if UserManager.shared.contacts.contains(where: { $0.username == user.username }) {
                callUser(user)
            }
        case .featured:
            let featuredUser = UserManager.shared.featuredUsers[indexPath.row]
            RootViewController.shared.pushFeatureVCWithFeaturedUser(featuredUser)
        case .friends:
            guard UserManager.shared.hasFriends else { return }
            let user = UserManager.shared.contacts[indexPath.row]
            callUser(user)
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
        searchForContactWithString(searchQuery.lowercased())
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
    
    // MARK: - Search
    
    func searchForContactWithString(_ query: String) {
        isSearching = true
        searchResults = []
        guard query != UserManager.shared.currentUserUsername else {
            tableView.reloadData()
            return
        }
        if let user = UserManager.shared.contacts.filter({ $0.username.lowercased() == query }).first {
            appendUserToSearchResults(user)
        } else if let user = UserManager.shared.contacts.filter({ $0.fullName == query }).first {
            appendUserToSearchResults(user)
        }
        let usersWithFirstname = UserManager.shared.contacts.filter({ $0.firstName == query })
        usersWithFirstname.forEach { user in
            appendUserToSearchResults(user)
        }
        let usersWithLastName = UserManager.shared.contacts.filter({ $0.lastName == query })
        usersWithLastName.forEach { user in
            appendUserToSearchResults(user)
        }
        
        FirebaseManager.shared.searchForUserWithUsername(query) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let user):
                if let user = user {
                    strongSelf.appendUserToSearchResults(user)
                    strongSelf.tableView.reloadData()
                } else {
                    FirebaseManager.shared.searchForUserWithFullName(query) { [weak self] result in
                        guard let strongSelf = self else { return }
                        switch result {
                        case .success(let users):
                            if let users = users, !users.isEmpty {
                                users.forEach { user in
                                    strongSelf.appendUserToSearchResults(user)
                                }
                            }
                            do {
                                strongSelf.foundAddressBookContacts = try strongSelf.contactsFromAddressBook(query)
                            } catch {
                                print(error.localizedDescription)
                            }
                        case .failure(let error):
                            let alertVC = UIAlertController.createSimpleAlert(withTitle: "Search Failed (FB)", message: error.localizedDescription)
                            strongSelf.present(alertVC, animated: true, completion: nil)
                        }
                        strongSelf.tableView.reloadData()
                    }
                }
            case .failure(let error):
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Search Failed (FB)", message: error.localizedDescription)
                strongSelf.present(alertVC, animated: true, completion: nil)
                strongSelf.tableView.reloadData()
            }
        }
    }
    
    // MARK: - ContactTableViewCellDelegate
    
    func addButtonWasTapped(sender: ContactTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        let tappedUser = searchResults[indexPath.row]
        FirebaseManager.shared.addUserAsFriend(username: tappedUser.username) { [weak self] result in
            switch result {
            case .success(_):
                UserManager.shared.addUserAsContact(tappedUser)
                self?.resetTableView()
            case .failure(let error):
                let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to add user.", message: error.localizedDescription)
                self?.present(alertVC, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - SearchResultTableViewCellDelegate
    
    func inviteButtonWasTapped(sender: SearchResultTableViewCell) {
        guard let indexPath = tableView.indexPath(for: sender) else { return }
        let contact = isSearching ? foundAddressBookContacts[indexPath.row] : allAddressBookContacts[indexPath.row]
        guard let phoneNumber = contact.phoneNumbers.first?.value.stringValue else { return }
        if MFMessageComposeViewController.canSendText() {
            let messageComposeVC = MFMessageComposeViewController()
            messageComposeVC.body = "hey - download this app real quick.  it's a fun way to have 30 second video chats. https://that30app.com/download"
            messageComposeVC.recipients = [phoneNumber]
            messageComposeVC.messageComposeDelegate = self
            present(messageComposeVC, animated: true, completion: nil)
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
    
    private func callUser(_ user: User) {
        FirebaseManager.shared.getCurrentDetailsForUser(user) { [weak self] result in
            guard let strongSelf = self else { return }
            switch result {
            case .success(let user):
                if user.doNotDisturb {
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "User is not accepting 30s at this time 🤷‍♂️", message: "This user has do not disturb mode enabled.  💤  Try again later.")
                    DispatchQueue.main.async {
                        strongSelf.present(alertVC, animated: true, completion: nil)
                    }
                } else if let deviceToken = user.deviceToken, !deviceToken.isEmpty {
                    let call = Call(uuid: UUID(), caller: UserManager.shared.currentUserUsername, callerFullName: UserManager.shared.currentUser.fullName, callee: user.username, calleeDeviceToken: deviceToken, direction: .outgoing)
                    if AVCaptureDevice.authorizationStatus(for: .video) != .authorized || AVAudioSession.sharedInstance().recordPermission() != .granted  {
                        strongSelf.requestCameraAndMicrophonePermissions { granted in
                            if granted {
                                RootViewController.shared.pushCallVCWithCall(call)
                            }
                        }
                    } else {
                        RootViewController.shared.pushCallVCWithCall(call)
                    }
                } else {
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to make 30", message: "This user is currently logged out and unable to receive 30s at this time 😞")
                    DispatchQueue.main.async {
                        strongSelf.present(alertVC, animated: true, completion: nil)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    let alertVC = UIAlertController.createSimpleAlert(withTitle: "Unable to call user.", message: error.localizedDescription)
                    strongSelf.present(alertVC, animated: true, completion: nil)
                }
            }
        }
    }
    
    private func appendUserToSearchResults(_ user: User) {
        guard user.username != UserManager.shared.currentUserUsername else { return }
        guard !searchResults.contains(where: { $0.username == user.username }) else { return }
        searchResults.append(user)
    }
    
    private func resetTableView(searchControllerIsActive: Bool = false) {
        searchResults = []
        foundAddressBookContacts = []
        isSearching = false
        searchController.isActive = searchControllerIsActive
        tableView.reloadData()
    }
    
    var permissionCompletion: ((Bool) -> Void)?
    
    private func requestCameraAndMicrophonePermissions(completion: @escaping (Bool) -> Void) {
        let permissionsVC = CameraMicrophoneTipViewController()
        permissionsVC.permissionsCompletion = completion
        present(permissionsVC, animated: true, completion: nil)
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Section Logic
    
    enum SectionType {
        case featured
        case friends
        case addressBook
        case searching
    }
    
    private func sectionType(_ section: Int) -> SectionType {
        if isSearching {
            return isAddressBookSection(section) ? SectionType.addressBook : SectionType.searching
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
        if isSearching {
            return section == 1
        } else if UserManager.shared.hasFeaturedUsers {
            return section == 2
        } else {
            return section == 1
        }
    }
    
}
