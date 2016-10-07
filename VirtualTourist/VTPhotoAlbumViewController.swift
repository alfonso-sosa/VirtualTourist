//
//  VTPhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 8/15/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit
import CoreData
import MapKit

//Contains the mapview and a container for the CollectionViewController
class VTPhotoAlbumViewController : UIViewController {
    
    //Selected pin
    var pin: Pin?

    //MapView
    @IBOutlet weak var mapView: MKMapView!
    
    //Button to remove photos
    @IBOutlet weak var removePhotosButton: UIBarButtonItem!
    
    //Button to request a new collection
    @IBOutlet weak var newCollectionButton: UIBarButtonItem!
    
    //Number of completed downloads, used to determine if a new request can be made
    var downloads = 0
    
    //The 'no photos' label is only shown if an attempt to download has been made.
    var attemptedDownload : Bool = false
    
    //Inits the view
    override func viewDidLoad() {
        photoAlbumCollectionViewController.parent = self
        toggleButtons(showNewCollectionButton: true)
        showPinOnMap()
        loadPhotos()
    }
    
    //Shows the 'new collection' button and hides the 'remove photos' button, or vice versa
    func toggleButtons(showNewCollectionButton showNew: Bool){
        if showNew {
            newCollectionButton.enabled = true
            newCollectionButton.title = "New Collection"
            removePhotosButton.enabled = false
            removePhotosButton.title = nil
        }
        else {
            removePhotosButton.enabled = true
            removePhotosButton.title = "Remove Selected Photos"
            newCollectionButton.enabled = false
            newCollectionButton.title = nil
        }
    }
    
    //Displays the selected pin and inits the contained AlbumViewController
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
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
            photoAlbumCollectionViewController.fetchedResultsController = frc
            //Request if none are available
            if let sections = frc.sections where sections[0].numberOfObjects == 0 {
                NSLog("no photos, requesting from flickr...")
                downloadPhotos()
            }
        }
    }
    
    //Sets the view and tracking variables to begin downloading
    func initDownloads() {
        disableNewCollectionButton()
        downloads = 0
        attemptedDownload = false
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
    
    //Sets the attempted flag, reloads if none were available, so the appropriate label can be shown
    func finishedAttempt(images: [[String: AnyObject]]?){
        self.attemptedDownload = true
        if let images = images where images.count == 0 {
            dispatch_async(dispatch_get_main_queue(), {
                self.photoAlbumCollectionViewController.collectionView?.reloadData()
            })
        }
    }
    
    //Save and enable 'new collection' button when downloads are done
    func checkDownloadsAreDone(){
        if let fetchedResultsController = photoAlbumCollectionViewController.fetchedResultsController,
            sections = fetchedResultsController.sections
            where sections[0].numberOfObjects == downloads {
            NSLog("All downloads are done")
            enableNewCollectionButton()
            coreDataStack.saveContext()
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
    
    
    
    
    //Returns the embedded AlbumViewController
    var photoAlbumCollectionViewController : VTPhotoAlbumCollectionViewController {
        get {
            return childViewControllers.last as! VTPhotoAlbumCollectionViewController
        }
    }
    
    
    //Zoos the map to the region of the pins and shows it
    func showPinOnMap(){
        if let pin = pin {
            mapView.setRegion(MKCoordinateRegionMake(pin.coordinate, MKCoordinateSpanMake(0.0725, 0.0725)), animated: true)
            mapView.addAnnotation(pin)
        }
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
        for photo in photoAlbumCollectionViewController.selectedPhotos {
            coreDataStack.context.deleteObject(coreDataStack.context.objectWithID(photo.objectID))
        }
        coreDataStack.saveContext()
        toggleButtons(showNewCollectionButton: true)
    }
    
    //Requests a new collection when the button is tapped
    @IBAction func showNewCollection(sender: UIBarButtonItem) {
        deleteAllPhotos()
        downloadPhotos()
    }
    
    //Deletes the selected photos when the button is tapped
    @IBAction func removeSelectedPhotos(sender: UIBarButtonItem) {
        deleteSelectedPhotos()
    }
    
    //Enables the 'New collection' button when the photos have finished downloading
    func enableNewCollectionButton() {
        newCollectionButton.enabled = true
        newCollectionButton.tintColor = UIColor.blueColor()
    }
    
    //Disables the 'New collection' button while the photos are downloading
    func disableNewCollectionButton() {
        newCollectionButton.enabled = false
        newCollectionButton.tintColor = UIColor.grayColor()
    }

    
}