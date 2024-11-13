import FirebaseAuth
import FirebaseFirestore

class UserManager {
    private let db = Firestore.firestore()
    
    // MARK: - User Registration with Firestore Addition
    func registerUser(email: String, password: String, username: String) async throws {
        do {
            // Create user with Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let userId = authResult.user.uid // No need to cast to String, uid is already a String
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
        let userData: [String: Any] = [
            "uid": userId,
            "username": username,
            "is_public": true,  // Changed from isPublic to is_public
            "friend_ids": [],
            "friend_request_ids": []
        ]
        
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("User added to Firestore with ID: \(userId) and data: \(userData)")
        } catch {
            print("Error adding user to Firestore: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Helper function to verify user data
    func verifyUserData(userId: String) async throws -> Bool {
        do {
            let document = try await db.collection("users").document(userId).getDocument()
            
            guard let data = document.data() else {
                print("No data found for user \(userId)")
                return false
            }
            
            // Verify all required fields exist
            let requiredFields = ["uid", "username", "is_public", "friend_ids", "friend_request_ids"]
            let missingFields = requiredFields.filter { data[$0] == nil }
            
            if !missingFields.isEmpty {
                print("Missing required fields for user \(userId): \(missingFields)")
                return false
            }
            
            // Verify uid matches document ID
            guard let storedUid = data["uid"] as? String, storedUid == userId else {
                print("UID mismatch for user \(userId)")
                return false
            }
            
            return true
        } catch {
            print("Error verifying user data: \(error.localizedDescription)")
            throw error
        }
    }
}
