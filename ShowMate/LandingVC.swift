//
//  LandingVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit

class LandingVC: UIViewController {
    
    var delegate:UIViewController!

    @IBOutlet weak var textLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //obivously not going to keep it like this, just wanted it to do something when you got in
        textLabel.text = "You signed in!"
    }
    
}
