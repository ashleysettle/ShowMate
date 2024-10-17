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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == settingsSegueIdentifier,
           let nextVC = segue.destination as? SettingsViewController {
            
            nextVC.delegate = self
        }
    }
    
    

}
