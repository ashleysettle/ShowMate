import UIKit
import FirebaseAuth
import FirebaseFirestore

// Struct containing the attributes of a user
struct UserProfile: Codable {
    let uid: String
    let username: String
    let isPublic: Bool
    var friendIds: [String]
    var friendRequestIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case uid
        case username
        case isPublic = "is_public"
        case friendIds = "friend_ids"
        case friendRequestIds = "friend_request_ids"
    }
}

// Custom table view cell for user search results
class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var searchResultUserLabel: UILabel!
    var onFollowButtonTapped: (() -> Void)?
    
    // Function when the follow button has been pressed
    @IBAction func followButtonTapped(_ sender: UIButton) {
        onFollowButtonTapped?()
    }
    
    // Formatting for the cell
    override func layoutSubviews() {
        super.layoutSubviews()
        
        searchResultUserLabel.lineBreakMode = .byTruncatingTail
        followButton.setContentHuggingPriority(.required, for: .horizontal)
        followButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        searchResultUserLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        searchResultUserLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        // Add some padding if needed
        let padding: CGFloat = 8
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0))
    }
}

// Custom table view cell for the current friends of the user
class currentFriendsTableViewCell: UITableViewCell{
    @IBOutlet weak var friendUserName: UILabel!
    @IBOutlet weak var unfollowButton: UIButton!
    
    var unfollowAction: (() -> Void)?
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
        unfollowAction?()
    }
    
    // Formatting for the cell
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add some padding if needed
        let padding: CGFloat = 8
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0))
    }
}

class FriendsViewController: UIViewController {
    // Labels and buttons from UI
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var currentFriendsTable: UITableView!
    
    // Cell ID and list to populate user search results table
    let searchUserCellID = "userCell"
    var resultsFromSearch = [UserProfile]()
    // Cell ID and list to populate current friends table
    let currentFriendsID = "currentFriendsCellId"
    var currentFriendsList = [UserProfile]()
    private var friendsManager: FriendsManager?
    private var friendsListener: ListenerRegistration?
    // Profile segue identifier
    let profileSegue = "profileSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Table set up for user results and current friends
        resultsTable.dataSource = self
        resultsTable.delegate = self
        currentFriendsTable.dataSource = self
        currentFriendsTable.delegate = self
        
        // UI set up
        setupUI()
        updateDisplayName()
        setupTableViews()
        
        searchBar.autocapitalizationType = .none
        searchBar.showsCancelButton = true
           
        if let currentUserId = Auth.auth().currentUser?.uid {
            friendsManager = FriendsManager(userId: currentUserId)
            // Set up real-time listener
            setupFriendsListener()
        }
    }
    
    // Function to set up the tables visually
    private func setupTableViews() {
        // Remove frame setting and use constraints instead
        resultsTable.translatesAutoresizingMaskIntoConstraints = false
        currentFriendsTable.translatesAutoresizingMaskIntoConstraints = false
        
        // Clear any existing constraints
        resultsTable.removeFromSuperview()
        currentFriendsTable.removeFromSuperview()
        
        // Add tables back to view
        view.addSubview(resultsTable)
        view.addSubview(currentFriendsTable)
        
        // Setup constraints
           NSLayoutConstraint.activate([
               // Results table
               resultsTable.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
               resultsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
               resultsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
               resultsTable.heightAnchor.constraint(equalToConstant: 150), // Shorter height for search results
               
               // Friends table
               currentFriendsTable.topAnchor.constraint(equalTo: resultsTable.bottomAnchor, constant: 40),
               currentFriendsTable.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
               currentFriendsTable.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
               currentFriendsTable.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
           ])
        // Configure table views
        resultsTable.backgroundColor = .clear
        currentFriendsTable.backgroundColor = .clear
        
        // Make sure the tables can scroll
        resultsTable.isScrollEnabled = true
        currentFriendsTable.isScrollEnabled = true
        
        // Register for automatic row height
        resultsTable.rowHeight = UITableView.automaticDimension
        resultsTable.estimatedRowHeight = 44
        currentFriendsTable.rowHeight = UITableView.automaticDimension
        currentFriendsTable.estimatedRowHeight = 44
    }
    
    // Helper function to help set up UI
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    // Helper method to ensure table is at correct height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
    }
    
    private func setupFriendsListener() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Remove existing listener if any
        friendsListener?.remove()
        
        // Setup real-time listener
        friendsListener = db.collection("users").document(currentUserID)
            .addSnapshotListener { [weak self] (documentSnapshot, error) in
                guard let self = self else { return }
                
                if let error = error {
                    print("Error listening for friend updates: \(error)")
                    return
                }
                
                guard let document = documentSnapshot, document.exists else {
                    print("User document doesn't exist")
                    return
                }
                
                // Debug print to see what we're getting from Firestore
                print("Received document update: \(document.data() ?? [:])")
                
                if let friendIDs = document.get("friend_ids") as? [String] {
                    print("Found friend IDs: \(friendIDs)")
                    Task {
                        await self.fetchFriendsProfiles(friendIDs)
                    }
                } else {
                    print("No friend_ids field found in document")
                    Task {
                        await MainActor.run {
                            self.currentFriendsList = []
                            self.currentFriendsTable.reloadData()
                        }
                    }
                }
            }
    }
    
    // Helper function that sets up UI
    private func setupUI() {
        setupSearchBar()
    }
    
    // Helper function that sets up UI
    private func setupSearchBar() {
        searchBar.placeholder = "Search users..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
    }
    
    // Method that searches for user
    private func performSearch(with searchText: String) {
        guard let friendsManager = friendsManager else { return }
        
        // Searches for user
        Task {
            do {
                let users = try await friendsManager.searchUsers(by: searchText)
                await MainActor.run {
                    self.resultsFromSearch = users
                    self.resultsTable.reloadData()
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    self.clearSearchResults()
                }
            }
        }
        resultsTable.reloadData()
    }
    
    // Clears search results
    private func clearSearchResults() {
        resultsFromSearch.removeAll()
        resultsTable.reloadData()
    }
    
    // Displays search results and reloads the table
    private func displaySearchResults(_ users: [UserProfile]) {
        clearSearchResults()
        self.resultsFromSearch = users
        
        if users.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No users found"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .gray
            resultsTable.tableFooterView = emptyLabel
        } else {
            resultsTable.tableFooterView = nil
        }
        resultsTable.reloadData()
    }
    
    // Function that loads the current friends of the user
    private func loadFriends() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
           let db = Firestore.firestore()
           
            // Uses user id to fetch current friends from database
           db.collection("users").document(currentUserID).getDocument { (document, error) in
               if let document = document, document.exists {
                   if let friendIDs = document.get("friend_ids") as? [String] {
                       Task {
                           await self.fetchFriendsProfiles(friendIDs)
                       }
                   }
               } else {
                   print("User document not found or error occurred: \(error?.localizedDescription ?? "No error description")")
               }
           }
    }
    
    private func unfollowAction(friendID: String) {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
        let ref = Firestore.firestore().collection("users").document(currentUserID)
        
        // Update the `friend_ids` field by removing the friend ID
        ref.updateData([
            "friend_ids": FieldValue.arrayRemove([friendID])
        ]) { error in
            if let error = error {
                print("Error unfollowing friend: \(error)")
                return
            }
            
            // Update local list and refresh UI
            self.currentFriendsList = self.currentFriendsList.filter { $0.uid != friendID }

            self.currentFriendsTable.reloadData()
            
        }
    }
    
    // Helper function for loading current friends of the userr
    func fetchFriendsProfiles(_ friendIDs: [String]) async {
        let db = Firestore.firestore()
        var friends = [UserProfile]()
        
        // Retrieves each friend in friend list of user
        for friendID in friendIDs {
            do {
                let document = try await db.collection("users").document(friendID).getDocument()
                
                if document.exists {
                    if let friendProfile = try? document.data(as: UserProfile.self) {
                        friends.append(friendProfile)
                    } else {
                        print("Failed to decode profile for friendID: \(friendID)")
                    }
                } else {
                    print("No document exists for friendID: \(friendID)")
                }
            } catch {
                print("Error fetching friend profile for \(friendID): \(error)")
            }
        }
        
        // Reloads the table
        await MainActor.run {
            self.currentFriendsList = friends
            self.currentFriendsTable.reloadData()
        }
    }

    
    // Updates the display name in the corner of the screen
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    // Adds friend when follow button is pressed
    func addFriendButtonTapped(user: UserProfile, button: UIButton) {
        guard let friendsManager = friendsManager else { return }
        
        // Changes whether the user has already been followed
        button.isEnabled = false
        
        Task {
            do {
                // Adds friend with user id from search result
                try await friendsManager.addFriend(friendId: user.uid)
                
                // Changes the button when friend is added
                await MainActor.run {
                    button.setTitle("Added", for: .normal)
                }
            } catch {
                print("Error adding friend: \(error)")
                await MainActor.run {
                    button.setTitle(user.isPublic ? "Follow" : "Request", for: .normal)
                    button.isEnabled = true
                }
            }
        }
    }
}

// Search Bar
extension FriendsViewController: UISearchBarDelegate {
    // Function for when the search bar is clicked, uses performSearch helper method
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        performSearch(with: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        searchBar.text = "" // Clear the text in the search bar
        clearSearchResults()
    }
}

// Functions needed for the search result and current friend tables
extension FriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = tableView == resultsTable ? resultsFromSearch.count : currentFriendsList.count
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Search result table
        if tableView == resultsTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: searchUserCellID, for: indexPath) as! UserTableViewCell
            let user = resultsFromSearch[indexPath.row]
            
            cell.searchResultUserLabel.text = user.username
            
            // Check if user is already in friends list
            let isAlreadyFriend = currentFriendsList.contains(where: { $0.uid == user.uid })
            cell.followButton.setTitle(isAlreadyFriend ? "Added" : (user.isPublic ? "Follow" : "Request"), for: .normal)
            cell.followButton.isEnabled = !isAlreadyFriend
            
            cell.onFollowButtonTapped = { [weak self] in
                self?.addFriendButtonTapped(user: user, button: cell.followButton)
            }
            return cell
        // Current Friend Table
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: currentFriendsID, for: indexPath) as! currentFriendsTableViewCell
            let friend = currentFriendsList[indexPath.row]
            cell.friendUserName.text = friend.username
            cell.unfollowAction = { [weak self] in
                        self?.unfollowAction(friendID: friend.uid)
                    }
            return cell
        }
    }
}

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        var user:UserProfile
        // Search result table
        if tableView == resultsTable {
            user = resultsFromSearch[indexPath.row]
        // Current friend table
        } else {
            user = currentFriendsList[indexPath.row]
        }
        self.performSegue(withIdentifier: profileSegue, sender: user)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == profileSegue,
           let nextVC = segue.destination as? ProfileViewController {
            nextVC.user = sender as? UserProfile
        }
    }
}
