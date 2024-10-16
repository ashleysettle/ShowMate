//
//  LandingVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit

class LandingVC: UIViewController {
    
    @IBOutlet weak var profileButton: UIImageView!
    var delegate:UIViewController!
    let settingsSegueIdentifier = "SettingsIdentifier"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        
        profileButton.addGestureRecognizer(tapGesture)
        profileButton.isUserInteractionEnabled = true
        
    }
    
    @objc func imageTapped() {
        performSegue(withIdentifier: settingsSegueIdentifier, sender: self)
    }

}
