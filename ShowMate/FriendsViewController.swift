//
//  FriendsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/22/24.
//

import UIKit
import FirebaseAuth

class FriendsViewController: UIViewController {
    @IBOutlet weak var searchUsersTextField: UITextField!
    @IBOutlet weak var usernameLabel: UILabel!
    // ScrollView that will be used for friend status later
    @IBOutlet weak var statusScrollView: UIScrollView!
    
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
    
    // Function that updates the display name in the corner
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
}
