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
    @IBOutlet weak var searchResultsScrollView: UIScrollView!
    @IBOutlet weak var friendsScrollView: UIScrollView!
    
    private var searchResultsStackView: UIStackView!
    private var friendsStackView: UIStackView!
    private var friendsManager: FriendsManager?
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
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
        setupSearchResultsView()
        setupFriendsView()
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
    
    private func setupSearchResultsView() {
        // Setup search results stack view
        searchResultsStackView = UIStackView()
        searchResultsStackView.axis = .vertical
        searchResultsStackView.spacing = 8
        searchResultsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        searchResultsScrollView.addSubview(searchResultsStackView)
        
        NSLayoutConstraint.activate([
            searchResultsStackView.topAnchor.constraint(equalTo: searchResultsScrollView.contentLayoutGuide.topAnchor),
            searchResultsStackView.leadingAnchor.constraint(equalTo: searchResultsScrollView.leadingAnchor, constant: 16),
            searchResultsStackView.trailingAnchor.constraint(equalTo: searchResultsScrollView.trailingAnchor, constant: -16),
            searchResultsStackView.bottomAnchor.constraint(equalTo: searchResultsScrollView.contentLayoutGuide.bottomAnchor),
            searchResultsStackView.widthAnchor.constraint(equalTo: searchResultsScrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func setupFriendsView() {
        // Setup friends stack view
        friendsStackView = UIStackView()
        friendsStackView.axis = .vertical
        friendsStackView.spacing = 8
        friendsStackView.translatesAutoresizingMaskIntoConstraints = false
        
        friendsScrollView.addSubview(friendsStackView)
        
        NSLayoutConstraint.activate([
            friendsStackView.topAnchor.constraint(equalTo: friendsScrollView.contentLayoutGuide.topAnchor),
            friendsStackView.leadingAnchor.constraint(equalTo: friendsScrollView.leadingAnchor, constant: 16),
            friendsStackView.trailingAnchor.constraint(equalTo: friendsScrollView.trailingAnchor, constant: -16),
            friendsStackView.bottomAnchor.constraint(equalTo: friendsScrollView.contentLayoutGuide.bottomAnchor),
            friendsStackView.widthAnchor.constraint(equalTo: friendsScrollView.widthAnchor, constant: -32)
        ])
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
                    self.displaySearchResults(users)
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    self.clearSearchResults()
                }
            }
        }
    }
    
    private func clearSearchResults() {
        searchResultsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    private func displaySearchResults(_ users: [UserProfile]) {
        clearSearchResults()
        
        if users.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No users found"
            emptyLabel.textAlignment = .center
            emptyLabel.textColor = .gray
            searchResultsStackView.addArrangedSubview(emptyLabel)
        } else {
            users.forEach { user in
                let userView = createUserView(for: user, isSearchResult: true)
                searchResultsStackView.addArrangedSubview(userView)
            }
        }
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
        friendsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
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
        }
    }
    
    private func createUserView(for user: UserProfile, isSearchResult: Bool) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        container.layer.cornerRadius = 8
        container.layer.borderWidth = 1
        container.layer.borderColor = UIColor.systemGray5.cgColor
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let nameLabel = UILabel()
        nameLabel.text = user.username
        stackView.addArrangedSubview(nameLabel)
        
        let spacer = UIView()
        stackView.addArrangedSubview(spacer)
        
        let button = UIButton(type: .system)
        button.tag = stackView.arrangedSubviews.count
        
        if isSearchResult {
            button.setTitle("Add Friend", for: .normal)
            button.addTarget(self, action: #selector(sendFriendRequest(_:)), for: .touchUpInside)
        } else {
            button.setTitle("Remove", for: .normal)
            button.tintColor = .systemRed
            button.addTarget(self, action: #selector(removeFriend(_:)), for: .touchUpInside)
        }
        
        stackView.addArrangedSubview(button)
        container.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            stackView.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        
        return container
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
