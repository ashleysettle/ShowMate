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
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    
    let createAccountSegueIdentifier = "CreateAccountSegue"
    let signInSegueIdentifier = "SignInSegue"
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: self.signInSegueIdentifier, sender: nil)
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
            }
        }
    }

    @IBAction func createAccountPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "Get Started",
            message: "Create an account",
            preferredStyle: .alert)
        alert.addTextField() { (tfDisplayName) in
            tfDisplayName.placeholder = "Enter your username"}
        alert.addTextField() { (tfEmail) in
            tfEmail.placeholder = "Enter your email"}
        alert.addTextField() { (tfPassword) in
            tfPassword.placeholder = "Enter your password"}
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            let displayNameField = alert.textFields![0]
            let emailField = alert.textFields![1]
            let passwordField = alert.textFields![2]
            
            // Create a new user
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { [weak self] (authResult, error) in
                if let error = error as NSError? {
                    self?.errorMessage.text = "\(error.localizedDescription)"
                } else {
                    // Successfully created user, now set the display name
                    let changeRequest = authResult?.user.createProfileChangeRequest()
                    changeRequest?.displayName = displayNameField.text
                    
                    changeRequest?.commitChanges { (error) in
                        if let error = error {
                            self?.errorMessage.text = "\(error.localizedDescription)"
                        } else {
                            self?.errorMessage.text = ""
                            // Display name updated successfully
                        }
                    }
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        present(alert, animated: true)
    }
    
    @IBAction func signInPressed(_ sender: Any) {
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!){
                    (authResult,error) in
                    if let error = error as NSError? {
                        self.errorMessage.text = "\(error.localizedDescription)"
                    }else {
                        self.errorMessage.text = ""
                    }
                }
    }
    
}

