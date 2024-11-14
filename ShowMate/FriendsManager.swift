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
    // Identifier for users
    private let currentUserId: String
    
    init(userId: String) {
        self.currentUserId = userId
    }
    
    // Function that connects to Firebase to add friend
    func addFriend(friendId: String) async throws {
        // Reference to the current user's document
        let userRef = db.collection("users").document(currentUserId)
        
        // Use arrayUnion to add the friend ID to friend_ids
        try await userRef.updateData([
            "friend_ids": FieldValue.arrayUnion([friendId])
        ])
    }
    
    // Uses inputted username to search for users in the database
    func searchUsers(by username: String, limit: Int = 20) async throws -> [UserProfile] {
        let snapshot = try await db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: username)
            .whereField("username", isLessThan: username + "z")
            .limit(to: limit)
            .getDocuments()
        
        // Checks if the user is public
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
    
    // Returns the list of friends the user currently has
    func getFriends() async throws -> [UserProfile] {
        let currentUser = try await db.collection("users").document(currentUserId).getDocument()
        guard let friendIds = try currentUser.data()?["friend_ids"] as? [String] else {
            return []
        }
        
        if friendIds.isEmpty { return [] }
        
        // Fetch all friend profiles
        // Firestore limits to 10 items
        let chunks = friendIds.chunked(into: 10)
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
// Helper function to create an array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
