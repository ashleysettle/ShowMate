//
//  StatusUpdate.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/21/24.
//

import Foundation
import FirebaseFirestore

struct StatusUpdate {
    let id: String
    let userId: String
    let username: String
    let showId: Int
    let showName: String
    let posterPath: String
    let season: Int
    let episode: Int
    let message: String?
    let timestamp: Date
    
    var toDictionary: [String: Any] {
        var dict: [String: Any] = [
            "userId": userId,
            "username": username,
            "showId": showId,
            "showName": showName,
            "posterPath": posterPath,
            "season": season,
            "episode": episode,
            "timestamp": timestamp
        ]
        
        if let message = message {
            dict["message"] = message
        }
        
        return dict
    }
    
    static func fromDictionary(_ dict: [String: Any], id: String) -> StatusUpdate? {
        guard let userId = dict["userId"] as? String,
              let username = dict["username"] as? String,
              let showId = dict["showId"] as? Int,
              let showName = dict["showName"] as? String,
              let posterPath = dict["posterPath"] as? String,
              let season = dict["season"] as? Int,
              let episode = dict["episode"] as? Int,
              let timestamp = dict["timestamp"] as? Timestamp else {
            return nil
        }
        
        return StatusUpdate(
            id: id,
            userId: userId,
            username: username,
            showId: showId,
            showName: showName,
            posterPath: posterPath,
            season: season,
            episode: episode,
            message: dict["message"] as? String,
            timestamp: timestamp.dateValue()
        )
    }
    
    static func statusUpdatesCollection() -> CollectionReference {
        return Firestore.firestore().collection("status_updates")
    }
}
