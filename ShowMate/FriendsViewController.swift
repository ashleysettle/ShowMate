import UIKit
import FirebaseAuth
import FirebaseFirestore

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

class UserTableViewCell: UITableViewCell {
    @IBOutlet weak var followButton: UIButton!
    @IBOutlet weak var searchResultUserLabel: UILabel!
    var onFollowButtonTapped: (() -> Void)?
    
    @IBAction func followButtonTapped(_ sender: UIButton) {
        onFollowButtonTapped?()
    }
    
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

class currentFriendsTableViewCell: UITableViewCell{
    @IBOutlet weak var friendUserName: UILabel!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Add some padding if needed
        let padding: CGFloat = 8
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: padding, left: 0, bottom: padding, right: 0))
    }
}

class FriendsViewController: UIViewController {
    // MARK: - UI Components
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var currentFriendsTable: UITableView!
    
    
    let searchUserCellID = "userCell"
    let currentFriendsID = "currentFriendsCellId"
    var resultsFromSearch = [UserProfile]()
    var currentFriendsList = [UserProfile]()
    private var searchResultsStackView: UIStackView!
    private var friendsStackView: UIStackView!
    private var friendsManager: FriendsManager?
    
    private var friendsListener: ListenerRegistration?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
               
           resultsTable.dataSource = self
           resultsTable.delegate = self
           currentFriendsTable.dataSource = self
           currentFriendsTable.delegate = self
           
           setupUI()
           updateDisplayName()
        setupTableViews()
           
           if let currentUserId = Auth.auth().currentUser?.uid {
               friendsManager = FriendsManager(userId: currentUserId)
               setupFriendsListener() // Set up real-time listener
           }
           
           // Debug frames
           print("Results table frame: \(resultsTable.frame)")
           print("Current friends table frame: \(currentFriendsTable.frame)")
    }
    
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Print frames for debugging
        print("Results Table Frame: \(resultsTable.frame)")
        print("Current Friends Table Frame: \(currentFriendsTable.frame)")
        print("Results Table Content Size: \(resultsTable.contentSize)")
        print("Current Friends Table Content Size: \(currentFriendsTable.contentSize)")
    }
    
    // Add this delegate method to ensure proper cell layout
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60 // Or whatever height you want for the cells
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
        // Remove loadFriends() here as we're using real-time listener
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
    
    private func setupUI() {
        setupSearchBar()
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Search users..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
    }
    
    // MARK: - Search and Display Methods
    private func performSearch(with searchText: String) {
        guard let friendsManager = friendsManager else { return }
        
        Task {
            do {
                let users = try await friendsManager.searchUsers(by: searchText)
                await MainActor.run {
                    self.resultsFromSearch = users
                    print("results : \(self.resultsFromSearch)")
                    self.resultsTable.reloadData()
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    self.clearSearchResults()
                }
            }
        }
        print("Table frame:", resultsTable.frame)
        resultsTable.reloadData()
    }
    
    private func clearSearchResults() {
        resultsFromSearch.removeAll()
        resultsTable.reloadData()
    }
    
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
    
    private func loadFriends() {
        guard let currentUserID = Auth.auth().currentUser?.uid else { return }
           let db = Firestore.firestore()
           
           db.collection("users").document(currentUserID).getDocument { (document, error) in
               if let document = document, document.exists {
                   if let friendIDs = document.get("friend_ids") as? [String] {
                       Task {
                           await self.fetchFriendsProfiles(friendIDs) // Call the async function with await
                       }
                   }
               } else {
                   print("User document not found or error occurred: \(error?.localizedDescription ?? "No error description")")
               }
           }
    }
    
    func fetchFriendsProfiles(_ friendIDs: [String]) async {
        print("Starting to fetch profiles for friends: \(friendIDs)")
        let db = Firestore.firestore()
        var friends = [UserProfile]()
        
        for friendID in friendIDs {
            do {
                let document = try await db.collection("users").document(friendID).getDocument()
                print("Fetched document for friendID: \(friendID)")
                
                if document.exists {
                    if let friendProfile = try? document.data(as: UserProfile.self) {
                        friends.append(friendProfile)
                        print("Successfully decoded profile for: \(friendProfile.username)")
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
        
        print("Finished fetching all profiles, found \(friends.count) friends")
        
        await MainActor.run {
            self.currentFriendsList = friends
            self.currentFriendsTable.reloadData()
            print("Updated UI with \(self.currentFriendsList.count) friends")
        }
    }
    
    /*private func handleFriendAction(for user: UserProfile) {
     guard let friendsManager = friendsManager else { return }
     
     if user.friendIds.contains(friendsManager.userId) {
     // Already friends, so remove friend
     removeFriend(user)
     } else if user.friendRequestIds.contains(friendsManager.userId) {
     // Friend request sent, so cancel the request
     cancelFriendRequest(user)
     } else if user.isPublic {
     // Public account, send friend request automatically
     sendFriendRequest(user)
     } else {
     // Private account, send friend request to wait for approval
     sendFriendRequest(user)
     }
     }*/
    
    @objc private func sendFriendRequest(_ sender: UIButton) {
        // TODO: Implement send friend request
    }
    
    @objc private func removeFriend(_ sender: UIButton) {
        // TODO: Implement remove friend
    }
    
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    func addFriendButtonTapped(user: UserProfile, button: UIButton) {
        guard let friendsManager = friendsManager else { return }
        
        button.isEnabled = false
        
        Task {
            do {
                print("Starting to add friend with ID: \(user.uid)")
                try await friendsManager.addFriend(friendId: user.uid)
                
                await MainActor.run {
                    button.setTitle("Added", for: .normal)
                    print("Successfully added friend, listener should update automatically")
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



// MARK: - UISearchBarDelegate
extension FriendsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        performSearch(with: searchText)
    }
}

extension FriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = tableView == resultsTable ? resultsFromSearch.count : currentFriendsList.count
        print("\(tableView == resultsTable ? "Results" : "Friends") table showing \(count) rows")
        return count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: currentFriendsID, for: indexPath) as! currentFriendsTableViewCell
            let friend = currentFriendsList[indexPath.row]
            cell.friendUserName.text = friend.username
            print("Configuring friends cell with username: \(friend.username)")
            return cell
        }
    }
}

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == resultsTable {
            let user = resultsFromSearch[indexPath.row]
        } else {
            let friend = currentFriendsList[indexPath.row]
        }
    }
}
