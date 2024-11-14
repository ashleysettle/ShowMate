import FirebaseAuth
import FirebaseFirestore

class UserManager {
    private let db = Firestore.firestore()
    
    // Function to register the user with the Firebase
    func registerUser(email: String, password: String, username: String) async throws {
        do {
            // Create user with Firebase Authentication
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Set the userId
            let userId = authResult.user.uid
            
            // Add user details to Firestore database
            try await addUserToFirestore(userId: userId, username: username)
        } catch {
            print("Error during user registration: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Function to add attributes to user in database
    func addUserToFirestore(userId: String, username: String) async throws {
        // Attributes in the Firebase database
        let userData: [String: Any] = [
            "uid": userId,
            "username": username,
            "is_public": true,
            "friend_ids": [],
            "friend_request_ids": []
        ]
        
        // Sets the users data based on default values
        do {
            try await db.collection("users").document(userId).setData(userData)
            print("User added to Firestore with ID: \(userId) and data: \(userData)")
        } catch {
            print("Error adding user to Firestore: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Checks that all user data is set
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
