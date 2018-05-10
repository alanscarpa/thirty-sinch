//
//  FirebaseManager.swift
//  Thirty
//
//  Created by Alan Scarpa on 6/29/17.
//  Copyright © 2017 Thirty. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth
import FirebaseDatabase

@objc protocol FirebaseObserverDelegate: class {
    @objc optional func currentUserDidLogOut()
    @objc optional func callWasDeclinedByCallee()
}

class FirebaseManager {
    static let shared = FirebaseManager(userManager: UserManager.shared)

    // MARK: Dependencies

    private let userManager: UserManager

    weak var delegate: FirebaseObserverDelegate?

    // MARK: Firebase Properties

    private let databaseRef = Database.database().reference()
    private let usersRef = Database.database().reference().child("users")
    private let friendsRef = Database.database().reference().child("friends")
    private let blockedUsersRef = Database.database().reference().child("blocked-users")
    private let activeCallsRef = Database.database().reference().child("active-calls")

    var currentUsersFriendsRef: DatabaseReference? {
        // References will crash if username is blank ""
        guard !userManager.currentUserUsername.lowercased().isEmpty else { return nil }
        return friendsRef.child(userManager.currentUserUsername.lowercased())
    }
    
    var currentUserRef: DatabaseReference? {
        guard !userManager.currentUserUsername.lowercased().isEmpty else { return nil }
        return usersRef.child(userManager.currentUserUsername.lowercased())
    }

    var currentUser: Firebase.User? {
        return Auth.auth().currentUser
    }

    var currentUserIsLoggedIn: Bool {
        return currentUser != nil
    }
    
    private var authStateListener: AuthStateDidChangeListenerHandle!
    private var observeCallEndedStateHandle: DatabaseHandle?
    private var observeCallPendingStateHandle: DatabaseHandle?

    // MARK: Init

    init(userManager: UserManager) {
        self.userManager = userManager
    }

    // MARK: Auth State Changes
    
    func listenForAuthStateChanges() {
        authStateListener = Auth.auth().addStateDidChangeListener(authStateChangedHandler)
    }
    
    func stopListeningForAuthStateChanges() {
        Auth.auth().removeStateDidChangeListener(authStateListener)
    }
    
    private func authStateChangedHandler(auth: Auth, user: Firebase.User?) {
        if !currentUserIsLoggedIn {
            delegate?.currentUserDidLogOut?()
        }
    }

    // MARK: Log In/Out

    func logInUserWithUsername(_ username: String, password: String, completion: @escaping (Result<Void>) -> Void) {
        Auth.auth().signInAnonymously { [weak self] (anonymousUser, error) in
            self?.databaseRef.child("users").child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
                anonymousUser?.delete(completion: { deletionError in
                    if let deletionError = deletionError {
                        completion(.failure(deletionError))
                    } else {
                        guard snapshot.exists() else {
                            completion(.failure(THError.usernameDoesNotExist))
                            return
                        }
                        let value = snapshot.value as? NSDictionary
                        if let email = value?["email"] as? String {
                            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                                if let error = error {
                                    completion(.failure(error))
                                } else {
                                    if !TokenUtils.deviceToken.isEmpty {
                                        self?.databaseRef.child("users")
                                            .child(username.lowercased()).updateChildValues(["device-token": TokenUtils.deviceToken])
                                    }
                                    completion(.success)
                                }
                            }
                        }
                    }
                })
            }) { (error) in
                anonymousUser?.delete(completion: { deletionError in
                    completion(.failure(deletionError ?? error))
                })
            }
        }
    }
    
    func logOutCurrentUser(completion: @escaping (Result<Void>) -> Void) {
        currentUserRef?.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                self.currentUserRef?.updateChildValues(["device-token":""]) { (error, ref) in
                    self.authSignOut()
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success)
                    }
                }
            } else {
                self.authSignOut()
                completion(.success)
            }
        }
    }
    
    func authSignOut() {
        try? Auth.auth().signOut()
    }

    // MARK: Create User
    
    func createNewUser(user: User, completion: @escaping (Result<Void>) -> Void) {
        // STEP 1 - First we create our user and sign in because sign in is required to access DB
        Auth.auth().createUser(withEmail: user.email, password: user.password) { [weak self] (fbUser, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                // STEP 2 - Make sure the username is available
                self?.databaseRef.child("users").child(user.username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists() {
                        // Delete our user from DB if username already exists
                        fbUser?.delete(completion: { error in
                            completion(.failure(error ?? THError.usernameAlreadyExists))
                        })
                    } else {
                        // STEP 3 - We add a display name to the firebase auth user
                        if let newlyCreatedUser = Auth.auth().currentUser {
                            let changeRequest = newlyCreatedUser.createProfileChangeRequest()
                            changeRequest.displayName = user.username
                            changeRequest.commitChanges { error in
                                if let error = error {
                                    completion(.failure(error))
                                } else {
                                    // STEP 4 - Then we add details to user which allows a username sign-in
                                    if let fbUser = fbUser {
                                        self?.databaseRef.child("users")
                                            .child(user.username.lowercased())
                                            .setValue(["phone-number": user.phoneNumber,
                                                       "uid": fbUser.uid,
                                                       "display-name": user.username,
                                                       "email": user.email,
                                                       "device-token": user.deviceToken,
                                                       "first-name": user.firstName,
                                                       "last-name": user.lastName,
                                                       "full-name": user.firstName.lowercased() + " " +  user.lastName.lowercased()], withCompletionBlock: { (error, ref) in
                                                        if let error = error {
                                                            completion(.failure(error))
                                                        } else {
                                                            completion(.success)
                                                        }
                                            })
                                    } else {
                                        completion(.failure(THError.blankFBUserReturned))
                                    }
                                }
                            }
                        }
                    }
                }) { (error) in
                    // Delete our user if we were unable to access DB after creating user
                    fbUser?.delete(completion: { error in
                        completion(.failure(error ?? THError.usernameAlreadyExists))
                    })
                }
            }
        }
    }
    
    // MARK: - Users
    
    func getCurrentUserDetails(completion: @escaping (Result<Void>) -> Void) {
        let cancelBlock: (Error) -> Void = { completion(.failure($0) )}
        currentUserRef?.observeSingleEvent(of: .value, with: { snapshot in
            guard let user = snapshot.value as? [String : Any] else {
                completion(.failure(THError.noCurrentUser))
                return
            }
            guard
                let name = user["display-name"] as? String,
                let email = user["email"] as? String,
                let number = user["phone-number"] as? String
                else {
                    completion(.failure(THError.noCurrentUser))
                    return
            }
            let token = user["device-token"] as? String
            let firstName = user["first-name"] as? String ?? ""
            let lastName = user["last-name"] as? String ?? ""
            let currentUser = User(username: name, email: email, phoneNumber: number, password: "", deviceToken: token, firstName: firstName, lastName: lastName)
            if let doNotDisturb = user["do-not-disturb"] as? Bool {
                currentUser.doNotDisturb = doNotDisturb
            }
            UserManager.shared.currentUser = currentUser
            completion(.success)
        }, withCancel: cancelBlock)
    }
    
    // MARK: - Current User
    
    func getCurrentDetailsForUser(_ user: User, completion: @escaping (Result<User>) -> Void) {
        let cancelBlock: (Error) -> Void = { completion(.failure($0) )}
        usersRef.child(user.username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            guard let user = snapshot.value as? [String : Any] else {
                completion(.failure(THError.usernameDoesNotExist))
                return
            }
            guard
                let name = user["display-name"] as? String,
                let email = user["email"] as? String,
                let number = user["phone-number"] as? String
                else {
                    completion(.failure(THError.usernameDoesNotExist))
                    return
            }
            let token = user["device-token"] as? String
            let firstName = user["first-name"] as? String ?? ""
            let lastName = user["last-name"] as? String ?? ""
            let mostUpToDateUser = User(username: name, email: email, phoneNumber: number, password: "", deviceToken: token, firstName: firstName, lastName: lastName)
            if let doNotDisturb = user["do-not-disturb"] as? Bool {
                mostUpToDateUser.doNotDisturb = doNotDisturb
            }
            completion(.success(mostUpToDateUser))
        }, withCancel: cancelBlock)
    }
    
    // MARK: Blocked Status
    
    func userIsBlocked(_ user: User, isBlocked: @escaping (Bool) -> Void) {
        blockedUsersRef.child(user.username).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? NSDictionary,
                let blockedUsernames = value.allKeys as? [String] {
                isBlocked(blockedUsernames.contains(where: { $0 == UserManager.shared.currentUserUsername }))
            } else {
                isBlocked(false)
            }
        }
    }
    
    // MARK: Search Users

    func searchForUserWithUsername(_ username: String, completion: @escaping (Result<User?>) -> Void) {
        usersRef.child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? NSDictionary {
                let user = User(username: value["display-name"] as? String ?? "",
                                email: value["email"] as? String ?? "",
                                phoneNumber: value["phone-number"] as? String ?? "",
                                password: "",
                                deviceToken: value["device-token"] as? String ?? "",
                                firstName: value["first-name"] as? String ?? "",
                                lastName: value["last-name"] as? String ?? "")
                completion(.success(user))
            } else {
                completion(.success(nil))
            }
        }) { (error) in
            completion(.failure(error))
        }
    }
    
    func searchForUserWithFullName(_ fullName: String, completion: @escaping (Result<[User]?>) -> Void) {
        usersRef.queryOrdered(byChild: "full-name").queryEqual(toValue: fullName.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            if let foundUsers = snapshot.value as? [String: Any] {
                var users = [User]()
                let usernames = foundUsers.keys
                usernames.forEach { username in
                    guard let foundUser = foundUsers[username] as? [String: Any] else { return }
                    let user = User(username: foundUser["display-name"] as? String ?? "",
                                    email: foundUser["email"] as? String ?? "",
                                    phoneNumber: foundUser["phone-number"] as? String ?? "",
                                    password: "",
                                    deviceToken: foundUser["device-token"] as? String ?? "",
                                    firstName: foundUser["first-name"] as? String ?? "",
                                    lastName: foundUser["last-name"] as? String ?? "")
                    users.append(user)
                }
                completion(.success(users))
            } else {
                completion(.success(nil))
            }
        }) { (error) in
            completion(.failure(error))
        }
    }
    
    func usersWithPhoneNumber(_ phoneNumber: String, completion: @escaping (Result<[User]?>) -> Void) {
        usersRef.queryOrdered(byChild: "phone-number").queryEqual(toValue: phoneNumber).observeSingleEvent(of: .value, with: { snapshot in
            if let foundUsers = snapshot.value as? [String: Any] {
                var users = [User]()
                let usernames = foundUsers.keys
                usernames.forEach { username in
                    guard let foundUser = foundUsers[username] as? [String: Any] else { return }
                    let user = User(username: foundUser["display-name"] as? String ?? "",
                                    email: foundUser["email"] as? String ?? "",
                                    phoneNumber: foundUser["phone-number"] as? String ?? "",
                                    password: "",
                                    deviceToken: foundUser["device-token"] as? String ?? "",
                                    firstName: foundUser["first-name"] as? String ?? "",
                                    lastName: foundUser["last-name"] as? String ?? "")
                    users.append(user)
                }
                completion(.success(users))
            } else {
                completion(.success(nil))
            }
        }) { (error) in
            completion(.failure(error))
        }
    }

    // MARK: Friends
    
    func addUserAsFriend(username: String, completion: @escaping (Result<Void>) -> Void) {
        friendsRef
            .child(UserManager.shared.currentUserUsername.lowercased())
            .updateChildValues([username.lowercased(): true], withCompletionBlock: { [weak self] (error, ref) in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            self?.databaseRef.child("friends")
                                .child(username.lowercased())
                                .updateChildValues([UserManager.shared.currentUserUsername.lowercased(): true], withCompletionBlock: { (error, ref) in
                                    if let error = error {
                                        completion(.failure(error))
                                    } else {
                                        completion(.success)
                                    }
                                })
                        }
            })
    }

    func getContacts(completion: @escaping (Result<Void>) -> Void) {
        let cancelBlock: (Error) -> Void = { completion(.failure($0) )}
        currentUsersFriendsRef?.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            guard let friends = snapshot.value as? [String : Any] else {
                completion(.success) // user doesn't have any friends :(
                return
            }
            let usernames = friends.keys
            let dispatchGroup = DispatchGroup()
            usernames.forEach { username in
                dispatchGroup.enter()
                self?.usersRef.child(username).observeSingleEvent(of: .value) { snapshot in
                    defer { dispatchGroup.leave() }
                    guard
                        let value = snapshot.value as? [String : Any],
                        let name = value["display-name"] as? String,
                        let email = value["email"] as? String,
                        let number = value["phone-number"] as? String
                        else { return }
                    let token = value["device-token"] as? String
                    let firstName = value["first-name"] as? String ?? ""
                    let lastName = value["last-name"] as? String ?? ""
                    let user = User(username: name, email: email, phoneNumber: number, password: "", deviceToken: token, firstName: firstName, lastName: lastName)
                    if let doNotDisturb = value["do-not-disturb"] as? Bool {
                        user.doNotDisturb = doNotDisturb
                    }
                    self?.userManager.addUserAsContact(user)
                }
            }
            dispatchGroup.notify(queue: .main) {
                completion(.success)
            }
            }, withCancel: cancelBlock)
    }
    
    // MARK: Remove friend
    
    func removeUserAsFriend(username: String, completion: @escaping (Result<Void>) -> Void) {
        friendsRef
            .child(UserManager.shared.currentUserUsername.lowercased()).child(username).removeValue { [weak self] (error, ref) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self?.friendsRef
                        .child(username.lowercased())
                        .child(UserManager.shared.currentUserUsername.lowercased()).removeValue { (error, ref) in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success)
                        }
                    }
                }
        }
    }
    
    // MARK: Block User
    
    func blockUser(username: String, completion: @escaping (Result<Void>) -> Void) {
        blockedUsersRef
            .child(UserManager.shared.currentUserUsername.lowercased())
            .updateChildValues([username.lowercased(): true]) { [weak self] (error, ref) in
                if let error = error {
                    completion(.failure(error))
                } else {
                    self?.removeUserAsFriend(username: username) { (result) in
                        completion(result)
                    }
            }
        }
    }

    // MARK: Featured Users
    
    func getFeaturedUsers(completion: @escaping (Result<Void>) -> Void) {
        databaseRef.child("featured").observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? NSDictionary,
                let featuredUserNames = value.allKeys as? [String] {
                for featuredUserName in featuredUserNames {
                    let featuredUser = FeaturedUser()
                    if let username = (value[featuredUserName] as? NSDictionary)?["username"] as? String {
                        featuredUser.username = username
                    }
                    if let date = (value[featuredUserName] as? NSDictionary)?["feature-date"] as? Double {
                        featuredUser.featureDate = Date(timeIntervalSince1970: date)
                    }
                    if let photoUrlString = (value[featuredUserName] as? NSDictionary)?["photo-url"] as? String {
                        featuredUser.photoUrlString = photoUrlString
                    }
                    if let promoDetails = (value[featuredUserName] as? NSDictionary)?["promo-details"] as? String {
                        featuredUser.promoDetails = promoDetails
                    }
                    if let deviceToken = (value[featuredUserName] as? NSDictionary)?["device-token"] as? String {
                        featuredUser.deviceToken = deviceToken
                    }
                    UserManager.shared.featuredUsers.append(featuredUser)
                }
                UserManager.shared.featuredUsers.sort(by: { $0.username.lowercased() < $1.username.lowercased() })
                completion(.success)
            } else {
                completion(.failure(THError.unableToGetUsers))
            }
        }) { (error) in
            completion(.failure(error))
        }
    }

    // MARK: Device Token

    func updateDeviceToken() {
        currentUserRef?.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                self.currentUserRef?.updateChildValues(["device-token": TokenUtils.deviceToken])
            }
        }
    }
    
    func getDeviceTokenForUsername(_ username: String, completion: @escaping (Result<String>) -> Void) {
        databaseRef.child("users").child(username).observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let deviceToken = value?["device-token"] as? String {
                completion(.success(deviceToken))
            } else {
                completion(.failure(THError.unableToGetDeviceToken))
            }
        }) { (error) in
            completion(.failure(error))
        }
    }
    
    // MARK: Settings
    
    func setDoNotDisturb(_ doNotDisturb: Bool) {
        currentUserRef?.updateChildValues(["do-not-disturb": doNotDisturb])
    }

    // MARK: Calls

    func answeredCallWithRoomName(_ roomName: String) {
        activeCallsRef.child(roomName).updateChildValues(["call-state": "active"])
    }

    func endCallWithRoomName(_ roomName: String) {
        activeCallsRef.child(roomName).observeSingleEvent(of: .value) { [weak self] snapshot in
            if snapshot.exists() {
                self?.activeCallsRef.child(roomName).updateChildValues(["call-state": "ended"]) { [weak self] (error, ref) in
                    self?.activeCallsRef.child(roomName).removeValue()
                }
            }
        }
    }

    func declineCall(_ call: Call) {
        activeCallsRef.child(call.roomName).child("call-state").observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let strongSelf = self else { return }
            if let value = snapshot.value as? String {
                let callState = CallState(rawValue: value)!
                switch callState {
                case .pending:
                    strongSelf.activeCallsRef.child(call.roomName).updateChildValues(["call-state": "declined"]) { [weak self] (error, ref) in
                        self?.activeCallsRef.child(call.roomName).removeValue()
                    }
                case .active, .declined, .ended:
                    break
                }
            }
        }
    }

    func observeStatusForCallWithRoomName(_ roomName: String, completion: @escaping (CallState) -> Void) {
        let callStateRef = activeCallsRef.child(roomName).child("call-state")
        observeCallEndedStateHandle = callStateRef.observe(.value) { [weak self] snapshot in
            guard let strongSelf = self else { return }
            if let value = snapshot.value as? String {
                let callState = CallState(rawValue: value)!
                switch callState {
                case .ended:
                    callStateRef.removeObserver(withHandle: strongSelf.observeCallEndedStateHandle!)
                    completion(callState)
                case .active:
                    callStateRef.removeObserver(withHandle: strongSelf.observeCallEndedStateHandle!)
                case .declined, .pending:
                    break // no-op
                }
            } else {
                callStateRef.removeObserver(withHandle: strongSelf.observeCallEndedStateHandle!)
                // Value may return nil.  End call if that's the case.
                completion(CallState(rawValue: "ended")!)
            }
        }
    }

    func createCallStatusForCall(_ call: Call, completion: @escaping (Result<Void>) -> Void) {
        let callStateRef = activeCallsRef.child(call.roomName).child("call-state")
        callStateRef.setValue("pending") { (error, ref) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success)
            }
        }
        observeCallPendingStateHandle = callStateRef.observe(.value) { [weak self] snapshot in
            guard let strongSelf = self else { return }
            if let value = snapshot.value as? String {
                let callState = CallState(rawValue: value)!
                let cleanUpCall = {
                    self?.activeCallsRef.child(call.roomName).removeValue()
                    callStateRef.removeObserver(withHandle: strongSelf.observeCallPendingStateHandle!)
                }
                switch callState {
                case .pending, .active:
                    break
                case .declined:
                    self?.delegate?.callWasDeclinedByCallee?()
                    cleanUpCall()
                case .ended:
                    cleanUpCall()
                }
            }
        }
    }
}
