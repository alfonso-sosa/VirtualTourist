//
//  Pin+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 9/26/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var photos: NSSet?

}
