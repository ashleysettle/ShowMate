//
//  SettingsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/16/24.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var curUsername: UILabel!
    var delegate:UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        if let user = Auth.auth().currentUser {
            let displayName = user.displayName
            curUsername.text = "Current Username: \(displayName!)"
            
        }
        // Do any additional setup after loading the view.
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true)
        } catch {
            print("Sign out error")
        }
    }
    @IBAction func changeUsernamePressed(_ sender: Any) {
        let alert = UIAlertController(
            title: "Change Username",
            message: "Enter your new  username",
            preferredStyle: .alert)
        
        alert.addTextField { textField in
            // Pre-fill with current display name
            textField.placeholder = "Enter new username"
            textField.text = Auth.auth().currentUser?.displayName
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let newDisplayName = alert.textFields?[0].text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newDisplayName.isEmpty else {
                self?.showError(message: "Please enter a valid display name")
                return
            }
            
            self?.changeDisplayName(newDisplayName: newDisplayName) { error in
                if let error = error {
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        present(alert, animated: true)
    }
    
    func changeDisplayName(newDisplayName: String, completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"]))
            return
        }
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = newDisplayName
        
        changeRequest.commitChanges { error in
            completion(error)
        }
        curUsername.text = "Current Username: \(newDisplayName)"
    }
    
    private func showError(message: String) {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    

}
