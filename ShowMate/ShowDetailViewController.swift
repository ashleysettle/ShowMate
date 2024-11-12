//
//  ShowDetailViewController.swift
//  ShowMate
//
//  Created by Victoria Plaxton on 10/22/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class ShowDetailViewController: UIViewController {
    
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var showImageView: UIImageView!
    @IBOutlet weak var showDescriptionLabel: UILabel!
    @IBOutlet weak var providerLabel: UILabel!
    @IBOutlet weak var lastAirDate: UILabel!
    @IBOutlet weak var firstAirDate: UILabel!
    @IBOutlet weak var numberOfSeasons: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var currentlyWatchingButton: UIButton!
    @IBOutlet weak var watchlistButton: UIButton!
    
    var show: TVShow!
    weak var delegate: ShowListUpdateDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        checkIfShowIsBeingWatched()
        checkIfShowIsWished()
    }
    
    private func configureUI() {
        guard let show = show else { return }
        
        showTitleLabel.text = show.name
        showDescriptionLabel.text = show.description
        showDescriptionLabel.sizeToFit()
        
        guard let url = URL(string: show.posterPath) else {
                print("Invalid URL: \(show.posterPath)")
                return
            }
       showImageView.image = UIImage(systemName: "photo.fill")
       
       URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
           guard let self = self,
                 let data = data,
                 error == nil,
                 let image = UIImage(data: data) else {
               print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
               return
           }
           
           // Update UI on main thread
           DispatchQueue.main.async {
               self.showImageView.image = image
           }
       }.resume()
        providerLabel.text = "Where to Watch: \(show.providers.joined(separator: ", "))"
        genreLabel.sizeToFit()
        genreLabel.text = "Genres: \(show.genres.joined(separator: ", "))"
        numberOfSeasons.text = "Number of Seasons: \(show.numSeasons)"
        firstAirDate.text = "First Air Date: \(show.firstAirDate)"
        lastAirDate.text = "Last Air Date: \(show.lastAirDate)"
    }
    
    func checkIfShowIsBeingWatched() {
        guard let userId = Auth.auth().currentUser?.uid,
              let show = show else { return }
        
        let db = Firestore.firestore()
        let watchingRef = db.collection("users")
            .document(userId)
            .collection("watching")
            .document(String(show.showId))
        
        watchingRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    self.currentlyWatchingButton.tintColor = .gray
                } else {
                    self.currentlyWatchingButton.tintColor = .systemBlue // or your default color
                }
            }
        }
    }
    
    func checkIfShowIsWished() {
        guard let userId = Auth.auth().currentUser?.uid,
              let show = show else { return }
        
        let db = Firestore.firestore()
        let wishRef = db.collection("users")
            .document(userId)
            .collection("wish")
            .document(String(show.showId))
        
        wishRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let document = document, document.exists {
                    self.watchlistButton.tintColor = .gray
                } else {
                    self.watchlistButton.tintColor = .systemBlue
                }
            }
        }
    }
    
    @IBAction func currentlyWatchingButton(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid,
              let show = show else { return }
        
        let db = Firestore.firestore()
        let watchingRef = db.collection("users")
            .document(userId)
            .collection("watching")
            .document(String(show.showId))
        
        // First check if the show is already being watched
        watchingRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Show is already being watched, remove it
                watchingRef.delete { error in
                    if let error = error {
                        print("Error removing show: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.currentlyWatchingButton.tintColor = .systemBlue // or your default color
                            self.delegate?.showRemovedFromWatching(show)
                        }
                    }
                }
            } else {
                // Add to watching
                let watchingShow = WatchingShow(
                    showId: show.showId,
                    name: show.name,
                    posterPath: show.posterPath,
                    numSeasons: show.numSeasons,
                    status: WatchingShow.ShowStatus(season: 1, episode: 1)
                )
                
                watchingRef.setData(watchingShow.toDictionary) { error in
                    if let error = error {
                        print("Error adding show: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.currentlyWatchingButton.tintColor = .gray
                            self.delegate?.showAddedToWatching(show)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func addToWatchingButton(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid,
              let show = show else { return }
        
        let db = Firestore.firestore()
        let wishRef = db.collection("users")
            .document(userId)
            .collection("wish")
            .document(String(show.showId))
        
        // First check if the show is already being watched
        wishRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Show is already being watched, remove it
                wishRef.delete { error in
                    if let error = error {
                        print("Error removing show: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.watchlistButton.tintColor = .systemBlue
                            self.delegate?.showRemovedFromWishlist(show)
                        }
                    }
                }
            } else {
                // Add to watching
                let wishShow = WishShow(
                    showId: show.showId,
                    name: show.name,
                    posterPath: show.posterPath,
                    providerNames: show.providers
                )
                
                wishRef.setData(wishShow.toDictionary) { error in
                    if let error = error {
                        print("Error adding show: \(error)")
                    } else {
                        DispatchQueue.main.async {
                            self.watchlistButton.tintColor = .gray
                            self.delegate?.showAddedToWishlist(show)
                        }
                    }
                }
            }
        }

    }
}
