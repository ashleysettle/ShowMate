//
//  ProfileViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/18/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ShowListUpdateDelegate {
    
    
    @IBOutlet weak var currentlyWatchingCV: UICollectionView!
    @IBOutlet weak var statusUpdateCV: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel!

//    @IBOutlet weak var followButton: UIButton!
//    private var isFollowing = false
    
    private var watchingShows: [TVShow] = [] {
        didSet {
            currentlyWatchingCV.reloadData()
        }
    }
    
    private var statusUpdates: [StatusUpdate] = [] {
        didSet {
            statusUpdateCV.reloadData()
        }
    }
    
    var user:UserProfile!
    private var loggedInUserId: String? { // Add this to track logged in user
        return Auth.auth().currentUser?.uid
    }
    
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel.text = user.username
        setupCollectionViews()
        loadWatchingList()
        loadStatusUpdates()
//        isFollowing = user.friendIds.contains(loggedInUserId ?? "")
//        followButton.tintColor = isFollowing ? .gray : .systemBlue
//        followButton.titleLabel?.text = isFollowing ? "Unfollow" : "Follow"
    }
    
    private func setupCollectionViews() {
        // Setup watching shows collection view
        currentlyWatchingCV.delegate = self
        currentlyWatchingCV.dataSource = self
        
        let showLayout = UICollectionViewFlowLayout()
        showLayout.scrollDirection = .horizontal
        showLayout.minimumInteritemSpacing = itemSpacing
        showLayout.minimumLineSpacing = itemSpacing
        currentlyWatchingCV.collectionViewLayout = showLayout
        currentlyWatchingCV.backgroundColor = .clear
        currentlyWatchingCV.showsHorizontalScrollIndicator = false
        currentlyWatchingCV.contentInset = sectionInsets
        
        // Setup status updates collection view
        statusUpdateCV.delegate = self
        statusUpdateCV.dataSource = self
        // Remove the register line since we're using storyboard cell
        
        let statusLayout = UICollectionViewFlowLayout()
        statusLayout.scrollDirection = .vertical
        statusLayout.minimumLineSpacing = 12
        statusLayout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)  // Add padding around section
        statusUpdateCV.collectionViewLayout = statusLayout
        statusUpdateCV.backgroundColor = .clear
        statusUpdateCV.showsVerticalScrollIndicator = true
        statusUpdateCV.contentInset = sectionInsets
    }
    
    private func loadWatchingList() {
        // Use the uid from the UserProfile passed to this view controller
        guard let userId = user?.uid else {
            print("User ID not available")
            return
        }
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
    
    private func loadStatusUpdates() {
        guard let userId = user?.uid else {
            print("User ID not available")
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

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == currentlyWatchingCV {
            return watchingShows.count
        }else {
            return statusUpdates.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == currentlyWatchingCV {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
            let watchingShow = watchingShows[indexPath.row]
            cell.configure(with: watchingShow.posterPath)
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatusCell", for: indexPath) as! StatusCell
            let status = statusUpdates[indexPath.row]
            cell.configure(with: status)
            
            cell.onLikePressed = {
                guard let userId = Auth.auth().currentUser?.uid else { return }
                // Your like button logic here
                let db = Firestore.firestore()
                let ref = StatusUpdate.statusUpdatesCollection().document(status.id)
                
                if !cell.isLiked {
                    // Add user to likedBy array and increment likes
                    ref.updateData([
                        "likes": FieldValue.increment(Int64(1)),
                        "likedBy": FieldValue.arrayUnion([userId])
                    ]) { error in
                        if let error = error {
                            print("Error updating likes: \(error)")
                        }
                    }
                } else {
                    // Remove user from likedBy array and decrement likes
                    ref.updateData([
                        "likes": FieldValue.increment(Int64(-1)),
                        "likedBy": FieldValue.arrayRemove([userId])
                    ]) { error in
                        if let error = error {
                            print("Error updating likes: \(error)")
                        }
                    }
                }
                
                cell.likeButton.setImage(UIImage(systemName: cell.isLiked ? "heart.fill" : "heart"), for: .normal)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == currentlyWatchingCV {
            let selectedShow = watchingShows[indexPath.row]
            DispatchQueue.main.async {
                print(selectedShow.name)
                self.performSegue(withIdentifier: "ShowDetailSegue", sender: selectedShow)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue",
           let destinationVC = segue.destination as? ShowDetailViewController,
           let show = sender as? TVShow {
            destinationVC.show = show
            destinationVC.delegate = self
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == currentlyWatchingCV {
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
        
    // MARK: - ShowListUpdateDelegate
        
    func showAddedToWatching(_ show: TVShow) {
    }
    
    func showAddedToWishlist(_ show: TVShow) {
    }
    
    func showRemovedFromWatching(_ show: TVShow) {
    }
    
    func showRemovedFromWishlist(_ show: TVShow) {
        
    }
}
