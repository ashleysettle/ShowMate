//
//  TVShow.swift
//  ShowMate
//
//  Created by Victoria Plaxton on 10/22/24.
//
import Foundation
import FirebaseFirestore

class TVShow {
    let showId: Int
    let name: String
    var description: String
    var genres: [String]
    var firstAirDate: String
    var lastAirDate: String
    var numSeasons: Int
    var posterPath: String
    var cast: [String]
    var providers: [String]
    var providerLogoPaths: [String]
    var episodesPerSeason: [Int]
    var preview: Bool
    
    // Watching status
    var watchingStatus: WatchingStatus?
    
    struct WatchingStatus: Codable {
        var season: Int
        var episode: Int
    }
    
    // Firestore conversion
    var toDictionary: [String: Any] {
        var dict: [String: Any] = [
            "showId": showId,
            "name": name,
            "description": description,
            "genres": genres,
            "firstAirDate": firstAirDate,
            "lastAirDate": lastAirDate,
            "numSeasons": numSeasons,
            "posterPath": posterPath,
            "cast": cast,
            "providers": providers,
            "providerLogoPaths": providerLogoPaths,
            "episodesPerSeason": episodesPerSeason,
            "preview": preview
        ]
        
        if let status = watchingStatus {
            dict["watchingStatus"] = [
                "season": status.season,
                "episode": status.episode
            ]
        }
        
        return dict
    }
    
    init(name: String, showId: Int, description: String, genres: [String], firstAirDate: String, lastAirDate: String, numSeasons: Int, posterPath: String, cast: [String], providers: [String], providerLogoPaths: [String], episodesPerSeason: [Int], watchingStatus: WatchingStatus? = WatchingStatus(season: 1, episode: 1)) {
        self.name = name
        self.showId = showId
        self.description = description
        self.genres = genres
        self.firstAirDate = firstAirDate
        self.lastAirDate = lastAirDate
        self.numSeasons = numSeasons
        self.posterPath = posterPath
        self.cast = cast
        self.providers = providers
        self.providerLogoPaths = providerLogoPaths
        self.episodesPerSeason = episodesPerSeason
        self.preview = false
        self.watchingStatus = watchingStatus
        
    }
    
    // Initializer for search results
    init(name: String, showId: Int, posterPath: String) {
        self.name = name
        self.showId = showId
        self.posterPath = posterPath
        self.description = "N/A"
        self.genres = ["N/A"]
        self.firstAirDate = "N/A"
        self.lastAirDate = "N/A"
        self.numSeasons = -1
        self.cast = ["N/A"]
        self.providers = ["N/A"]
        self.providerLogoPaths = ["N/A"]
        self.episodesPerSeason = [-1]
        self.preview = true
        self.watchingStatus = WatchingStatus(season: 1, episode: 1)
    }
    
    // prints details on TV show to console
    func printDetails() {
            print("TV Show Details:")
            print("Name: \(name)")
            print("ShowId: \(showId)")
            print("Description: \(description)")
            print("Genres: \(genres)")
            print("First air date: \(firstAirDate)")
            print("Last air date: \(lastAirDate)")
            print("Number of Seasons: \(numSeasons)")
            print("Poster Path: \(posterPath)")
            print("Cast: \(cast)")
            print("Providers: \(providers)")
            print("Provider Logo Paths: \(providerLogoPaths)")
            print("Is Search Preview: \(preview)")
    }
    
    // Create from Firestore document
    static func fromDictionary(_ dict: [String: Any]) -> TVShow? {
        guard let showId = dict["showId"] as? Int,
              let name = dict["name"] as? String,
              let posterPath = dict["posterPath"] as? String else {
            return nil
        }
        
        var show = TVShow(name: name, showId: showId, posterPath: posterPath)
        
        // Optional fields
        show.description = dict["description"] as? String ?? "N/A"
        show.genres = dict["genres"] as? [String] ?? ["N/A"]
        show.firstAirDate = dict["firstAirDate"] as? String ?? "N/A"
        show.lastAirDate = dict["lastAirDate"] as? String ?? "N/A"
        show.numSeasons = dict["numSeasons"] as? Int ?? -1
        show.cast = dict["cast"] as? [String] ?? ["N/A"]
        show.providers = dict["providers"] as? [String] ?? ["N/A"]
        show.providerLogoPaths = dict["providerLogoPaths"] as? [String] ?? ["N/A"]
        show.episodesPerSeason = dict["episodesPerSeason"] as? [Int] ?? [-1]
        show.preview = dict["preview"] as? Bool ?? true
        
        if let statusDict = dict["watchingStatus"] as? [String: Any],
           let season = statusDict["season"] as? Int,
           let episode = statusDict["episode"] as? Int {
            show.watchingStatus = WatchingStatus(season: season, episode: episode)
        }
        
        return show
    }
}

// Collection references
extension TVShow {
    static func watchingCollection(userId: String) -> CollectionReference {
        return Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("watching")
    }
    
    static func wishlistCollection(userId: String) -> CollectionReference {
        return Firestore.firestore()
            .collection("users")
            .document(userId)
            .collection("wish")
    }
}
