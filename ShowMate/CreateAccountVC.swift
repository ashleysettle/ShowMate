//
//  CreateAccountVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit
import FirebaseAuth

class CreateAccountVC: UIViewController {
    
    var delegate: UIViewController!
    var createSegueIdentifier = "CreateAccountSegue"
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var confirmPasswordText: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var usernameTextField: UITextField!
    
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

    @IBAction func createAccountPressed(_ sender: Any) {
        // need to add username to createUser
        if(passwordText.text != confirmPasswordText.text){
            errorMessage.text = "Passwords do not match!"
            return
        }
        // create a new user
        Auth.auth().createUser(withEmail: emailTextField.text!, password: passwordText.text!) {
                (authResult,error) in
                if let error = error as NSError? {
                    self.errorMessage.text = "\(error.localizedDescription)"
                }else {
                    self.errorMessage.text = ""
                }
            }
    }
}
