//
//  ProfileViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/18/24.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var currentlyWatchingCV: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel!

    private var watchingShows: [TVShow] = [] {
        didSet {
            currentlyWatchingCV.reloadData()
        }
    }
    
    var user:UserProfile!
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel.text = user.username
        setupCollectionViews()
        loadWatchingList()
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
        
    }
    
    private func loadWatchingList() {
        // Ensure the user object is set
            guard let userId = user?.uid else {
                print("User ID not available")
                return
            }
            
            // Use the static collection reference from TVShow for the given user ID
            TVShow.watchingCollection(userId: userId)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error loading watching list for user \(userId): \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    self?.watchingShows = documents.compactMap { document in
                        TVShow.fromDictionary(document.data())
                    }
                    
                    print("Loaded \(self?.watchingShows.count ?? 0) watching shows for user \(userId)")
                }
    }
    

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            // Keep existing show collection sizing
            let availableHeight = collectionView.bounds.height - (sectionInsets.top + sectionInsets.bottom)
            let width = availableHeight / posterAspectRatio
            return CGSize(width: width, height: availableHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return watchingShows.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
            let watchingShow = watchingShows[indexPath.row]
            cell.configure(with: watchingShow.posterPath)
            return cell
        
    }
    
    /*func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == showCollectionView {
            let selectedShow = watchingShows[indexPath.row]
            DispatchQueue.main.async {
                print(selectedShow.name)
                self.performSegue(withIdentifier: "StatusUpdateSegue", sender: selectedShow)
            }
        }
    }*/

}
