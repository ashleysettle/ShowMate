//
//  ShowsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/22/24.
//

import UIKit
import FirebaseAuth

class ShowsViewController: UIViewController {
    
    // Outlets
    @IBOutlet weak var usernameLabel: UILabel!
    
    // Lists for currently watching, watched, and to-watch TV shows
    var currentlyWatching = [TVShow]()
    var watched = [TVShow]()
    var toWatch = [TVShow]()
    
    // API Key for TMDB
    let apiKey = "YOUR_API_KEY"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplayName()
        
        // Add authentication state listener
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
    }
    
    // Update display name based on user authentication
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    // Fetch TV show details
    func fetchShowDetails(for showId: Int) {
        let detailsUrl = "https://api.themoviedb.org/3/tv/\(showId)?api_key=\(apiKey)&append_to_response=credits"
        
        URLSession.shared.dataTask(with: URL(string: detailsUrl)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching show details: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                // Parse show details here
                let name = json?["name"] as? String ?? "N/A"
                let description = json?["overview"] as? String ?? "N/A"
                let genres = (json?["genres"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
                let firstAirDate = json?["first_air_date"] as? String ?? "N/A"
                let lastAirDate = json?["last_air_date"] as? String ?? "N/A"
                let numSeasons = json?["number_of_seasons"] as? Int ?? 0
                let posterPath = json?["poster_path"] as? String ?? ""
                let cast = (json?["credits"] as? [String: Any])?["cast"] as? [[String: Any]] ?? []
                let castNames = cast.compactMap { $0["name"] as? String }
                
                // Fetch watch providers
                self.fetchWatchProviders(for: showId) { providers in
                    // Create a TVShow instance with the fetched data
                    let tvShow = TVShow(name: name, description: description, genres: genres, firstAirDate: firstAirDate, lastAirDate: lastAirDate, numSeasons: numSeasons, posterPath: posterPath, cast: castNames, providers: providers)
                    
                    // TODO: conditionals for adding to list
                    DispatchQueue.main.async {
                        self.currentlyWatching.append(tvShow)
                        self.updateUI() // Update the UI with the new show details
                    }
                }
                
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    // Fetch watch providers for a TV show
    // Use completion to handle once task completes
    func fetchWatchProviders(for showId: Int, completion: @escaping ([String]) -> Void) {
        let providerUrl = "https://api.themoviedb.org/3/tv/\(showId)/watch/providers?api_key=\(apiKey)"
        
        URLSession.shared.dataTask(with: URL(string: providerUrl)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching providers: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                let results = json?["results"] as? [String: Any]
                let usProviders = results?["US"] as? [String: Any]
                let providerNames = (usProviders?["flatrate"] as? [[String: Any]])?.compactMap { $0["provider_name"] as? String } ?? []
                
                completion(providerNames) // Return the provider names
                
            } catch {
                print("Error parsing providers JSON: \(error.localizedDescription)")
                completion([])
            }
        }.resume()
    }
    
    // UI update function
    // Want to see when lists are updated
    private func updateUI() {
        print("UI Updated with \(currentlyWatching.count) shows in 'Currently Watching'")
    }
}
