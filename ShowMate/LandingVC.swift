//
//  LandingVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit
import FirebaseAuth

class LandingVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var showCollectionView: UICollectionView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    let shows = ["pll", "office", "dwts", "bluey", "b99"]
    
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5  // Standard movie poster ratio (3:2)
    
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        updateDisplayName()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
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
         // Calculate height first based on collection view height
         let availableHeight = collectionView.bounds.height - (sectionInsets.top + sectionInsets.bottom)
         let width = availableHeight / posterAspectRatio  // Width based on poster aspect ratio
         
         return CGSize(width: width, height: availableHeight)
     }
     
     // MARK: - UICollectionViewDataSource
     
     func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
         return shows.count
     }
     
     func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
         let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
         cell.configure(with: shows[indexPath.row])
         return cell
     }
     
     private func updateDisplayName() {
         if let user = Auth.auth().currentUser {
             usernameLabel.text = user.displayName
         } else {
             usernameLabel.text = "N/A"
         }
     }
 }
