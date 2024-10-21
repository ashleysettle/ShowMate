//
//  ViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/9/24.
//

import UIKit
import FirebaseAuth

class ViewController: UIViewController {

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    
    let createAccountSegueIdentifier = "CreateAccountSegue"
    let signInSegueIdentifier = "SignInSegue"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    //dont need to add sign in and create account button actions bc they will be segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == createAccountSegueIdentifier,
           let nextVC = segue.destination as? CreateAccountVC {
            nextVC.delegate = self
        }
        if segue.identifier == signInSegueIdentifier,
           let nextVC = segue.destination as? LandingVC {
            nextVC.delegate = self
        }
    }
    @IBAction func signInPressed(_ sender: Any) {
        Auth.auth().signIn(withEmail: usernameTextField.text!, password: passwordTextField.text!){
                    (authResult,error) in
                    if let error = error as NSError? {
                        self.errorMessage.text = "\(error.localizedDescription)"
                    }else {
                        self.errorMessage.text = ""
                    }
                }
    }
    
}

