//
//  ProfileViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/18/24.
//

import UIKit

class ProfileViewController: UIViewController {
    
    var user:UserProfile!
    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameLabel.text = user.username
    }

}
