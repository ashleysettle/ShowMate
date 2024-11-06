//
//  FriendsManager.swift
//  ShowMate
//
//  Created by Ashley Settle on 11/6/24.
//
import FirebaseAuth
import FirebaseFirestore

class FriendsManager {
    private let db = Firestore.firestore()
    private let currentUserId: String
    
    init(userId: String) {
        self.currentUserId = userId
    }
    
    // MARK: - Profile Management
    func updatePrivacySettings(isPublic: Bool) async throws {
        try await db.collection("users").document(currentUserId).updateData([
            "is_public": isPublic
        ])
    }
    
    // MARK: - Friend Operations
    func sendFriendRequest(to userId: String) async throws {
        // Verify target user exists and is public or already friends
        let targetUser = try await db.collection("users").document(userId).getDocument()
        guard let userData = targetUser.data(),
              (userData["is_public"] as? Bool == true ||
               (userData["friend_ids"] as? [String])?.contains(currentUserId) == true) else {
            throw NSError(domain: "FriendsManager", code: 403, userInfo: [
                NSLocalizedDescriptionKey: "User is private or not found"
            ])
        }
        
        // Add to pending requests
        try await db.collection("users").document(userId).updateData([
            "friend_request_ids": FieldValue.arrayUnion([currentUserId])
        ])
    }
    
    func acceptFriendRequest(from userId: String) async throws {
        let batch = db.batch()
        
        // Add each user to the other's friend list
        let currentUserRef = db.collection("users").document(currentUserId)
        let otherUserRef = db.collection("users").document(userId)
        
        batch.updateData([
            "friend_ids": FieldValue.arrayUnion([userId]),
            "friend_request_ids": FieldValue.arrayRemove([userId])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "friend_ids": FieldValue.arrayUnion([currentUserId])
        ], forDocument: otherUserRef)
        
        try await batch.commit()
    }
    
    func removeFriend(userId: String) async throws {
        let batch = db.batch()
        
        // Remove each user from the other's friend list
        let currentUserRef = db.collection("users").document(currentUserId)
        let otherUserRef = db.collection("users").document(userId)
        
        batch.updateData([
            "friend_ids": FieldValue.arrayRemove([userId])
        ], forDocument: currentUserRef)
        
        batch.updateData([
            "friend_ids": FieldValue.arrayRemove([currentUserId])
        ], forDocument: otherUserRef)
        
        try await batch.commit()
    }
    
    // MARK: - User Discovery
    func searchUsers(by username: String, limit: Int = 20) async throws -> [UserProfile] {
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: username)
            .whereField("username", isLessThan: username + "z")
            .limit(to: limit)
            .getDocuments()
        
        return try snapshot.documents.compactMap { document -> UserProfile? in
            let data = document.data()
            guard let isPublic = data["is_public"] as? Bool else { return nil }
            
            // Only return public profiles or friends
            if !isPublic {
                guard let friendIds = data["friend_ids"] as? [String],
                      friendIds.contains(currentUserId) else {
                    return nil
                }
            }
            
            return try document.data(as: UserProfile.self)
        }
    }
    
    // MARK: - Friend List
    func getFriends() async throws -> [UserProfile] {
        let currentUser = try await db.collection("users").document(currentUserId).getDocument()
        guard let friendIds = try currentUser.data()?["friend_ids"] as? [String] else {
            return []
        }
        
        if friendIds.isEmpty { return [] }
        
        // Fetch all friend profiles
        let chunks = friendIds.chunked(into: 10) // Firestore limits to 10 items in whereField(in:)
        var allFriends: [UserProfile] = []
        
        for chunk in chunks {
            let snapshot = try await db.collection("users")
                .whereField("uid", in: chunk)
                .getDocuments()
            
            let friends = try snapshot.documents.compactMap { try $0.data(as: UserProfile.self) }
            allFriends.append(contentsOf: friends)
        }
        
        return allFriends
    }
}
// MARK: - Helper Extensions
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
