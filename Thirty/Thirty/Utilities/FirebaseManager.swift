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
        // STEP 1 - First we create our user
        FIRAuth.auth()?.createUser(withEmail: user.email, password: user.password) { (fbUser, error) in
            if let error = error {
                completion(.Failure(error))
            } else {
                // STEP 2 - Then we add details to user which allows a username sign-in
                if let fbUser = fbUser {
                    self.databaseRef.child("users")
                        .child(fbUser.uid)
                        .setValue(["phone-number": user.phoneNumber,
                                   "username": user.username,
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
}
