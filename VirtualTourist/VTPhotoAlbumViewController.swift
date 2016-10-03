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
    
    //Inits the view
    override func viewDidLoad() {
        toggleButtons(showNewCollectionButton: true)
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
        setPinOnChildController()
        showPinOnMap()
    }
    
    //Returns the embedded AlbumViewController
    var photoAlbumCollectionViewController : VTPhotoAlbumCollectionViewController {
        get {
            return childViewControllers.last as! VTPhotoAlbumCollectionViewController
        }
    }
    
    //Sets selected pin in the embedded AlbumViewController
    func setPinOnChildController(){
        if let pin = pin {
            photoAlbumCollectionViewController.pin = pin
            photoAlbumCollectionViewController.parent = self
        }
    }
    
    //Zoos the map to the region of the pins and shows it
    func showPinOnMap(){
        if let pin = pin {
            mapView.setRegion(MKCoordinateRegionMake(pin.coordinate, MKCoordinateSpanMake(0.0725, 0.0725)), animated: true)
            mapView.addAnnotation(pin)
        }
    }
    
    
    //Requests a new collection when the button is tapped
    @IBAction func showNewCollection(sender: UIBarButtonItem) {
        photoAlbumCollectionViewController.loadNewCollection()
    }
    
    //Deletes the selected photos when the button is tapped
    @IBAction func removeSelectedPhotos(sender: UIBarButtonItem) {
        photoAlbumCollectionViewController.deleteSelectedPhotos()
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