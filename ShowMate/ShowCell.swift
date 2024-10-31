//
//  ShowCell.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/23/24.
//

import UIKit
// ShowCell.swift

class ShowCell: UICollectionViewCell {
    
    @IBOutlet weak var showPosterImage: UIImageView! {
        didSet {
            setupUI()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        // Content view setup
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        // Image view setup
        showPosterImage.contentMode = .scaleToFill
        showPosterImage.clipsToBounds = true
        showPosterImage.layer.cornerRadius = 10
        showPosterImage.layer.masksToBounds = true
        
        // Add shadow to cell
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 5
        layer.masksToBounds = false
        
        // This ensures the shadow appears with the rounded corners
        layer.cornerRadius = 10
    }
    
    // Update configure method to handle URLs
    func configure(with posterUrl: String) {
        // Show a loading state or placeholder while image loads
        showPosterImage.image = UIImage(named: "placeholder") // Optional: add a placeholder image
        
        guard let url = URL(string: posterUrl) else {
            print("Invalid URL: \(posterUrl)")
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  error == nil,
                  let image = UIImage(data: data) else {
                print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                self.showPosterImage.image = image
            }
        }.resume()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        showPosterImage?.image = nil
    }
}
