//
//  ShowsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/22/24.
//

import UIKit
import FirebaseAuth

class ShowsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate{
    
    @IBOutlet weak var showCollectionView: UICollectionView!
    // API Key for TMDB
    // TODO: CHANGE TO ACCESS TOKEN?
    let apiKey = "93080f9cf388f053e991e750e536b3ff"
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var showSearchBar: UISearchBar!
    
    
    // Properties to hold the lists of shows
    var currentlyWatching: [TVShow] = []
    var watched: [TVShow] = []
    var toWatch: [TVShow] = []
    
    // Array to hold search results
    var searchResults: [TVShow] = []
    
    // Layout constants
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        updateDisplayName()
        
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        searchBar.resignFirstResponder() // Dismiss keyboard
        searchSubmitted(show: searchText)
    }
    
    
    private func setupCollectionView() {
        showCollectionView.delegate = self
        showCollectionView.dataSource = self
        
        // Configure layout
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
        return searchResults.count // Will be replaced with actual show data later
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
        cell.configure(with: searchResults[indexPath.row].posterPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedShow = searchResults[indexPath.row]
        
        // Fetch full details for the selected show
        fetchShowDetails(for: selectedShow.showId) { [weak self] detailedShow in
            guard let detailedShow = detailedShow else {
                print("Failed to fetch show details")
                return
            }
            
            DispatchQueue.main.async {
                print(detailedShow.name)
                self?.performSegue(withIdentifier: "ShowDetailSegue", sender: detailedShow)
                // Navigate to detail view controller
                //self?.showDetailView(for: detailedShow)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue",
           let destinationVC = segue.destination as? ShowDetailViewController,
           let show = sender as? TVShow {
            destinationVC.show = show
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
    }
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    // UI update function
    // Want to see when lists are updated
    private func updateUI() {
        print("UI Updated with \(currentlyWatching.count) shows in 'Currently Watching'")
    }
    
    // Triggered after a show name is searched
    // TODO: show results as they type (beta)
    // Return: TVShow object if created (TV Show found), otherwise null
    private func searchSubmitted(show: String) {
        fetchTVShowDetails(for: show) { tvShows in
            if let tvShows = tvShows {
                // Success: Array of TVShow objects was created
                self.searchResults = tvShows // Store the results for later use
//                print("Shows found: \(self.searchResults.map { $0.name })")
//                print("Images found: \(self.searchResults.map { $0.posterPath })")
                DispatchQueue.main.async {
                                self.showCollectionView.reloadData()
                            }
                // TODO: display search results (title and picture) in dropdown
            } else {
                // Failure: No show was found
                // TODO: display no resuplts found in results dropdown
                print("No results found.")
            }
        }
    }

    // Returns an array of TV show objects w/ matching titles
    // Only fetch poster and title for searching stage
    func fetchTVShowDetails(for title: String, completion: @escaping ([TVShow]?) -> Void) {
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let searchUrl = "https://api.themoviedb.org/3/search/tv?api_key=\(apiKey)&query=\(query)"

        URLSession.shared.dataTask(with: URL(string: searchUrl)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching show details: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                guard let results = json?["results"] as? [[String: Any]] else {
                    print("No results found")
                    DispatchQueue.main.async {
                        completion(nil)
                    }
                    return
                }

                var tvShows: [TVShow] = []
                for result in results {
                    // Extract show ID
                    let showId = result["id"] as? Int ?? 0
                    let name = result["name"] as? String ?? "Unknown Title"
                    let posterPath = result["poster_path"] as? String ?? "No Poster"
                    let posterUrl = "https://image.tmdb.org/t/p/w500\(posterPath)"

                    // Create a TVShow object for each result
                    let tvShow = TVShow(name: name, showId: showId, posterPath: posterUrl)
                    tvShows.append(tvShow)
                }

                // Return the array of TVShow objects
                DispatchQueue.main.async {
                    completion(tvShows)
                }

            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // Call when an option is selected from dropdown (want ALL the show data now)
    func fetchShowDetails(for showId: Int, completion: @escaping (TVShow?) -> Void) {
        let detailsUrl = "https://api.themoviedb.org/3/tv/\(showId)?api_key=\(apiKey)&append_to_response=credits"
        
        URLSession.shared.dataTask(with: URL(string: detailsUrl)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching detailed show information: \(error?.localizedDescription ?? "Unknown error")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                let name = json?["name"] as? String ?? "Unknown Title"
                let description = json?["overview"] as? String ?? "N/A"
                let firstAirDate = json?["first_air_date"] as? String ?? "N/A"
                let lastAirDate = json?["last_air_date"] as? String ?? "N/A"
                let genres = json?["genres"] as? [[String: Any]] ?? []
                let numSeasons = json?["number_of_seasons"] as? Int ?? 0
                let posterPath = json?["poster_path"] as? String ?? ""
                let posterUrl = "https://image.tmdb.org/t/p/w500\(posterPath)"
                let genreNames = genres.compactMap { $0["name"] as? String }
                let cast = (json?["credits"] as? [String: Any])?["cast"] as? [[String: Any]] ?? []
                let castNames = cast.compactMap { $0["name"] as? String }

                // Fetch watch providers, then call completion
                self.fetchWatchProviders(for: showId) { providers, providerLogoPaths in
                    let tvShow = TVShow(
                        name: name,
                        showId: showId,
                        description: description,
                        genres: genreNames,
                        firstAirDate: firstAirDate,
                        lastAirDate: lastAirDate,
                        numSeasons: numSeasons,
                        posterPath: posterUrl,
                        cast: castNames,
                        providers: providers,
                        providerLogoPaths: providerLogoPaths
                    )
                    DispatchQueue.main.async {
                        completion(tvShow)
                    }
                }

            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }

    // Fetch watch providers and update the TVShow object
    func fetchWatchProviders(for showId: Int, completion: @escaping ([String], [String]) -> Void) {
        let countryCode = Locale.current.region?.identifier ?? "US"
        let providersUrl = "https://api.themoviedb.org/3/tv/\(showId)/watch/providers?api_key=\(apiKey)"
        
        URLSession.shared.dataTask(with: URL(string: providersUrl)!) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching watch providers: \(error?.localizedDescription ?? "Unknown error")")
                completion([], []) // Return empty arrays if error
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                var providerNames: [String] = []
                var logoUrls: [String] = []
                
                if let results = json?["results"] as? [String: Any],
                   let providerInfo = results[countryCode] as? [String: Any],
                   let providerArray = providerInfo["flatrate"] as? [[String: Any]] {
                    
                    for provider in providerArray {
                        if let providerName = provider["provider_name"] as? String {
                            providerNames.append(providerName)
                        }
                        if let logoPath = provider["logo_path"] as? String {
                            let logoUrl = "https://image.tmdb.org/t/p/w92\(logoPath)"
                            logoUrls.append(logoUrl)
                        }
                    }
                } else {
                    print("No watch provider information available for \(countryCode)")
                }
                
                // Return both the provider names and provider logo URLs
                completion(providerNames, logoUrls)

            } catch {
                print("Error parsing watch providers JSON: \(error.localizedDescription)")
                completion([], [])
            }
        }.resume()
    }
    
}
