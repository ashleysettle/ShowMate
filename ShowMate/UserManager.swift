//
//  UserManager.swift
//  ShowMate
//
//  Created by Your Name on 11/8/24.
//

import FirebaseAuth
import FirebaseFirestore

class UserManager {
    private let db = Firestore.firestore()
    
    // MARK: - User Registration with Firestore Addition
    
    func registerUser(email: String, password: String, username: String) async throws {
        do {
            // Create user with Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            guard let userId = authResult.user.uid as? String else {
                print("Error: Could not retrieve user ID")
                return
            }
            
            print("User registered with ID: \(userId)")
            
            // Add user details to Firestore
            try await addUserToFirestore(userId: userId, username: username)
            print("User successfully added to Firestore")
            
        } catch {
            print("Error during user registration: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Add User to Firestore
    
    func addUserToFirestore(userId: String, username: String) async throws {
        let userData = [
            "username": username,
            "isPrivate": true,  // or false, based on app's privacy setting
            "friend_ids": [String]()  // Initialize as empty array
        ] as [String : Any]
        
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("User added to Firestore with ID: \(userId)")
        } catch {
            print("Error adding user to Firestore: \(error.localizedDescription)")
            throw error
        }
    }
    
}
