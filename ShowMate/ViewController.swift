// ViewController.swift
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
        
        // Only check auth state on cold launch
        if let user = Auth.auth().currentUser {
            self.performSegue(withIdentifier: self.signInSegueIdentifier, sender: nil)
        }
        
        // Listen for auth state changes
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if user != nil {
                self?.emailTextField.text = nil
                self?.passwordTextField.text = nil
            }
        }
    }

    @IBAction func createAccountPressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "Get Started",
            message: "Create an account",
            preferredStyle: .alert)
        
        alert.addTextField { (tfDisplayName) in
            tfDisplayName.placeholder = "Enter your username"
        }
        alert.addTextField { (tfEmail) in
            tfEmail.placeholder = "Enter your email"
        }
        alert.addTextField { (tfPassword) in
            tfPassword.placeholder = "Enter your password"
            tfPassword.isSecureTextEntry = true  // Hide password
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            
            let displayNameField = alert.textFields![0]
            let emailField = alert.textFields![1]
            let passwordField = alert.textFields![2]
            
            // Create a new user
            Auth.auth().createUser(withEmail: emailField.text!, password: passwordField.text!) { [weak self] (authResult, error) in
                if let error = error as NSError? {
                    self?.errorMessage.text = "\(error.localizedDescription)"
                } else {
                    // Set display name
                    let changeRequest = authResult?.user.createProfileChangeRequest()
                    changeRequest?.displayName = displayNameField.text
                    
                    changeRequest?.commitChanges { [weak self] (error) in
                        if let error = error {
                            self?.errorMessage.text = "\(error.localizedDescription)"
                        } else {
                            self?.errorMessage.text = ""
                            self?.performSegue(withIdentifier: self?.signInSegueIdentifier ?? "", sender: nil)
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
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            errorMessage.text = "Please enter both email and password"
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error as NSError? {
                self?.errorMessage.text = "\(error.localizedDescription)"
            } else {
                self?.errorMessage.text = ""
                // After successful sign in
                self?.performSegue(withIdentifier: self?.signInSegueIdentifier ?? "", sender: nil)

                // Change to:
                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    sceneDelegate.checkAuthAndSetRootViewController()
                }
            }
        }
    }
}
