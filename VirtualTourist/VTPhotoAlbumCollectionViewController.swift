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
    
    //Number of completed downloads, used to determine if a new request can be made
    var downloads = 0
    
    //The 'no photos' label is only shown if an attempt to download has been made.
    var attemptedDownload = false
    
    //Layout
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    //Loads the photos before showing the view
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadPhotos()
    }
    
    //Restores photos from CoreData, tries to download if none are found
    func loadPhotos(){
        if let pin = pin {
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let stack = delegate.stack
            let fr = NSFetchRequest(entityName: "Photo")
            fr.sortDescriptors = []
            fr.predicate = NSPredicate(format: "pin = %@", argumentArray: [pin])
            //Trigger search
            let frc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            fetchedResultsController = frc
            //Request if none are available
            if let sections = frc.sections where sections[0].numberOfObjects == 0 {
                NSLog("no photos, requesting from flickr...")
                downloadPhotos()
            }
        }
    }
    
    //Inits the map with Flickr arguments
    func getFlickrRequestArguments() -> [String: String!] {
        let methodArguments: [String: String!] = [
            "method": VTClient.Constants.METHOD_NAME,
            "api_key": VTClient.Constants.API_KEY,
            "bbox": createBoundingBoxString(),
            "safe_search": VTClient.Constants.SAFE_SEARCH,
            "extras": VTClient.Constants.EXTRAS,
            "format": VTClient.Constants.DATA_FORMAT,
            "nojsoncallback": VTClient.Constants.NO_JSON_CALLBACK,
            "per_page": VTClient.Constants.PER_PAGE]
        return methodArguments
    }
    
    //Sets the view and tracking variables to begin downloading
    func initDownloads() {
        parent?.disableNewCollectionButton()
        downloads = 0
        attemptedDownload = false
    }
    
    //Sets the attempted flag, reloads if none were available, so the appropriate label can be shown
    func finishedAttempt(images: [[String: AnyObject]]?){
        self.attemptedDownload = true
        if let images = images where images.count == 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.collectionView?.reloadData()
            })
        }
    }
    
    //Gets the photos from flickr
    func downloadPhotos(){
        initDownloads()
        VTClient.sharedInstance.getImagesFromFlickr(getFlickrRequestArguments(),
                                                    completionHandler: { (success: Bool, images: [[String: AnyObject]]?, error: String?) in
            if success {
                //Let the view know, an attempt was made
                self.finishedAttempt(images)
                NSLog("Got \(images?.count) results from flickr")
                //Save the retrieved photos in the Core Data background context
                self.coreDataStack.performBackgroundBatchOperation { (workerContext) in
                    //Retrieve pin in worker context, so it matches batch context for downloading
                    let pin = workerContext.objectWithID(self.pin!.objectID) as! Pin
                    if let images = images {
                        for image in images {
                            _ = Photo(pin: pin, url_m: image["url_m"] as! String, context: workerContext)
                        }
                        //Save photo data, so number of placeholders can be picked up from FRC
                        self.coreDataStack.performBackgroundUpdate()
                        for photo in pin.photos! {
                            let photo = photo as! Photo
                            //Download each image
                            VTClient.sharedInstance.getImageFromFlickr(urlString: photo.url_m!, completionHandler: { (imageData) in
                                //set image
                                photo.img = imageData
                                //Keep track of finished downloads
                                self.downloads += 1
                                //Save image, so the change shows up in the parent
                                //(used by FRC to query the photos) and propagated to the view.
                                self.coreDataStack.performBackgroundUpdate()
                                //Check if all images have been downloaded
                                //Run in main queue, as it updates UI
                                dispatch_async(dispatch_get_main_queue(), {
                                    self.checkDownloadsAreDone()
                                })
                            })
                        }
                    }
                }
            }
            else if let error = error {
                self.displayError(error)
            }
        })
    }
    
    //Delete current photos, context will notify view
    func deleteAllPhotos() {
        for photo in (pin?.photos)! {
            coreDataStack.context.deleteObject(coreDataStack.context.objectWithID(photo.objectID))
        }
        coreDataStack.saveContext()
    }
    
    //Delete selected photos, context will notify view
    func deleteSelectedPhotos() {
        for photo in selectedPhotos {
            coreDataStack.context.deleteObject(coreDataStack.context.objectWithID(photo.objectID))
        }
        coreDataStack.saveContext()
        parent?.toggleButtons(showNewCollectionButton: true)
    }
    
    //Loads a new collection, replacing the old photos
    func loadNewCollection(){
        deleteAllPhotos()
        downloadPhotos()
    }
    
    //Creates a bounding box for the pin coordinates, as a String
    func createBoundingBoxString() -> String {
        if let pin = pin {
            let latitude = pin.coordinate.latitude
            let longitude = pin.coordinate.longitude
            
            /* Fix added to ensure box is bounded by minimum and maximums */
            let bottom_left_lon =
                max(longitude - VTClient.Constants.BOUNDING_BOX_HALF_WIDTH,
                    VTClient.Constants.LON_MIN)
            let bottom_left_lat =
                max(latitude - VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT,
                    VTClient.Constants.LAT_MIN)
            let top_right_lon =
                min(longitude + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT,
                    VTClient.Constants.LON_MAX)
            let top_right_lat =
                min(latitude + VTClient.Constants.BOUNDING_BOX_HALF_HEIGHT,
                    VTClient.Constants.LAT_MAX)
            
            return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
        }
        else {
            return ""
        }
    }
    
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
    
    
    //Save and enable 'new collection' button when downloads are done
    func checkDownloadsAreDone(){
        if let fetchedResultsController = fetchedResultsController, sections = fetchedResultsController.sections where sections[0].numberOfObjects == downloads {
            NSLog("All downloads are done")
            parent?.enableNewCollectionButton()
            coreDataStack.saveContext()
        }
    }
    
    //Returs the footer to show. Size and visibility are updated
    //if images were found (or not) for the selected pin.
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryViewOfKind(UICollectionElementKindSectionFooter, withReuseIdentifier: "photoCollectionFooter", forIndexPath: indexPath)
        if kind == UICollectionElementKindSectionFooter {
            if let fc = fetchedResultsController
                where fc.sections?[0].numberOfObjects == 0 && attemptedDownload {
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
            where fc.sections?[0].numberOfObjects == 0 && attemptedDownload {
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