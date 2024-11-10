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
    var show: TVShow!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    private func configureUI() {
        guard let show = show else { return }
        
        showTitleLabel.text = show.name
        showDescriptionLabel.text = show.description
        
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
        providerLabel.sizeToFit()
        providerLabel.text = "Where to Watch: \(show.providers.joined(separator: ", "))"
        genreLabel.sizeToFit()
        genreLabel.text = "Genres: \(show.genres.joined(separator: ", "))"
        numberOfSeasons.text = "Number of Seasons: \(show.numSeasons)"
        firstAirDate.text = "First Air Date: \(show.firstAirDate)"
        lastAirDate.text = "Last Air Date: \(show.lastAirDate)"
        show.printDetails()
    }
    @IBAction func currentlyWatchingButton(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid,
                      let show = show else { return }
                
        let db = Firestore.firestore()
        let watchingRef = db.collection("users")
            .document(userId)
            .collection("watching")
            .document(String(show.showId))
        
        // Simply add to watching
        let watchingShow = WatchingShow(
            showId: show.showId,
            name: show.name,
            posterPath: show.posterPath
        )
        
        watchingRef.setData(watchingShow.toDictionary) { error in
            if let error = error {
                print("Error adding show: \(error)")
            } else {
                DispatchQueue.main.async {
                    self.currentlyWatchingButton.tintColor = .green
                }
            }
        }
    }
}
