//
//  VTPhotoAlbumCollectionViewController.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 9/4/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit
import CoreData

//AlbumCollectionViewController, displays and manages the photos stored in CoreData
//Extends the CoreDataCollectionViewController with the photo specific behaviour
class VTPhotoAlbumCollectionViewController : CoreDataCollectionViewController, UICollectionViewDelegateFlowLayout {
    
    //Selected pin
    var pin: Pin?
    
    //The controller that holds this one
    var parent: VTPhotoAlbumViewController?
    
    //List with selected photos for deletion
    var selectedPhotos : [Photo] = []

    //Layout
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!


    //Sets up the view
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFlowLayout()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //Returns the cell to be shown for each photo in the Fetched Results Controller
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        //Get photo
        let currentPhoto = fetchedResultsController!.objectAtIndexPath(indexPath) as! Photo
        
        //Create cell
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCollectionViewCell", forIndexPath: indexPath) as! VTPhotoCollectionViewCell
        
        //Rounded borders :)
        cell.layer.cornerRadius = 10
        cell.layer.borderWidth = 2.0
        cell.layer.borderColor = UIColor.clearColor().CGColor
        
        //Reuse saved image
        if let imgData = currentPhoto.img {
            //Reset properties, otherwise reused cells of deleted photos 
            //will show as if they were selected
            cell.layer.borderWidth = 0
            cell.contentView.alpha = 1.0
            cell.layer.borderColor = UIColor.clearColor().CGColor
            cell.activityIndicator.stopAnimating()
            cell.imageView.image = UIImage.init(data: imgData)
        }
        //Show the spinner while downloading
        else {
            cell.imageView.image = nil
            cell.activityIndicator.startAnimating()
        }
        
        return cell
    }
    
    //Returs the footer to show. Size and visibility are updated
    //if images were found (or not) for the selected pin.
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "photoCollectionFooter", forIndexPath: indexPath)
        if kind == UICollectionElementKindSectionFooter {
            if let fc = fetchedResultsController
                where fc.sections?[0].numberOfObjects == 0 && (parent?.attemptedDownload)! {
                footer.hidden = false
                footer.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)
            }
            else {
                footer.hidden = true
                footer.frame = CGRectMake(0, 0, 0, 0)
            }
            
        }
        return footer
    }
    
    //Return size of the footer, depending on whether images were found for the pin
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if let fc = fetchedResultsController
            where fc.sections?[0].numberOfObjects == 0 && (parent?.attemptedDownload)! {
            return  CGSizeMake(320, self.view.frame.size.height);
        }
        else {
            return CGSizeZero
        }
    }
    
    //Configures the flow layout (spacing, item size)
    func setupFlowLayout(){
        let space: CGFloat = 3.0
        let width = (view.frame.size.width - 2*space) / 3.0
        let height = (view.frame.size.height - 3*space) / 7.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSizeMake(width, height)
        
    }
    
    //Shows the 'Remove selected' photos if some have been selected.
    //Otherwise, shows the 'Load new collection' button.
    func toggleButtonsForSelectedItems(){
        if selectedPhotos.count > 0 && (parent?.newCollectionButton.enabled)! {
            parent?.toggleButtons(showNewCollectionButton: false)
        }
        else if selectedPhotos.count == 0 && !(parent?.newCollectionButton.enabled)! {
            parent?.toggleButtons(showNewCollectionButton: true)
        }
    }
    
    //Keeps track of selected items
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let photo = fetchedResultsController!.objectAtIndexPath(indexPath) as! Photo
        let cell = collectionView.cellForItemAtIndexPath(indexPath)
        //Remove from selection and restore cell if already selected
        if selectedPhotos.contains(photo) {
            cell?.layer.borderWidth = 0
            cell?.contentView.alpha = 1.0
            cell?.layer.borderColor = UIColor.clearColor().CGColor
            selectedPhotos.removeAtIndex(selectedPhotos.indexOf(photo)!)
        }
        //Mark cell and store in list of selected photos
        else {
            cell?.layer.borderWidth = 2.0
            cell?.contentView.alpha = 0.5
            cell?.layer.borderColor = UIColor.grayColor().CGColor
            selectedPhotos.append(photo)
        }
        toggleButtonsForSelectedItems()
    }
    
    
    
}