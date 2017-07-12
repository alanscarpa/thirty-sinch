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
        // STEP 1 - First we make sure the username is available
        databaseRef.child("users").child(user.username).observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(.Failure(THError(errorType: .usernameAlreadyExists)))
            } else {
                // STEP 2 - First we create our user
                FIRAuth.auth()?.createUser(withEmail: user.email, password: user.password) { (fbUser, error) in
                    if let error = error {
                        completion(.Failure(error))
                    } else {
                        // STEP 3 - Then we add details to user which allows a username sign-in
                        if let fbUser = fbUser {
                            self.databaseRef.child("users")
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
                }
            }
        }) { (error) in
            completion(.Failure(error))
        }
        
    }
    
    func logInUserWithUsername(_ username: String, password: String, completion: @escaping (Result<Void>) -> Void) {
        databaseRef.child("users").child(username).observeSingleEvent(of: .value, with: { snapshot in
            guard snapshot.exists() else {
                completion(.Failure(THError(errorType: .usernameDoesNotExist)))
                return
            }
            let value = snapshot.value as? NSDictionary
            if let email = value?["email"] as? String {
                FIRAuth.auth()?.signIn(withEmail: email, password: password) { (user, error) in
                    // ...
                }
                completion(.Success())
            }
        }) { (error) in
            completion(.Failure(error))
        }
    }
}
