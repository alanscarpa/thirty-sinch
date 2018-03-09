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

protocol FirebaseManagerDelegate: class {
    func currentUserDidSignOut()
}

class FirebaseManager {
    
    static let shared = FirebaseManager()
    weak var delegate: FirebaseManagerDelegate?
    private let databaseRef = FIRDatabase.database().reference()
    
    var currentUserIsSignedIn: Bool {
        return FIRAuth.auth()?.currentUser != nil
    }
    
    private var currentUserIsSignedOut: Bool {
        return FIRAuth.auth()?.currentUser == nil
    }
    
    private var authStateListener: FIRAuthStateDidChangeListenerHandle!
    
    private init() {}
    
    func listenForAuthStateChanges() {
        authStateListener = FIRAuth.auth()?.addStateDidChangeListener(authStateChangedHandler)
    }
    
    func stopListeningForAuthStateChanges() {
        FIRAuth.auth()?.removeStateDidChangeListener(authStateListener)
    }
    
    private func authStateChangedHandler(auth: FIRAuth, user: FIRUser?) -> Swift.Void {
        if currentUserIsSignedOut {
            delegate?.currentUserDidSignOut()
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
                                           "uuid": user.uuid.uuidString], withCompletionBlock: { (error, ref) in
                                            if let error = error {
                                                completion(.Failure(error))
                                            } else {
                                                UserManager.shared.currentUserUsername = user.username
                                                UserManager.shared.currentUserPassword = user.password
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
                                    self?.databaseRef.child("users")
                                        .child(username.lowercased()).updateChildValues(["uuid": UUID().uuidString])
                                    // TODO: Get entire profile and set user.
                                    UserManager.shared.currentUserUsername = username
                                    UserManager.shared.currentUserPassword = password
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
    
    func searchForUserWithUsername(_ username: String, completion: @escaping (Result<User?>) -> Void) {
        databaseRef.child("users").child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            if let value = snapshot.value as? NSDictionary {
                let displayName = value["display-name"] as? String ?? ""
                let email = value["email"] as? String ?? ""
                let phoneNumber = value["phone-number"] as? String ?? ""
                let user = User(username: displayName, email: email, phoneNumber: phoneNumber, password: "")
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
                    UserManager.shared.contacts.append(user)
                }
            }
            completion(.Success)
        }) { (error) in
            completion(.Failure(error))
        }
    }
}
