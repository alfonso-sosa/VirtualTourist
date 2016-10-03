//
//  VTPhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 9/20/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit

//Cell to display photos in collection view
class VTPhotoCollectionViewCell : UICollectionViewCell {
    
    //The activity indicator, placeholder for images
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    //The imageView to display the flickr photo
    @IBOutlet weak var imageView: UIImageView!
    
}