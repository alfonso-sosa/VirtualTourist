//
//  Photo.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 8/24/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import Foundation
import CoreData
import UIKit


class Photo: NSManagedObject {
    
    //Convenience init
    convenience init(pin: Pin, url_m: String, context: NSManagedObjectContext){
        if let ent = NSEntityDescription.entityForName("Photo",
                                                       inManagedObjectContext: context){
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.pin = pin
            self.url_m = url_m
        }
        else{
            fatalError("Unable to find Entity name!")
        }
    }

}
