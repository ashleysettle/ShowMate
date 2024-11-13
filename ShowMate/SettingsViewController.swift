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
    var delegate: UIViewController!
    
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
            curUsername.text = "Current Username: \(displayName ?? "")"
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDisplayName()
        loadVisibilitySetting()
    }
    
    private func updateDisplayName() {
        if let user = Auth.auth().currentUser {
            usernameLabel.text = user.displayName
        } else {
            usernameLabel.text = "N/A"
        }
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
            message: "Enter your new username",
            preferredStyle: .alert)
        
        alert.addTextField { textField in
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
        
        changeRequest.commitChanges { [weak self] error in
            if let error = error {
                completion(error)
                return
            }
            
            // Update username in Firestore as well
            guard let userId = Auth.auth().currentUser?.uid else { return }
            self?.db.collection("users").document(userId).updateData([
                "username": newDisplayName
            ]) { error in
                if let error = error {
                    print("Error updating username in Firestore: \(error)")
                }
                DispatchQueue.main.async {
                    self?.curUsername.text = "Current Username: \(newDisplayName)"
                    self?.usernameLabel.text = newDisplayName
                }
                completion(error)
            }
        }
    }
    
    private func showError(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func setupVisibilityControl() {
        // Set up segmented control with proper titles
        segmentedVisibility.removeAllSegments()
        segmentedVisibility.insertSegment(withTitle: "Public", at: 0, animated: false)
        segmentedVisibility.insertSegment(withTitle: "Private", at: 1, animated: false)
        
        // Add target for value changed
        segmentedVisibility.addTarget(self,
                                    action: #selector(visibilityChanged),
                                    for: .valueChanged)
        
        loadVisibilitySetting()
    }
    
    private func loadVisibilitySetting() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            
            if let document = document, document.exists {
                // Check for is_public field (snake_case version)
                if let isPublic = document.data()?["is_public"] as? Bool {
                    DispatchQueue.main.async {
                        // If is_public is true, select index 0 (Public)
                        // If is_public is false, select index 1 (Private)
                        self.segmentedVisibility.selectedSegmentIndex = isPublic ? 0 : 1
                    }
                }
            } else {
                // Set default to Public (index 0) if no setting exists
                self.updateVisibilitySetting(isPublic: true)
                DispatchQueue.main.async {
                    self.segmentedVisibility.selectedSegmentIndex = 0
                }
            }
        }
    }
    
    @objc private func visibilityChanged() {
        // selectedSegmentIndex 0 = Public (isPublic = true)
        // selectedSegmentIndex 1 = Private (isPublic = false)
        let isPublic = segmentedVisibility.selectedSegmentIndex == 0
        updateVisibilitySetting(isPublic: isPublic)
    }
    
    private func updateVisibilitySetting(isPublic: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).updateData([
            "is_public": isPublic,
            "lastUpdated": FieldValue.serverTimestamp()
        ]) { [weak self] error in
            if let error = error {
                self?.showError(message: "Failed to update visibility: \(error.localizedDescription)")
            } else {
                print("Successfully updated visibility to: \(isPublic ? "Public" : "Private")")
            }
        }
    }
}
