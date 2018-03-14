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
    @objc optional func currentUserDidSignOut()
    @objc optional func callWasDeclinedByCallee()
}

class FirebaseManager {
    
    static let shared = FirebaseManager()
    weak var delegate: FirebaseObserverDelegate?
    private let databaseRef = FIRDatabase.database().reference()
    var activeCallsRef: FIRDatabaseReference {
        return databaseRef.child("active-calls")
    }
    var currentUserIsSignedIn: Bool {
        return FIRAuth.auth()?.currentUser != nil
    }
    
    private var currentUserIsSignedOut: Bool {
        return FIRAuth.auth()?.currentUser == nil
    }
    
    private var authStateListener: FIRAuthStateDidChangeListenerHandle!
    private var observeCallEndedStateHandle: FIRDatabaseHandle?
    private var observeCallPendingStateHandle: FIRDatabaseHandle?
    private init() {}
    
    func listenForAuthStateChanges() {
        authStateListener = FIRAuth.auth()?.addStateDidChangeListener(authStateChangedHandler)
    }
    
    func stopListeningForAuthStateChanges() {
        FIRAuth.auth()?.removeStateDidChangeListener(authStateListener)
    }
    
    private func authStateChangedHandler(auth: FIRAuth, user: FIRUser?) -> Swift.Void {
        if currentUserIsSignedOut {
            delegate?.currentUserDidSignOut?()
        }
    }
    
    func signOutCurrentUser(completion: @escaping (Result<Void>) -> Void) {
        do {
            try FIRAuth.auth()?.signOut()
            UserManager.shared.currentUserUsername = nil
            UserManager.shared.currentUserPassword = nil
            completion(.Success)
        } catch {
            completion(.Failure(error))
        }
    }
    
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
        activeCallsRef.child(call.roomName).updateChildValues(["call-state": "declined"])
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
                completion(.Failure(error))
            } else {
                completion(.Success)
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
    
    func createNewUser(user: User, completion: @escaping (Result<Void>) -> Void) {
        // STEP 1 - First we create our user and sign in because sign in is required to access DB
        FIRAuth.auth()?.createUser(withEmail: user.email, password: user.password) { [weak self] (fbUser, error) in
            if let error = error {
                completion(.Failure(error))
            } else {
                // STEP 2 - Make sure the username is available
                self?.databaseRef.child("users").child(user.username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
                    if snapshot.exists() {
                        // Delete our user from DB if username already exists
                        fbUser?.delete(completion: { error in
                            completion(.Failure(error ?? THError(errorType: .usernameAlreadyExists)))
                        })
                    } else {
                        // STEP 3 - Then we add details to user which allows a username sign-in
                        if let fbUser = fbUser {
                            self?.databaseRef.child("users")
                                .child(user.username.lowercased())
                                .setValue(["phone-number": user.phoneNumber,
                                           "uid": fbUser.uid,
                                           "display-name": user.username,
                                           "email": user.email,
                                           "device-token": user.deviceToken], withCompletionBlock: { (error, ref) in
                                            if let error = error {
                                                completion(.Failure(error))
                                            } else {
                                                self?.completeUserSetup(username: user.username, password: user.password)
                                                completion(.Success)
                                            }
                                })
                        } else {
                            completion(.Failure(THError(errorType: .blankFBUserReturned)))
                        }
                    }
                }) { (error) in
                    // Delete our user if we were unable to access DB after creating user
                    fbUser?.delete(completion: { error in
                        completion(.Failure(error ?? THError(errorType: .usernameAlreadyExists)))
                    })
                }
            }
        }
    }
    
    func logInUserWithUsername(_ username: String, password: String, completion: @escaping (Result<Void>) -> Void) {
        // TODO: if user logs in with email, it crashes because invalid characters
        FIRAuth.auth()?.signInAnonymously { [weak self] (anonymousUser, error) in
            self?.databaseRef.child("users").child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
                anonymousUser?.delete(completion: { deletionError in
                    if let deletionError = deletionError {
                        completion(.Failure(deletionError))
                    } else {
                        guard snapshot.exists() else {
                            completion(.Failure(THError(errorType: .usernameDoesNotExist)))
                            return
                        }
                        let value = snapshot.value as? NSDictionary
                        if let email = value?["email"] as? String {
                            FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                                if let error = error {
                                    completion(.Failure(error))
                                } else {
                                    if !TokenUtils.deviceToken.isEmpty {
                                        self?.databaseRef.child("users")
                                            .child(username.lowercased()).updateChildValues(["device-token": TokenUtils.deviceToken])
                                    }
                                    // TODO: Get entire profile and set user.
                                    self?.completeUserSetup(username: username, password: password)
                                    completion(.Success)
                                }
                            }
                        }
                    }
                })
            }) { (error) in
                anonymousUser?.delete(completion: { deletionError in
                    completion(.Failure(deletionError ?? error))
                })
            }
        }
    }
    
    private func completeUserSetup(username: String, password: String) {
        UserManager.shared.currentUserUsername = username
        UserManager.shared.currentUserPassword = password
    }
    
    func searchForUserWithUsername(_ username: String, completion: @escaping (Result<User?>) -> Void) {
        databaseRef.child("users").child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? NSDictionary {
                let displayName = value["display-name"] as? String ?? ""
                let email = value["email"] as? String ?? ""
                let phoneNumber = value["phone-number"] as? String ?? ""
                let deviceToken = value["device-token"] as? String ?? ""
                let user = User(username: displayName, email: email, phoneNumber: phoneNumber, password: "", deviceToken: deviceToken)
                completion(.Success(user))
            } else {
                completion(.Success(nil))
            }
        }) { (error) in
            completion(.Failure(error))
        }
    }
    
    func addUserAsFriend(username: String, completion: @escaping (Result<Void>) -> Void) {
        guard let currentUsername = UserManager.shared.currentUserUsername?.lowercased() else {
            return completion(.Failure(THError.init(errorType: .noCurrentUser)))
        }
        databaseRef.child("friends")
            .child(currentUsername)
            .setValue([username.lowercased(): true], withCompletionBlock: { (error, ref) in
                        if let error = error {
                            completion(.Failure(error))
                        } else {
                            completion(.Success)
                        }
            })
    }
    
    func getContacts(completion: @escaping (Result<Void>) -> Void) {
        guard let currentUsername = UserManager.shared.currentUserUsername?.lowercased() else {
            return completion(.Failure(THError.init(errorType: .noCurrentUser)))
        }
        // TODO: Change "users" back to ("friends").child(currentUsername)
        databaseRef.child("users").observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            // TODO: Get display-name somehow
            if let usernames = value?.allKeys as? [String] {
                for username in usernames {
                    guard username != currentUsername else { continue }
                    var user = User()
                    user.username = username
                    if let deviceToken = (value?[username] as? NSDictionary)?["device-token"] as? String {
                        user.deviceToken = deviceToken
                    }
                    UserManager.shared.contacts.append(user)
                }
                UserManager.shared.contacts.sort(by: { $0.username < $1.username })
            }
            completion(.Success)
        }) { (error) in
            completion(.Failure(error))
        }
    }
    
    func getDeviceTokenForUsername(_ username: String, completion: @escaping (Result<String>) -> Void) {
        databaseRef.child("users").child(username).observeSingleEvent(of: .value, with: { snapshot in
            let value = snapshot.value as? NSDictionary
            if let deviceToken = value?["device-token"] as? String {
                completion(.Success(deviceToken))
            } else {
                completion(.Failure(THError.init(errorType: .unableToGetDeviceToken)))
            }
        }) { (error) in
            completion(.Failure(error))
        }
    }
}
