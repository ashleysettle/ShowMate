//
//  CreateAccountVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit

class CreateAccountVC: UIViewController {
    
    var delegate: UIViewController!
    var createSegueIdentifier = "CreateAccountSegue"

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == createSegueIdentifier,
           let nextVC = segue.destination as? LandingVC {
            nextVC.delegate = self
        }
    }

}
