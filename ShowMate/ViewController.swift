//
//  ViewController.swift
import UIKit
import FirebaseAuth
import FirebaseFirestore

class ViewController: UIViewController, UITextFieldDelegate {
    // Fields for inputting login information
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var errorMessage: UILabel!
    
    // Variable names for segues
    let createAccountSegueIdentifier = "CreateAccountSegue"
    let signInSegueIdentifier = "SignInSegue"
    
    // Instance of UserManager to handle Firestore interactions
    private let userManager = UserManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.delegate = self
        emailTextField.delegate = self
        
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
    
    // Called when 'return' key pressed

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // Called when the user clicks on the view outside of the UITextField

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    // Function for create account alert
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
            tfPassword.isSecureTextEntry = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self,
                  let displayName = alert.textFields?[0].text, !displayName.isEmpty,
                  let email = alert.textFields?[1].text, !email.isEmpty,
                  let password = alert.textFields?[2].text, !password.isEmpty else {
                self?.errorMessage.text = "Please fill in all fields"
                return
            }
            
            // First create the user in Firebase Auth
            Auth.auth().createUser(withEmail: email, password: password) { [weak self] (authResult, error) in
                guard let self = self else { return }
                
                if let error = error as NSError? {
                    DispatchQueue.main.async {
                        self.errorMessage.text = "\(error.localizedDescription)"
                    }
                    return
                }
                
                guard let userId = authResult?.user.uid else {
                    DispatchQueue.main.async {
                        self.errorMessage.text = "Failed to get user ID"
                    }
                    return
                }
                
                print("Created user with ID: \(userId)")
                
                // Update display name
                let changeRequest = authResult?.user.createProfileChangeRequest()
                changeRequest?.displayName = displayName
                
                changeRequest?.commitChanges { [weak self] (error) in
                    guard let self = self else { return }
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            self.errorMessage.text = "Error setting display name: \(error.localizedDescription)"
                        }
                        return
                    }
                    
                    // Add user to Firestore
                    Task {
                        do {
                            try await self.userManager.addUserToFirestore(
                                userId: userId,
                                username: displayName
                            )
                            
                            print("Successfully added user to Firestore with ID: \(userId)")
                            
                            await MainActor.run {
                                self.errorMessage.text = ""
                                self.performSegue(withIdentifier: self.signInSegueIdentifier, sender: nil)
                                
                                // Update root view controller
                                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                                    sceneDelegate.checkAuthAndSetRootViewController()
                                }
                            }
                        } catch {
                            await MainActor.run {
                                self.errorMessage.text = "Error adding user to Firestore: \(error.localizedDescription)"
                                print("Firestore error: \(error)")
                            }
                        }
                    }
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true)
    }
    
    // Function to sign the user in
    @IBAction func signInPressed(_ sender: Any) {
        // Check to ensure that all fields are complete
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            errorMessage.text = "Please enter both email and password"
            return
        }
        
        // Connects to Firebase to log user in
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] (authResult, error) in
            if let error = error as NSError? {
                self?.errorMessage.text = "\(error.localizedDescription)"
            } else {
                self?.errorMessage.text = ""
                // After successful sign in, perform segue
                self?.performSegue(withIdentifier: self?.signInSegueIdentifier ?? "", sender: nil)

                // Set the root view controller after sign-in
                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate {
                    sceneDelegate.checkAuthAndSetRootViewController()
                }
            }
        }
    }
}


