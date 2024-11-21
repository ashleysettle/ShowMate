// LandingVC.swift
import UIKit
import FirebaseAuth
import FirebaseFirestore

class LandingVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var showCollectionView: UICollectionView!
    @IBOutlet weak var feedCollectionView: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    private var watchingShows: [TVShow] = [] {
        didSet {
            showCollectionView.reloadData()
        }
    }
    
    private var statusUpdates: [StatusUpdate] = [] {
        didSet {
            feedCollectionView.reloadData()
        }
    }
    
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViews()
        checkAuthAndUpdateUI()
        loadWatchingList()
        loadStatusUpdates()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.checkAuthAndUpdateUI()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
        loadStatusUpdates()
    }
    
    private func loadWatchingList() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Use the static collection reference from TVShow
        TVShow.watchingCollection(userId: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading watching list: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.watchingShows = documents.compactMap { document in
                    TVShow.fromDictionary(document.data())
                }
                
                print("Loaded \(self?.watchingShows.count ?? 0) watching shows")
            }
    }
    
    private func checkAuthAndUpdateUI() {
        if let user = Auth.auth().currentUser {
            updateDisplayName()
        } else {
            // No user logged in, return to login screen
            if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                sceneDelegate.checkAuthAndSetRootViewController()
            }
        }
    }
    
    private func setupCollectionViews() {
        // Setup watching shows collection view
        showCollectionView.delegate = self
        showCollectionView.dataSource = self
        
        let showLayout = UICollectionViewFlowLayout()
        showLayout.scrollDirection = .horizontal
        showLayout.minimumInteritemSpacing = itemSpacing
        showLayout.minimumLineSpacing = itemSpacing
        showCollectionView.collectionViewLayout = showLayout
        showCollectionView.backgroundColor = .clear
        showCollectionView.showsHorizontalScrollIndicator = false
        showCollectionView.contentInset = sectionInsets
        
        // Setup status updates collection view
        feedCollectionView.delegate = self
        feedCollectionView.dataSource = self
        // Remove the register line since we're using storyboard cell
        
        let statusLayout = UICollectionViewFlowLayout()
        statusLayout.scrollDirection = .vertical
        statusLayout.minimumLineSpacing = 12
        statusLayout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)  // Add padding around section
        feedCollectionView.collectionViewLayout = statusLayout
        feedCollectionView.backgroundColor = .clear
        feedCollectionView.showsVerticalScrollIndicator = true
        feedCollectionView.contentInset = sectionInsets
    }
    
    private func loadStatusUpdates() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID available")
            return
        }
        
        // Load all status updates for current user and friends
        let db = Firestore.firestore()
        
        // First get user's friends
        db.collection("users").document(userId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error getting user document: \(error)")
                return
            }
            
            guard let self = self,
                  let data = document?.data() else {
                print("No user data found")
                return
            }
            
            var relevantUserIds = [userId] // Start with current user
            
            // Add friend IDs if they exist
            if let friendIds = data["friend_ids"] as? [String] {
                relevantUserIds.append(contentsOf: friendIds)
            }
            
            print("Loading status updates for users: \(relevantUserIds)")
            
            // Listen for status updates from friends and current user
            StatusUpdate.statusUpdatesCollection()
                .whereField("userId", in: relevantUserIds)  // Use the array of IDs
                .order(by: "timestamp", descending: true)
                .limit(to: 20)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error fetching status updates: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("No status documents found")
                        return
                    }
                    
                    print("Found \(documents.count) status documents")
                    
                    self?.statusUpdates = documents.compactMap { document in
                        let status = StatusUpdate.fromDictionary(document.data(), id: document.documentID)
                        if status == nil {
                            print("Failed to parse status update: \(document.data())")
                        }
                        return status
                    }
                    
                    print("Parsed \(self?.statusUpdates.count ?? 0) valid status updates")
                }
        }
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == showCollectionView {
            // Keep existing show collection sizing
            let availableHeight = collectionView.bounds.height - (sectionInsets.top + sectionInsets.bottom)
            let width = availableHeight / posterAspectRatio
            return CGSize(width: width, height: availableHeight)
        } else {
            // Status cell sizing
            let width = collectionView.bounds.width - 12  // Account for left/right padding
            return CGSize(width: width, height: 140)  // Increase height slightly
        }
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == showCollectionView {
            return watchingShows.count
        }else {
            return statusUpdates.count
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == showCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
            let watchingShow = watchingShows[indexPath.row]
            cell.configure(with: watchingShow.posterPath)
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatusCell", for: indexPath) as! StatusCell
            let status = statusUpdates[indexPath.row]
            cell.configure(with: status)
            return cell
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == showCollectionView {
            let selectedShow = watchingShows[indexPath.row]
            DispatchQueue.main.async {
                print(selectedShow.name)
                self.performSegue(withIdentifier: "StatusUpdateSegue", sender: selectedShow)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StatusUpdateSegue",
           let nextVC = segue.destination as? StatusUpdateViewController {
            nextVC.delegate = self
            nextVC.show = sender as? TVShow
        }
    }
    
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
}
