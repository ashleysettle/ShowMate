// LandingVC.swift
import UIKit
import FirebaseAuth
import FirebaseFirestore

class LandingVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var showCollectionView: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    private var watchingShows: [WatchingShow] = [] {
            didSet {
                showCollectionView.reloadData()
            }
        }
    
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        checkAuthAndUpdateUI()
        loadWatchingList()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.checkAuthAndUpdateUI()
        }
        
    }
    
    private func loadWatchingList() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userId)
            .collection("watching")
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    print("Error loading watching list: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self?.watchingShows = documents.compactMap { document in
                    WatchingShow.fromDictionary(document.data())
                }
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
    
    private func setupCollectionView() {
        showCollectionView.delegate = self
        showCollectionView.dataSource = self
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = itemSpacing
        layout.minimumLineSpacing = itemSpacing
        showCollectionView.collectionViewLayout = layout
        
        showCollectionView.backgroundColor = .clear
        showCollectionView.showsHorizontalScrollIndicator = false
        showCollectionView.contentInset = sectionInsets
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableHeight = collectionView.bounds.height - (sectionInsets.top + sectionInsets.bottom)
        let width = availableHeight / posterAspectRatio
        return CGSize(width: width, height: availableHeight)
    }
    
    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return watchingShows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
        let watchingShow = watchingShows[indexPath.row]
        cell.configure(with: watchingShow.posterPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedShow = watchingShows[indexPath.row]
        print(selectedShow.name)
    }
    
    
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
}
