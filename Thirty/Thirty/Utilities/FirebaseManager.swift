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
        FIRAuth.auth()?.createUser(withEmail: user.email, password: user.password) { (fbUser, error) in
            if let error = error {
                completion(.Failure(error))
            } else {
                FIRAuth.auth()?.signIn(withEmail: user.email, password: user.password, completion: { (fbUser, error) in
                    if let error = error {
                        completion(.Failure(error))
                    } else {
                        if let fbUser = fbUser {
                            self.databaseRef.child("users")
                                .child(fbUser.uid).setValue(["phone-number": user.phoneNumber, "username": user.username, "email": user.email], withCompletionBlock: { (error, ref) in
                                    if let error = error {
                                        completion(.Failure(error))
                                    } else {
                                        completion(.Success())
                                    }
                                })
                        } else {
                            completion(.Failure(_))
                        }
                    }
                })
            }
        }
    }
    
//    func put(photoData: Data, completion: @escaping (Result<Void>) -> Void) {
//        guard let userID = FIRAuth.auth()?.currentUser?.uid else { return }
//        let fileName = databaseRef.child("users").child(userID).child("images").childByAutoId().key
//        
//        let storageRef = storage.reference(forURL: "gs://insecurity-40a93.appspot.com")
//        let imagesRef = storageRef.child("images/\(userID)")
//        
//        let fileRef = imagesRef.child(fileName)
//        
//        let metadata = FIRStorageMetadata()
//        metadata.contentType = "image/jpeg"
//        
//        _ = fileRef.put(photoData, metadata: metadata) { [weak self] metadata, error in
//            if let error = error {
//                completion(.Failure(error))
//            } else {
//                let downloadURLString = metadata!.downloadURL()!.absoluteString
//                self?.databaseRef.child("users")
//                    .child(userID)
//                    .child("images")
//                    .child(fileName)
//                    .setValue(["downloadURL" : downloadURLString, "date" : NSDate().timeIntervalSince1970], withCompletionBlock: {  error, ref in
//                        if let error = error {
//                            completion(.Failure(error))
//                        } else {
//                            completion(.Success())
//                        }
//                    })
//            }
//        }
//    }
//    
//    func getPhoto(url: URL, completion: @escaping (Result<UIImage>) -> Void) {
//        let httpsReference = storage.reference(forURL: url.absoluteString)
//        httpsReference.data(withMaxSize: 1 * 1024 * 1024) { (data, error) in
//            if error != nil {
//                completion(.Failure(error!))
//            } else if let data = data, let image = UIImage(data: data) {
//                completion(.Success(image))
//            }
//        }
//    }
//    
//    func deleteImage(imageData: FBImageData, completion: @escaping (Result<Void>) -> Void) {
//        guard let userID = FIRAuth.auth()?.currentUser?.uid else { return }
//        let httpsReference = storage.reference(forURL: imageData.url.absoluteString)
//        httpsReference.delete { [weak self] error in
//            if let error = error {
//                completion(.Failure(error))
//            } else {
//                self?.databaseRef.child("users")
//                    .child(userID)
//                    .child("images")
//                    .child(imageData.databaseKey).removeValue { error, ref in
//                        if let error = error {
//                            completion(.Failure(error))
//                        } else {
//                            ImageLoader.sharedInstance.removeImageData(imageDataToRemove: imageData)
//                            completion(.Success())
//                        }
//                }
//            }
//        }
//    }
//    
//    
//    func getCurrentUserImageURLs(completion: @escaping (Result<[FBImageData]?>) -> Void) {
//        guard let userID = FIRAuth.auth()?.currentUser?.uid else { return }
//        var imageObjects = [FBImageData]()
//        databaseRef.child("users").child(userID).child("images").observeSingleEvent(of: .value, with: { (snapshot) in
//            guard snapshot.exists() else {
//                completion(.Success(nil))
//                return
//            }
//            let allValues = snapshot.value as! NSDictionary
//            for (key, value) in allValues {
//                let valueDictionary = value as! NSDictionary
//                let urlString = valueDictionary["downloadURL"] as? String ?? ""
//                let dateDouble = valueDictionary["date"] as? Double ?? 0
//                
//                let url = URL(string: urlString)
//                let date = Date(timeIntervalSince1970: TimeInterval(dateDouble))
//                let imageObject = FBImageData(url: url, databaseKey: key as! String, date: date, image: nil)
//                imageObjects.append(imageObject)
//            }
//            completion(.Success(imageObjects))
//        }) { (error) in
//            completion(.Failure(error))
//        }
//    }
}

struct FBImageData {
    var url: URL!
    var databaseKey = ""
    var date = Date()
    var image: UIImage?
}

