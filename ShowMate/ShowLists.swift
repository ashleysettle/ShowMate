//
//  ShowLists.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/31/24.
//

import Foundation

struct WatchingShow {
    let showId: Int
    let name: String
    let posterPath: String
    let numSeasons: Int
    let status: ShowStatus
    
    struct ShowStatus {
        let season: Int
        let episode: Int
        
        var toDictionary: [String: Any] {
            return [
                "season": season,
                "episode": episode
            ]
        }
        
        static func fromDictionary(_ dict: [String: Any]) -> ShowStatus? {
            guard let season = dict["season"] as? Int,
                  let episode = dict["episode"] as? Int else {
                return nil
            }
            return ShowStatus(season: season, episode: episode)
        }
    }
    
    var toDictionary: [String: Any] {
        return [
            "showId": showId,
            "name": name,
            "posterPath": posterPath,
            "numSeasons": numSeasons,
            "status": status.toDictionary
        ]
    }
    
    
    
    static func fromDictionary(_ dict: [String: Any]) -> WatchingShow? {
        guard let showId = dict["showId"] as? Int,
              let name = dict["name"] as? String,
              let posterPath = dict["posterPath"] as? String,
              let numSeasons = dict["numSeasons"] as? Int,
              let statusDict = dict["status"] as? [String: Any],
              let status = ShowStatus.fromDictionary(statusDict) else {
            return nil
        }
        
        return WatchingShow(
            showId: showId,
            name: name,
            posterPath: posterPath,
            numSeasons: numSeasons,
            status: status
        )
    }
}

struct WishShow {
    let showId: Int
    let name: String
    let posterPath: String
    let providerNames: [String]
    
    var toDictionary: [String: Any] {
        return [
            "showId": showId,
            "name": name,
            "posterPath": posterPath,
            "providerNames": providerNames
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> WishShow? {
        guard let showId = dict["showId"] as? Int,
              let name = dict["name"] as? String,
              let posterPath = dict["posterPath"] as? String,
              let providerNames = dict["providerNames"] as? [String] else {
            return nil
        }
        
        return WishShow(
            showId: showId,
            name: name,
            posterPath: posterPath,
            providerNames: providerNames
        )
    }
}
