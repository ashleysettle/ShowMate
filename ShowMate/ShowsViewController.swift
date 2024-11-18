//
//  ShowsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/22/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

protocol ShowListUpdateDelegate: AnyObject {
    func showAddedToWatching(_ show: TVShow)
    func showAddedToWishlist(_ show: TVShow)
    func showRemovedFromWatching(_ show: TVShow)
    func showRemovedFromWishlist(_ show: TVShow)
}

class ShowsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, ShowListUpdateDelegate{
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var watchlistCV: UICollectionView!
    @IBOutlet weak var currentlyWatchingCV: UICollectionView!
    @IBOutlet weak var showCollectionView: UICollectionView!
    // API Key for TMDB
    let apiKey = "93080f9cf388f053e991e750e536b3ff"
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var showSearchBar: UISearchBar!
    
    @IBOutlet weak var watchlistLabel: UILabel!
    @IBOutlet weak var currentlyWatchingLabel: UILabel!
    @IBOutlet weak var searchLabel: UILabel!
    
    // Properties to hold the lists of shows
    var currentlyWatching: [TVShow] = []
    var watched: [TVShow] = []
    var watchlist: [TVShow] = []
    
    // Array to hold search results
    var searchResults: [TVShow] = []
    
    // Layout constants
    private let sectionInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    private let itemSpacing: CGFloat = 12
    private let posterAspectRatio: CGFloat = 1.5
    
    // MARK: View setup
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        updateDisplayName()
        fetchUserLists()
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
        }
        fixScrollViewConstraints()
        showSearchBar.showsCancelButton = true
        showSearchBar.autocapitalizationType = .none
    }
    
    private func setupCollectionView() {
        [showCollectionView, currentlyWatchingCV, watchlistCV].forEach { collectionView in
            collectionView?.delegate = self
            collectionView?.dataSource = self
            
            let layout = UICollectionViewFlowLayout()
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = itemSpacing
            layout.minimumLineSpacing = itemSpacing
            collectionView?.collectionViewLayout = layout
            
            collectionView?.backgroundColor = .clear
            collectionView?.showsHorizontalScrollIndicator = false
            collectionView?.contentInset = sectionInsets
        }
    }
    
    private func fixScrollViewConstraints() {
        scrollView.alwaysBounceVertical = true
        scrollView.alwaysBounceHorizontal = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.subviews.forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        // Configure the width of elements to match the scroll view's width
        if let searchShowsLabel = searchLabel {
            NSLayoutConstraint.activate([
                searchShowsLabel.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
                searchShowsLabel.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
                searchShowsLabel.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16)
            ])
        }
        
        if let searchBar = showSearchBar {
            NSLayoutConstraint.activate([
                searchBar.topAnchor.constraint(equalTo: searchLabel?.bottomAnchor ?? scrollView.contentLayoutGuide.topAnchor, constant: 20),
                searchBar.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
                searchBar.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor)
            ])
        }
        
        if let searchResults = showCollectionView {
            NSLayoutConstraint.activate([
                searchResults.topAnchor.constraint(equalTo: showSearchBar?.bottomAnchor ?? scrollView.contentLayoutGuide.topAnchor, constant: 20),
                searchResults.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
                searchResults.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
                searchResults.heightAnchor.constraint(equalToConstant: 200)
            ])
        }
        
        if let currentlyWatchingLabel = currentlyWatchingLabel {
            NSLayoutConstraint.activate([
                currentlyWatchingLabel.topAnchor.constraint(equalTo: showCollectionView?.bottomAnchor ?? scrollView.contentLayoutGuide.topAnchor, constant: 20),
                currentlyWatchingLabel.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
                currentlyWatchingLabel.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16)
            ])
        }
        
        if let currentlyWatching = currentlyWatchingCV {
            NSLayoutConstraint.activate([
                currentlyWatching.topAnchor.constraint(equalTo: currentlyWatchingLabel?.bottomAnchor ?? scrollView.contentLayoutGuide.topAnchor, constant: 12),
                currentlyWatching.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
                currentlyWatching.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
                currentlyWatching.heightAnchor.constraint(equalToConstant: 200)
            ])
        }
        
        if let watchlistLabel = watchlistLabel {
            NSLayoutConstraint.activate([
                watchlistLabel.topAnchor.constraint(equalTo: currentlyWatchingCV?.bottomAnchor ?? scrollView.contentLayoutGuide.topAnchor, constant: 20),
                watchlistLabel.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
                watchlistLabel.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16)
            ])
        }
        
        if let watchlist = watchlistCV {
            NSLayoutConstraint.activate([
                watchlist.topAnchor.constraint(equalTo: watchlistLabel?.bottomAnchor ?? scrollView.contentLayoutGuide.topAnchor, constant: 12),
                watchlist.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
                watchlist.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
                watchlist.heightAnchor.constraint(equalToConstant: 200),
                watchlist.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20)
            ])
        }
    }
        
    // MARK: fetch user's lists from firebase
    private func fetchUserLists() {
            guard let userId = Auth.auth().currentUser?.uid else { return }
            
            // Fetch watching list
            TVShow.watchingCollection(userId: userId)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error fetching watching list: \(error)")
                        return
                    }
                    
                    self?.currentlyWatching = snapshot?.documents.compactMap {
                        TVShow.fromDictionary($0.data())
                    } ?? []
                    
                    DispatchQueue.main.async {
                        self?.currentlyWatchingCV.reloadData()
                    }
                }
            
            // Fetch wishlist
            TVShow.wishlistCollection(userId: userId)
                .addSnapshotListener { [weak self] snapshot, error in
                    if let error = error {
                        print("Error fetching wishlist: \(error)")
                        return
                    }
                    
                    self?.watchlist = snapshot?.documents.compactMap {
                        TVShow.fromDictionary($0.data())
                    } ?? []
                    
                    DispatchQueue.main.async {
                        self?.watchlistCV.reloadData()
                    }
                }
        }
    // MARK: - Collection View
    
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
        let availableHeight = collectionView.bounds.height - (sectionInsets.top + sectionInsets.bottom)
        let width = availableHeight / posterAspectRatio
        
        return CGSize(width: width, height: availableHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case showCollectionView:
            return searchResults.count
        case currentlyWatchingCV:
            return currentlyWatching.count
        case watchlistCV:
            return watchlist.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ShowCell", for: indexPath) as! ShowCell
                
        let show: TVShow?
        switch collectionView {
        case showCollectionView:
            show = searchResults[indexPath.row]
        case currentlyWatchingCV:
            show = currentlyWatching[indexPath.row]
        case watchlistCV:
            show = watchlist[indexPath.row]
        default:
            show = nil
        }
        
        if let show = show {
            cell.configure(with: show.posterPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case currentlyWatchingCV:
            let show = currentlyWatching[indexPath.row]
            performSegue(withIdentifier: "StatusSegue", sender: show)
            
        case showCollectionView:
            let show = searchResults[indexPath.row]
            fetchShowDetails(for: show.showId) { [weak self] detailedShow in
                guard let detailedShow = detailedShow else { return }
                DispatchQueue.main.async {
                    self?.performSegue(withIdentifier: "ShowDetailSegue", sender: detailedShow)
                }
            }
            
        case watchlistCV:
            let show = watchlist[indexPath.row]
            performSegue(withIdentifier: "ShowDetailSegue", sender: show)
            
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowDetailSegue",
           let destinationVC = segue.destination as? ShowDetailViewController,
           let show = sender as? TVShow {
            destinationVC.show = show
            destinationVC.delegate = self
        }else if segue.identifier == "StatusSegue", let destinationVC = segue.destination as? StatusUpdateViewController, let show = sender as? TVShow {
                destinationVC.show = show
                destinationVC.delegate = self
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
        fetchUserLists()
    }
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    // MARK: - ShowListUpdateDelegate
        
    func showAddedToWatching(_ show: TVShow) {
        if !currentlyWatching.contains(where: { $0.showId == show.showId }) {
            currentlyWatching.append(show)
            currentlyWatchingCV.reloadData()
        }
    }
    
    func showAddedToWishlist(_ show: TVShow) {
        if !watchlist.contains(where: { $0.showId == show.showId }) {
            watchlist.append(show)
            watchlistCV.reloadData()
        }
    }
    
    func showRemovedFromWatching(_ show: TVShow) {
        if let index = currentlyWatching.firstIndex(where: { $0.showId == show.showId }) {
            currentlyWatching.remove(at: index)
            currentlyWatchingCV.reloadData()
        }
    }
    
    func showRemovedFromWishlist(_ show: TVShow) {
        if let index = watchlist.firstIndex(where: { $0.showId == show.showId }) {
            watchlist.remove(at: index)
            watchlistCV.reloadData()
        }
    }
    
    // MARK: Search bar
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            searchResults = []
            showCollectionView.reloadData()
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, !searchText.isEmpty else { return }
        
        fetchTVShowDetails(for: searchText) { [weak self] shows in
            DispatchQueue.main.async {
                if let shows = shows {
                    self?.searchResults = shows
                    self?.showCollectionView.reloadData()
                    print("Found \(shows.count) shows matching search")
                } else {
                    self?.searchResults = []
                    self?.showCollectionView.reloadData()
                    print("No shows found or error occurred")
                }
            }
        }
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    // MARK: API 
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
                // DEBUGGING: PRINTS ALL SHOW DETAILS
                // let prettyPrintedData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
                    
                // Convert Data to String for printing
                // if let jsonString = String(data: prettyPrintedData, encoding: .utf8) {
                    // print("Serialized JSON:\n", jsonString)
                // }
                // END OF JSON PRINT
                
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
                var episodesPerSeason: [Int] = []
                // attempt to get season specific info (# episodes)
                if let seasons = json?["seasons"] as? [[String: Any]] {
        
                    // Find episode count for each season
                    // Don't add season if number 0
                    for season in seasons {
                        if let seasonNumber = season["season_number"] as? Int,
                           seasonNumber != 0,
                           let episodeCount = season["episode_count"] as? Int {
                            episodesPerSeason.append(episodeCount)
                        }
                    }
                    
                    // TODO: remove, just for testing
                    print("Episodes per season for show \(name): \(episodesPerSeason)")
                } else {
                    // I don't think this should happen
                    print("No seasons found")
                }
                    

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
                        providerLogoPaths: providerLogoPaths,
                        episodesPerSeason: episodesPerSeason
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
