//
//  CreateAccountVC.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/11/24.
//

import UIKit
import Firebase
import FirebaseAuth
// needs an import statement

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
        if(((emailTextField.text?.isEmpty) != nil) || ((usernameTextField.text?.isEmpty) != nil) || ((passwordText.text?.isEmpty) != nil) || ((confirmPasswordText.text?.isEmpty) != nil)) {
            errorMessage.text! = "Please fill out all fields."
            return
        }
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
                    
                    /*guard let uid = authResult?.user.uid else {return}
                    let userRef = Database.database().reference().child("users").child(uid)
                    let userData = ["username": usernameTextField.text, "email": emailTextField.text!]
                    userRef.setValue(userData) {
                        (error, ref) in
                        if let error = error {
                            errorMessage.text = "failed to save user data"
                        } else {
                            return
                        }
                    }*/
                }
            }
    }
}
