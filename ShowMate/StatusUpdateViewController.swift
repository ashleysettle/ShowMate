//
//  StatusUpdateViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class StatusUpdateViewController: UIViewController, UITextFieldDelegate {
    
    var delegate:UIViewController!
    var show:WatchingShow!
    var tvShow:TVShow!
    
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var posterView: UIImageView!
    @IBOutlet weak var episodeTextField: UITextField!
    @IBOutlet weak var seasonTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Fetch the watching status when the view loads
        if let tvShow = tvShow {
            fetchWatchingShow(for: tvShow.showId) { [weak self] watchingShow in
                DispatchQueue.main.async {
                    self?.show = watchingShow ?? WatchingShow(
                        showId: tvShow.showId,
                        name: tvShow.name,
                        posterPath: tvShow.posterPath,
                        numSeasons: tvShow.numSeasons,
                        status: .init(season: 1, episode: 1)
                    )
                    // Update your UI here
                    self?.episodeTextField.delegate = self
                    self?.seasonTextField.delegate = self
                    self?.showTitleLabel.text = self?.show.name
                    self?.seasonTextField.text = String(self?.show.status.season ?? 1)
                    self?.episodeTextField.text = String(self?.show.status.episode ?? 1)
                    self?.loadPosterImage()
                }
            }
        }
    }
    
    private func fetchWatchingShow(for showId: Int, completion: @escaping (WatchingShow?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(nil)
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users")
            .document(userId)
            .collection("watching")
            .whereField("showId", isEqualTo: showId)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching watching show: \(error)")
                    completion(nil)
                    return
                }
                
                guard let document = snapshot?.documents.first,
                      let watchingShow = WatchingShow.fromDictionary(document.data()) else {
                    completion(nil)
                    return
                }
                
                completion(watchingShow)
            }
    }
    // Called when 'return' key pressed

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func loadPosterImage() {
        let baseURL = "https://image.tmdb.org/t/p/w500"
        let imageURLString = show.posterPath.hasPrefix("http") ? show.posterPath : baseURL + show.posterPath
        
        guard let url = URL(string: imageURLString) else {
            print("Invalid URL: \(show.posterPath)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Error creating image from data")
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self?.posterView.image = image
            }
        }.resume() // Don't forget to call resume()!
        
    }
    
    @IBAction func saveProgressButton(_ sender: Any) {
        guard let seasonText = seasonTextField.text,
              let episodeText = episodeTextField.text,
              let season = Int(seasonText),
              let episode = Int(episodeText),
              let userId = Auth.auth().currentUser?.uid else {
            print("error")
            return
        }
        
        let newStatus = WatchingShow.ShowStatus(season: season, episode: episode)
        let updatedShow = WatchingShow(
            showId: show.showId,
            name: show.name,
            posterPath: show.posterPath,
            numSeasons: show.numSeasons,
            status: newStatus
        )
        
        let db = Firestore.firestore()
        let watchingRef = db.collection("users")
            .document(userId)
            .collection("watching")
            .document(String(show.showId))
        
        watchingRef.setData(updatedShow.toDictionary) { [weak self] error in
            if let error = error {
                print("Error updating show status: \(error)")
            } else {
                self?.dismiss(animated: true) {

                }
            }
        }
    }
    
}
