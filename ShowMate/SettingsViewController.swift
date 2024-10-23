//
//  SettingsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/16/24.
//

import UIKit
import FirebaseAuth
//import FirebaseDatabaseInternal

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var curUsername: UILabel!
    @IBOutlet weak var segmentedVisibility: UISegmentedControl!
    var delegate:UIViewController!
    //private var ref: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplayName()
        
        // Add authentication state listener
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
        }
        if let user = Auth.auth().currentUser {
            let displayName = user.displayName
            curUsername.text = "Current Username: \(displayName!)"
            //loadVisibilitySetting(for: user.uid)
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
    }
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }
    
    /*private func loadVisibilitySetting(for uid: String) {
            ref.child("users").child(uid).child("visibility").observeSingleEvent(of: .value) { snapshot in
                if let visibility = snapshot.value as? String {
                    // Set the segmented control's selected index based on the visibility value
                    self.visibilitySegmentedControl.selectedSegmentIndex = (visibility == "public") ? 0 : 1
                }
            }
        }*/
    
    
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
        usernameLabel.text = newDisplayName
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
