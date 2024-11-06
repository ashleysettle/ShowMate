//
//  SettingsViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/16/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var curUsername: UILabel!
    @IBOutlet weak var segmentedVisibility: UISegmentedControl!
    private let db = Firestore.firestore()
    var delegate:UIViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDisplayName()
        setupVisibilityControl()
        
        // Add authentication state listener
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            self?.updateDisplayName()
            self?.loadVisibilitySetting()
        }
        if let user = Auth.auth().currentUser {
            let displayName = user.displayName
            curUsername.text = "Current Username: \(displayName!)"
        }
    }
    
    // Function to make the username appear and update
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
    }
    
    // Updates the username
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
    }

    // Logs the user out of the app
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            self.dismiss(animated: true)
        } catch {
            print("Sign out error")
        }
    }
    
    // An alert that allows the user to change username
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
            
            // updates the display name in the app
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
    
    // Function to change the name that displays in the corner of the app
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
    
    // Function that creates an error alert
    private func showError(message: String) {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
    }
    
    private func setupVisibilityControl() {
        segmentedVisibility.addTarget(self,
                                    action: #selector(visibilityChanged),
                                    for: .valueChanged)
        loadVisibilitySetting()
    }
    
    private func loadVisibilitySetting() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            if let document = document, document.exists {
                let isPrivate = document.data()?["isPrivate"] as? Bool ?? false
                DispatchQueue.main.async {
                    self?.segmentedVisibility.selectedSegmentIndex = isPrivate ? 1 : 0
                }
            } else {
                // Set default visibility to public if no setting exists
                self?.updateVisibilitySetting(isPrivate: false)
            }
        }
    }
    
    @objc private func visibilityChanged() {
        let isPrivate = segmentedVisibility.selectedSegmentIndex == 1
        updateVisibilitySetting(isPrivate: isPrivate)
    }
    
    private func updateVisibilitySetting(isPrivate: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).setData([
            "isPrivate": isPrivate,
            "lastUpdated": FieldValue.serverTimestamp()
        ], merge: true) { [weak self] error in
            if let error = error {
                self?.showError(message: "Failed to update visibility: \(error.localizedDescription)")
            }
        }
    }
}
