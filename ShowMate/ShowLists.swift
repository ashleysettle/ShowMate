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
    
    var toDictionary: [String: Any] {
        return [
            "showId": showId,
            "name": name,
            "posterPath": posterPath
        ]
    }
    
    static func fromDictionary(_ dict: [String: Any]) -> WatchingShow? {
        guard let showId = dict["showId"] as? Int,
              let name = dict["name"] as? String,
              let posterPath = dict["posterPath"] as? String else {
            return nil
        }
        return WatchingShow(showId: showId, name: name, posterPath: posterPath)
    }
}
