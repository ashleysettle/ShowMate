//
//  ShowDetailViewController.swift
//  ShowMate
//
//  Created by Victoria Plaxton on 10/22/24.
//

import UIKit
import FirebaseAuth

class ShowDetailViewController: UIViewController {
    
    // TODO: add back button
    
    // Outlets
    @IBOutlet weak var usernameLabel: UILabel!
    
    // LET SHOW HERE
    // dummy for now
    let show = TVShow(name: "The Office", showId: 1234, description: "Dunder mifflin happenings", genres: ["comedy", "romance"], firstAirDate: "Spring 2000", lastAirDate: "Fall 2010", numSeasons: 9, posterPath: "temp path", cast: ["Michael", "Ryan", "Jim"], providers: ["providers here"], providerLogoPaths: ["dummy"])
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        updateDisplayName()
//        
//        // Add authentication state listener
//        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
//            self?.updateDisplayName()
//        }
        printStats()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // updateDisplayName()
    }
    
    // Update display name based on user authentication
    // TODO: do we need to add username label?
//    private func updateDisplayName() {
//        if let user = Auth.auth().currentUser {
//            usernameLabel.text = user.displayName
//        } else {
//            usernameLabel.text = "N/A"
//        }
//    }
    
    // print stats for show (take in obj)
    private func printStats() {
        show.printDetails()
    }
    
}



