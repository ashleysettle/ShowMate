//
//  StatusUpdateViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class StatusUpdateViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextViewDelegate {
    
    var delegate:UIViewController!
    var show: TVShow!
    
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var posterView: UIImageView!
    
    @IBOutlet weak var shareSegmentedControl: UISegmentedControl!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var seasonPicker: UIPickerView!
    @IBOutlet weak var episodePicker: UIPickerView!
    
    private var selectedSeason: Int = 1
    private var selectedEpisode: Int = 1
    
    let placeholderText = "(optional)"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        seasonPicker.delegate = self
        seasonPicker.dataSource = self
        episodePicker.delegate = self
        episodePicker.dataSource = self
        if show != nil {
            if let status = show.watchingStatus {
                selectedSeason = status.season
                selectedEpisode = status.episode
            }
            
            print("current status \(selectedSeason) \(selectedEpisode)")
            let seasonIndex = max(0, selectedSeason - 1)
            let episodeIndex = max(0, selectedEpisode - 1)
            seasonPicker.selectRow(seasonIndex, inComponent: 0, animated: false)
            episodePicker.selectRow(episodeIndex, inComponent: 0, animated: false)
            
            // Force reload of episode picker for initial setup
            episodePicker.reloadAllComponents()
            updateUI()
        }
    }
    
    private func updateUI() {
        guard let show = show else { return }
        showTitleLabel.text = show.name
        loadPosterImage()
        shareSegmentedControl.selectedSegmentIndex = 1
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
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
    
    private func loadPosterImage() {
        let baseURL = "https://image.tmdb.org/t/p/w500"
        let imageURLString = show!.posterPath.hasPrefix("http") ? show!.posterPath : baseURL + show!.posterPath
        
        guard let url = URL(string: imageURLString) else {
            print("Invalid URL: \(show!.posterPath)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("Error creating image from data")
                return
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self?.posterView.image = image
            }
        }.resume()
        self.posterView.layer.cornerRadius = 30
        self.posterView.clipsToBounds = true
        
    }
    
    @IBAction func segmentedChanged(_ sender: UISegmentedControl) {
        let isSharing = sender.selectedSegmentIndex == 0
        UIView.animate(withDuration: 0.3) {
            self.textView.alpha = isSharing ? 1.0 : 0.0
        }
        
        if !isSharing {
            textView.text = placeholderText
            textView.textColor = .placeholderText
        }
    }
            
    // MARK: - UITextViewDelegate
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholderText {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text = placeholderText
            textView.textColor = .placeholderText
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == seasonPicker {
            return show.numSeasons
        }else {
            let seasonIndex = max(0, selectedSeason - 1)
            return seasonIndex < show.episodesPerSeason.count ? show.episodesPerSeason[seasonIndex] : 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row + 1)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == seasonPicker {
            selectedSeason = row + 1
            // Reset episode selection when season changes
            selectedEpisode = 1
            episodePicker.reloadAllComponents()
            episodePicker.selectRow(0, inComponent: 0, animated: true)
        } else {
            selectedEpisode = row + 1
        }
    }
    
    @IBAction func saveProgressButton(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("error")
            return
        }
        guard let userId = Auth.auth().currentUser?.uid,
              let updatedShow = show else { return }
        
        updatedShow.watchingStatus = TVShow.WatchingStatus(season: selectedSeason, episode: selectedEpisode)
        
        let watchingRef = TVShow.watchingCollection(userId: userId)
            .document(String(updatedShow.showId))
        
        let isSharing = shareSegmentedControl.selectedSegmentIndex == 0
        
        if isSharing {
            let message = textView.text == placeholderText ? nil : textView.text
                        
            let statusUpdate = StatusUpdate(
                id: UUID().uuidString,
                userId: userId,
                username: (Auth.auth().currentUser?.displayName)!,
                showId: updatedShow.showId,
                showName: updatedShow.name,
                posterPath: updatedShow.posterPath,
                season: selectedSeason,
                episode: selectedEpisode,
                message: message,
                timestamp: Date(),
                likes: 0,
                likedBy: []
            )
            
            // Use a batch write to update both documents atomically
            let batch = Firestore.firestore().batch()
            
            // Update show progress
            batch.setData(updatedShow.toDictionary, forDocument: watchingRef)
            
            // Create status update
            let statusRef = StatusUpdate.statusUpdatesCollection().document()
            batch.setData(statusUpdate.toDictionary, forDocument: statusRef)
            
            batch.commit { [weak self] error in
                if let error = error {
                    print("Error updating show and creating status: \(error)")
                } else {
                    self?.dismiss(animated: true)
                }
            }
        } else {
            watchingRef.setData(updatedShow.toDictionary) { [weak self] error in
                if let error = error {
                    print("Error updating show status: \(error)")
                } else {
                    self?.dismiss(animated: true)
                }
            }
        }
    }
    @IBAction func finishedButton(_ sender: Any) {
        let controller = UIAlertController(
            title: "\(show.name)",
            message: "You finished \(show.name)?",
            preferredStyle: .alert)
        
//        controller.addTextField() {
//            (textField) in textField.placeholder = "What did you think?"
//        }
        
        controller.addAction(UIAlertAction(
            title: "Save to Seen",
            style: .default) { [weak self] (action) in
                guard let self = self,
                      let userId = Auth.auth().currentUser?.uid,
                      let review = controller.textFields?[0].text else {
                    return
                }
                
                // Create a copy of the show with the review
                let updatedShow = self.show!
                updatedShow.review = review
                
                // Get references to both collections
                let seenRef = TVShow.seenCollection(userId: userId)
                    .document(String(updatedShow.showId))
                let watchingRef = TVShow.watchingCollection(userId: userId)
                    .document(String(updatedShow.showId))
                
                // Use a batch write to handle both operations atomically
                let batch = Firestore.firestore().batch()
                
                // Add to seen collection
                batch.setData(updatedShow.toDictionary, forDocument: seenRef)
                
                // Delete from watching collection
                batch.deleteDocument(watchingRef)
                
                // Commit the batch
                batch.commit { error in
                    if let error = error {
                        print("Error moving show to seen: \(error)")
                    } else {
                        print("Successfully moved show to seen list")
                        self.dismiss(animated: true)
                    }
                }
        })
        controller.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel))
        
        present(controller, animated: true)
        
    }
    
    
    
}
