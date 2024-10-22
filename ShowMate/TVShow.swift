//
//  TVShow.swift
//  ShowMate
//
//  Created by Victoria Plaxton on 10/22/24.
//

class TVShow {
    var name: String
    var description: String
    var genres: [String]
    var firstAirDate: String
    var lastAirDate: String
    var numSeasons: Int
    var posterPath: String
    var cast: [String]
    var providers: [String]
    
    init(name: String, description: String, genres: [String], firstAirDate: String, lastAirDate: String, numSeasons: Int, posterPath: String, cast: [String], providers: [String]) {
        self.name = name
        self.description = description
        self.genres = genres
        self.firstAirDate = firstAirDate
        self.lastAirDate = lastAirDate
        self.numSeasons = numSeasons
        self.posterPath = posterPath
        self.cast = cast
        self.providers = providers
    }
}
