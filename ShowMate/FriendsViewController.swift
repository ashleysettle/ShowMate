import UIKit
import FirebaseAuth
import FirebaseFirestore

struct UserProfile : Codable {
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
    
}

class currentFriendsTableViewCell: UITableViewCell{
    @IBOutlet weak var friendUserName: UILabel!
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
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        resultsTable.dataSource = self
        resultsTable.delegate = self
        currentFriendsTable.dataSource = self
        currentFriendsTable.delegate = self
        super.viewDidLoad()
        loadFriends()
        resultsTable.frame = CGRect(x: 0, y: 263, width: view.frame.width, height: 400)
        currentFriendsTable.frame = CGRect(x: 0, y: 263, width: view.frame.width, height: 400)
        setupUI()
        updateDisplayName()
        
        if let currentUserId = Auth.auth().currentUser?.uid {
            friendsManager = FriendsManager(userId: currentUserId)
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
            if let userId = user?.uid {
                self?.friendsManager = FriendsManager(userId: userId)
                self?.loadFriends()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
        loadFriends()
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
        let db = Firestore.firestore()
            var friends = [UserProfile]()
            
            for friendID in friendIDs {
                do {
                    let document = try await db.collection("users").document(friendID).getDocument()
                    if let friendProfile = try? document.data(as: UserProfile.self) {
                        friends.append(friendProfile)
                    }
                } catch {
                    print("Error fetching friend profile: \(error)")
                }
            }
            print("grabbing current friends: \(friends)")
            await MainActor.run {
                self.currentFriendsList = friends
                self.currentFriendsTable.reloadData() // Reload the table displaying friends
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
        Task{
            do{
                try await friendsManager?.addFriend(friendId: user.uid)
                await MainActor.run {
                    button.setTitle("Added", for: .normal)
                    button.isEnabled = false
                    self.loadFriends()
                }
            } catch {
                print("Error")
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
        if tableView == resultsTable {
            return resultsFromSearch.count // Number of search results
        } else {
            return currentFriendsList.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            if tableView == resultsTable {
                let cell = tableView.dequeueReusableCell(withIdentifier: searchUserCellID, for: indexPath) as! UserTableViewCell
                let user = resultsFromSearch[indexPath.row]
                cell.searchResultUserLabel.text = user.username
                cell.followButton.setTitle(user.isPublic ? "Follow" : "Request", for: .normal)
                cell.onFollowButtonTapped = { [weak self] in
                    self?.addFriendButtonTapped(user: user, button: cell.followButton)
                }
                return cell
            } else if tableView == currentFriendsTable {
                let cell = tableView.dequeueReusableCell(withIdentifier: currentFriendsID, for: indexPath) as! currentFriendsTableViewCell
                let friend = currentFriendsList[indexPath.row]
                cell.friendUserName.text = friend.username
                return cell
            }
            return UITableViewCell()
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
