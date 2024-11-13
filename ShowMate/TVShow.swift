//
//  TVShow.swift
//  ShowMate
//
//  Created by Victoria Plaxton on 10/22/24.
//

class TVShow {
    var name: String
    var showId: Int
    var description: String
    var genres: [String]
    var firstAirDate: String
    var lastAirDate: String
    var numSeasons: Int
    var posterPath: String
    var cast: [String]
    var providers: [String]
    var providerLogoPaths: [String]
    var episodesPerSeason: [Int] // length of array = num seasons
    var preview: Bool // true indicates only a search result, not added by user
    
    init(name: String, showId: Int, description: String, genres: [String], firstAirDate: String, lastAirDate: String, numSeasons: Int, posterPath: String, cast: [String], providers: [String], providerLogoPaths: [String], episodesPerSeason: [Int]) {
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
}
