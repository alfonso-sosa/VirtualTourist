//
//  VTMapViewController.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 8/1/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit
import MapKit
import CoreData

//Initial controller, shows the map and keeps track of the current position
class VTMapViewController : UIViewController, MKMapViewDelegate {
    
    //Reference to the mapView
    @IBOutlet weak var mapView: MKMapView!
    
    //Edit button
    @IBOutlet weak var editButton: UIBarButtonItem!
    
    //Label to start / end editing
    @IBOutlet weak var editingLabel: UILabel!
    
    // Whenever the frc changes, we execute the search and
    // reload the table
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            fetchedResultsController?.delegate = self
            executeSearch()
            refreshPins()
        }
    }
    
    //Inits the view
    override func viewDidLoad() {
        configureUI()
        restoreMapRegion()
        reloadPins()
    }
    
    
    //Adds a gesture recognizer to add a pin when the user makes a long press
    func configureUI(){
        editingLabel.layer.zPosition = -5
        let longPressRecognizer =
            UILongPressGestureRecognizer.init(target: self,
                                              action: #selector(VTMapViewController.addPinToMapView(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        
    }
    
    //Restore map to last seen region
    func restoreMapRegion(){
        let latitude = NSUserDefaults.standardUserDefaults().doubleForKey("latitude")
        let longitude = NSUserDefaults.standardUserDefaults().doubleForKey("longitude")
        let latitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("latitudeDelta")
        let longitudeDelta = NSUserDefaults.standardUserDefaults().doubleForKey("longitudeDelta")
        //Coordinates have been stored before, display the map using that information
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        if  !delegate.isFirstLaunch() && latitude != 0 && longitude != 0 {
            //Focus on region surrounding the placemark
            self.mapView.setRegion(
                MKCoordinateRegionMake(
                    CLLocationCoordinate2DMake(
                        latitude, longitude), MKCoordinateSpanMake(latitudeDelta, longitudeDelta)), animated: true)
        }
    }
    
    //Restore saved pins with CoreData
    func reloadPins(){
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let stack = delegate.stack
        let fr = NSFetchRequest(entityName: "Pin")
        fr.sortDescriptors = []
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    
    
    //Adds the pin to the mapview using the coordinates from the view.
    func addPinToMapView(recognizer: UILongPressGestureRecognizer){
        if recognizer.state == UIGestureRecognizerState.Began {
            let touchpoint = recognizer.locationInView(mapView)
            let coordinates = mapView.convertPoint(touchpoint, toCoordinateFromView: mapView)
            let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            let pin = Pin(latitude: coordinates.latitude, longitude: coordinates.longitude, context: delegate.stack.context)
            //Stores the pin, to make it available to other contexts
            delegate.stack.saveContext()
            dispatch_async(dispatch_get_main_queue(), {
                self.mapView.addAnnotation(pin)
            })
        }
    }
    
    //Creates or reuses an MKMPinAnnotationView to display the information stored in an MKPointAnnotation
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        print("MapDelegate method being called")
        print("Does have annotation")
        let identifier = "pinAnnotation"
        var view: MKPinAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier)
            as? MKPinAnnotationView {
            print("Dequed view")
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            print("New view")
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.animatesDrop = true
            view.annotation = annotation
        }
        return view
    }
    
    //When the MKMPinAnnotationView is tapped, the Photo Album View for the pin is shown
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let pin = view.annotation as? Pin
        if editing {
            coreDataStack.context.deleteObject(coreDataStack.context.objectWithID(pin!.objectID))
            coreDataStack.saveContext()
        }
        else {
            performSegueWithIdentifier("showPhotoAlbumSegue", sender: pin)
        }
    }
    
    //Passes the selected pin to the next controller
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier! == "showPhotoAlbumSegue" {
            if let photoAlbumViewController = segue.destinationViewController as? VTPhotoAlbumViewController {
                photoAlbumViewController.pin = sender as? Pin
            }
        }
    }
    
    //Persists coordinates and zoom level
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSUserDefaults
            .standardUserDefaults()
            .setDouble(mapView.centerCoordinate.longitude, forKey: "longitude")
        NSUserDefaults
            .standardUserDefaults()
            .setDouble(mapView.centerCoordinate.latitude, forKey: "latitude")
        NSUserDefaults
            .standardUserDefaults()
            .setDouble(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        NSUserDefaults
            .standardUserDefaults()
            .setDouble(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
    }
    
    //Refreshes the pins shown in the map with the results from FetchedResultsController
    func refreshPins(){
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.removeAnnotations(self.mapView.annotations)
            self.mapView.addAnnotations(self.fetchedResultsController?.fetchedObjects as! [MKAnnotation])
        })
    }
    
    //Starts editing mode
    @IBAction func editMapView(sender: UIBarButtonItem) {
        if !editing {
            beginEditing()
        }
        else {
            endEditing()
        }
    }
    
    //Raises the view to show the information label, and changes the button to let the user finish
    func beginEditing() {
        //Raise View
        editing = true
        UIView.animateWithDuration(0.5) {
            self.mapView.frame.origin.y -= self.editingLabel.frame.height
        }
        editButton.title = "Done"
    }
    
    //Lowers back the view, leaves the button in its original state.
    func endEditing() {
        editing = false
        UIView.animateWithDuration(0.5) {
            self.mapView.frame.origin.y += self.editingLabel.frame.height
        }
        editButton.title = "Edit"
    }
    
}

// MARK:  - Fetches
extension VTMapViewController {
    
    //Performs the specified fetch with the results controller
    func executeSearch(){
        if let fc = fetchedResultsController {
            do{
                try fc.performFetch()
            }catch let e as NSError{
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

// MARK:  - Delegate
extension VTMapViewController: NSFetchedResultsControllerDelegate {
    
    //Needs to be implementd by delegates, not needed for the MapView
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
    }
    
    //Reflects any changes in the underlying CoreData context, in the MapView.
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {
        let annotation = anObject as! MKAnnotation
        //inserts, and deletes as appropriate
        switch type {
            case .Insert:
                mapView.addAnnotation(annotation)
            case .Delete:
                mapView.removeAnnotation(annotation)
            case .Update:
                mapView.removeAnnotation(annotation)
                mapView.addAnnotation(annotation)
            case .Move:
                //do nothing
                break
        }
    }
    
    //Needs to be implementd by delegates, not needed for the MapView
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

    }
}


