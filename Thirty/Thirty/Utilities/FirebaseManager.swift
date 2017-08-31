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
            completion(.Success())
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
                                .child(user.username)
                                .setValue(["phone-number": user.phoneNumber,
                                           "uid": fbUser.uid,
                                           "email": user.email], withCompletionBlock: { (error, ref) in
                                            if let error = error {
                                                completion(.Failure(error))
                                            } else {
                                                completion(.Success())
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
                                    completion(.Success())
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
    
    func searchForUserWithUsername(_ username: String, completion: @escaping (Result<String>) -> Void) {
        databaseRef.child("users").child(username.lowercased()).observeSingleEvent(of: .value, with: { snapshot in
            // Get user value
            let value = snapshot.value as? NSDictionary
            let email = value?["email"] as? String ?? ""
            completion(.Success("BLAHBLAH"))
        }) { (error) in
            completion(.Failure(error))
        }
    }
}
