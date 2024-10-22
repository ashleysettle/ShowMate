//
//  LandingVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit
import FirebaseAuth

class LandingVC: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    
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
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
}
