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
       showPosterImage.contentMode = .scaleToFill  // Changed to scaleToFill
       showPosterImage.clipsToBounds = true
       showPosterImage.layer.cornerRadius = 10  // Added corner radius
       showPosterImage.layer.masksToBounds = true // Ensure corners are clipped
       
       // Add shadow to cell
       layer.shadowColor = UIColor.black.cgColor
       layer.shadowOffset = CGSize(width: 0, height: 4)
       layer.shadowOpacity = 0.3
       layer.shadowRadius = 5
       layer.masksToBounds = false
       
       // This ensures the shadow appears with the rounded corners
       layer.cornerRadius = 10
   }
    
    func configure(with imageName: String) {
        showPosterImage?.image = UIImage(named: imageName)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        showPosterImage?.image = nil
    }
}
