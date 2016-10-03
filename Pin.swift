//
//  Pin.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 8/24/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import Foundation
import CoreData
import MapKit


class Pin: NSManagedObject, MKAnnotation {

    //Convenience init
    convenience init(latitude: Double, longitude: Double, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Pin",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
        }
        else{
            fatalError("Unable to find Entity name!")
        }
    }
    
    
    //Convenience computed coordinate
    var coordinate: CLLocationCoordinate2D {
        get {
            var coord = CLLocationCoordinate2D()
            coord.latitude = self.latitude as! Double
            coord.longitude = self.longitude as! Double
            return coord
        }
    }

}
