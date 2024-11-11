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


class FriendsViewController: UIViewController {
    // MARK: - UI Components
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var resultsTable: UITableView!
    @IBOutlet weak var currentFriendsTable: UITableView!
    
    let searchUserCellID = "userCell"
    var resultsFromSearch = [UserProfile]()
    private var searchResultsStackView: UIStackView!
    private var friendsStackView: UIStackView!
    private var friendsManager: FriendsManager?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        resultsTable.dataSource = self
        resultsTable.delegate = self
        super.viewDidLoad()
        resultsTable.register(UITableViewCell.self, forCellReuseIdentifier: searchUserCellID)
        resultsTable.frame = CGRect(x: 0, y: 263, width: view.frame.width, height: 400)
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
        setupSubmitButton()
    }
    
    private func setupSearchBar() {
        searchBar.placeholder = "Search users..."
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
    }
    
    private func setupSubmitButton() {
        submitButton.setTitle("Search", for: .normal)
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.layer.cornerRadius = 8
        submitButton.addTarget(self, action: #selector(submitButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    @objc private func submitButtonTapped() {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        performSearch(with: searchText)
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
        guard let friendsManager = friendsManager else { return }
        
        Task {
            do {
                let friends = try await friendsManager.getFriends()
                await MainActor.run {
                    self.displayFriends(friends)
                }
            } catch {
                print("Error loading friends: \(error)")
            }
        }
    }
    
    private func displayFriends(_ friends: [UserProfile]) {
        /*friendsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if friends.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No friends yet"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .gray
            friendsStackView.addArrangedSubview(emptyLabel)
        } else {
            friends.forEach { friend in
                let friendView = createUserView(for: friend, isSearchResult: false)
                friendsStackView.addArrangedSubview(friendView)
            }
        }*/
    }
    
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
}

// MARK: - UISearchBarDelegate
extension FriendsViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        submitButtonTapped()
    }
}

extension FriendsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("num rows: \(resultsFromSearch.count)")
        return resultsFromSearch.count // Number of search results
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: searchUserCellID, for: indexPath)
        
        // Configure the cell
        let user = resultsFromSearch[indexPath.row]
        let usernameOnly = user.username
        print("only username: \(usernameOnly)")
        cell.textLabel?.text = user.username
        print("username: \(String(describing: user.username))")
        // Optionally, configure other properties (like image or friend status) if needed
        return cell
    }
}

extension FriendsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = resultsFromSearch[indexPath.row]
        // Handle the tap, e.g., show more info or send a friend request
    }
}
