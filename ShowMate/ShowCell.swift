//
//  ShowCell.swift
//  ShowMate
//
//  Created by Sydney Schrader on 10/23/24.
//

import UIKit
// ShowCell.swift

class ShowCell: UICollectionViewCell {
    @IBOutlet weak var showPosterImage: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }
    
    private func setupUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        
        showPosterImage.contentMode = .scaleToFill
        showPosterImage.clipsToBounds = true
        showPosterImage.layer.cornerRadius = 10
        showPosterImage.layer.masksToBounds = true
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 5
        layer.masksToBounds = false
        
        layer.cornerRadius = 10
    }
    
    func configure(with posterUrl: String) {
        guard let url = URL(string: posterUrl) else {
            print("Invalid URL: \(posterUrl)")
            return
        }
        
        showPosterImage.image = UIImage(systemName: "photo.fill")
        
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
        showPosterImage.image = nil
    }
}
