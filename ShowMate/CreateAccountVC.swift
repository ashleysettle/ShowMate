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
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: self.createSegueIdentifier, sender: nil)
                self.emailTextField.text = nil
                self.passwordText.text = nil
                self.confirmPasswordText.text = nil
                self.confirmPasswordText.text = nil
                self.usernameTextField.text = nil
                self.errorMessage.text = nil
            }
        }
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == createSegueIdentifier,
//           let nextVC = segue.destination as? LandingVC {
//            nextVC.delegate = self
//        }
//    }

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
        Auth.auth().createUser(withEmail: emailTextField.text!, password: emailTextField.text!) {
            (authResult,error) in
            if let error = error as NSError? {
                self.errorMessage.text = "\(error.localizedDescription)"
            }else {
                self.errorMessage.text = ""
            }
        }
    }
}
