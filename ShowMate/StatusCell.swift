import UIKit
import FirebaseAuth
import FirebaseFirestore

class StatusCell: UICollectionViewCell {
    
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var likes: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var posterImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    var isLiked = false
    var statusId = ""
    
    var onLikePressed: (() -> Void)?    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        setupActions()
    }
    
    private func setupActions() {
        likeButton.addTarget(self, action: #selector(handleLikePressed), for: .touchUpInside)
    }
        
    private func setupUI() {
        // Cell styling
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        // Poster image styling
        posterImageView.contentMode = .scaleAspectFill
        posterImageView.clipsToBounds = true
        posterImageView.layer.cornerRadius = 8
        
        // Text view styling
        messageTextView.backgroundColor = .clear
        messageTextView.isEditable = false
        messageTextView.isScrollEnabled = false
        messageTextView.font = .systemFont(ofSize: 14)
        messageTextView.textContainer.lineFragmentPadding = 0
        messageTextView.textContainerInset = .zero
        messageTextView.textColor = .label
        
        // Label styling
        usernameLabel.font = .boldSystemFont(ofSize: 16)
        statusLabel.font = .systemFont(ofSize: 14)
        timeLabel.font = .systemFont(ofSize: 12)
        timeLabel.textColor = .secondaryLabel

    }
    
    func configure(with status: StatusUpdate) {
        self.statusId = status.id
        // Set username
        usernameLabel.text = status.username
        
        // Create status text with show name
        statusLabel.text = "S:\(status.season) E:\(status.episode)"
        
        if let user = Auth.auth().currentUser {
            isLiked = status.likedBy.contains(user.uid)
        }
        
        let likeImage = isLiked ? UIImage(systemName: "heart.fill"): UIImage(systemName: "heart")
        likeButton.setImage(likeImage, for: .normal)
        likes.text = "\(status.likes)"
        
        // Handle optional message
        if let message = status.message {
            messageTextView.text = message
            messageTextView.isHidden = false
        } else {
            messageTextView.text = nil
            messageTextView.isHidden = true
        }
        
        // Format the time
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        timeLabel.text = formatter.localizedString(for: status.timestamp, relativeTo: Date())
        
        // Load poster image
        loadPosterImage(from: status.posterPath)
    }
    
    private func loadPosterImage(from urlString: String) {
        // Clear existing image first
        posterImageView.image = nil
        
        guard let url = URL(string: urlString) else {
            print("Invalid poster URL: \(urlString)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("Error loading poster image: \(error)")
                return
            }
            
            guard let data = data else {
                print("No image data received")
                return
            }
            
            guard let image = UIImage(data: data) else {
                print("Could not create image from data")
                return
            }
            
            DispatchQueue.main.async {
                // Make sure the cell hasn't been reused
                guard let self = self else { return }
                self.posterImageView.image = image
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.image = nil
        usernameLabel.text = nil
        statusLabel.text = nil
        likes.text = nil
        messageTextView.text = nil
        timeLabel.text = nil
        messageTextView.isHidden = false  // Reset visibility
        statusId = ""
        
    }
    
    
    @objc private func handleLikePressed() {
        onLikePressed?()
    }
    
}
