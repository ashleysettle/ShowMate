
import UIKit
import FirebaseAuth
import FirebaseFirestore

class ShowDetailViewController: UIViewController {
    // MARK: - Outlets
    @IBOutlet weak var showTitleLabel: UILabel!
    @IBOutlet weak var showImageView: UIImageView!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var providerLabel: UILabel!
    @IBOutlet weak var lastAirDate: UILabel!
    @IBOutlet weak var firstAirDate: UILabel!
    @IBOutlet weak var numberOfSeasons: UILabel!
    @IBOutlet weak var genreLabel: UILabel!
    @IBOutlet weak var currentlyWatchingButton: UIButton!
    @IBOutlet weak var watchlistButton: UIButton!
    
    // MARK: - Properties
    var show: TVShow!
    weak var delegate: ShowListUpdateDelegate?
    private var isInWatchingList = false
    private var isInWishlist = false
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        checkShowStatus()
    }
    
    // MARK: - UI Configuration
    private func configureUI() {
        guard let show = show else { return }
        
        showTitleLabel.text = show.name
        descriptionTextView.text = show.description
        //showDescriptionLabel.sizeToFit()
        
        providerLabel.text = "\(show.providers.joined(separator: ", "))"
        //providerLabel.text = "Where to Watch: \(show.providers.joined(separator: ", "))"
        genreLabel.text = "\(show.genres.joined(separator: ", "))"
        //genreLabel.text = "Genres: \(show.genres.joined(separator: ", "))"
        genreLabel.sizeToFit()
        
        numberOfSeasons.text = "Number of Seasons: \(show.numSeasons)"
        firstAirDate.text = "First Air Date: \(show.firstAirDate)"
        lastAirDate.text = "Last Air Date: \(show.lastAirDate)"
        
        loadPosterImage()
        updateButtonStates()
    }
    
    private func loadPosterImage() {
        guard let url = URL(string: show.posterPath) else {
            print("Invalid URL: \(show.posterPath)")
            return
        }
        
        showImageView.image = UIImage(systemName: "photo.fill")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                return
            }
            
            guard let data = data,
                  let image = UIImage(data: data) else {
                print("Error creating image from data")
                return
            }
            
            DispatchQueue.main.async {
                self?.showImageView.image = image
            }
        }.resume()
    }
    
    private func updateButtonStates() {
        currentlyWatchingButton.tintColor = isInWatchingList ? .gray : .systemBlue
        watchlistButton.tintColor = isInWishlist ? .gray : .systemBlue
    }
    
    // MARK: - Show Status Checking
    private func checkShowStatus() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let group = DispatchGroup()
        
        // Check watching status
        group.enter()
        TVShow.watchingCollection(userId: userId)
            .document(String(show.showId))
            .getDocument { [weak self] document, error in
                self?.isInWatchingList = document?.exists ?? false
                group.leave()
            }
        
        // Check wishlist status
        group.enter()
        TVShow.wishlistCollection(userId: userId)
            .document(String(show.showId))
            .getDocument { [weak self] document, error in
                self?.isInWishlist = document?.exists ?? false
                group.leave()
            }
        
        group.notify(queue: .main) { [weak self] in
            self?.updateButtonStates()
        }
    }
    
    // MARK: - Button Actions
    @IBAction func currentlyWatchingButtonTapped(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let watchingRef = TVShow.watchingCollection(userId: userId)
            .document(String(show.showId))
        
        if isInWatchingList {
            // Remove from watching list
            watchingRef.delete { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error removing show: \(error)")
                    return
                }
                
                self.isInWatchingList = false
                self.delegate?.showRemovedFromWatching(self.show)
                
                DispatchQueue.main.async {
                    self.updateButtonStates()
                }
            }
        } else {
            // Add to watching list
            var updatedShow = show
            updatedShow!.watchingStatus = TVShow.WatchingStatus(season: 1, episode: 1)
            
            watchingRef.setData(updatedShow!.toDictionary) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error adding show: \(error)")
                    return
                }
                
                self.isInWatchingList = true
                self.delegate?.showAddedToWatching(updatedShow!)
                
                DispatchQueue.main.async {
                    self.updateButtonStates()
                }
            }
        }
    }
    
    @IBAction func watchlistButtonTapped(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let wishRef = TVShow.wishlistCollection(userId: userId)
            .document(String(show.showId))
        
        if isInWishlist {
            // Remove from wishlist
            wishRef.delete { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error removing show from wishlist: \(error)")
                    return
                }
                
                self.isInWishlist = false
                self.delegate?.showRemovedFromWishlist(self.show)
                
                DispatchQueue.main.async {
                    self.updateButtonStates()
                }
            }
        } else {
            // Add to wishlist
            wishRef.setData(show.toDictionary) { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error adding show to wishlist: \(error)")
                    return
                }
                
                self.isInWishlist = true
                self.delegate?.showAddedToWishlist(self.show)
                
                DispatchQueue.main.async {
                    self.updateButtonStates()
                }
            }
        }
    }
}
