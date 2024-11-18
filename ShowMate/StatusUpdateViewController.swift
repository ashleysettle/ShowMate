//
//  StatusUpdateViewController.swift
//  ShowMate
//
//  Created by Sydney Schrader on 11/11/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class StatusUpdateViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var delegate:UIViewController!
    var show: TVShow!
    
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var posterView: UIImageView!
    
    @IBOutlet weak var seasonPicker: UIPickerView!
    @IBOutlet weak var episodePicker: UIPickerView!
    
    private var selectedSeason: Int = 1
    private var selectedEpisode: Int = 1
    
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
        
        watchingRef.setData(updatedShow.toDictionary) { [weak self] error in
            if let error = error {
                print("Error updating show status: \(error)")
            } else {
                self?.dismiss(animated: true)
            }
        }
    }
    
}
