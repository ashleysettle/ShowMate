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
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    private func addMagnifyingGlass() {
        // image for magnifying glass
        let magnifyingGlassImageView = UIImageView(image: UIImage(systemName: "magnifyingGlass"))
        magnifyingGlassImageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        magnifyingGlassImageView.contentMode = .scaleAspectFit
        searchUsersTextField.leftView = magnifyingGlassImageView
        searchUsersTextField.leftViewMode = .always
                
    }
    


}
