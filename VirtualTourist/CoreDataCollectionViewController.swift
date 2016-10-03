//
//  CoreDataCollectionViewController.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 8/24/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit
import CoreData

//CollectionViewController backed with CoreData.
class CoreDataCollectionViewController: UICollectionViewController {
    
    //Block operations for NSFetchedResultsControllerDelegate
    var blockOperations: [NSBlockOperation] = []
    
    //Trigger search when frc is set
    var fetchedResultsController : NSFetchedResultsController?{
        didSet{
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView!.reloadData()
        }
    }
    
    //Init method, sets the FRC
    init(fetchedResultsController fc : NSFetchedResultsController,
                                  layout : UICollectionViewLayout){
        fetchedResultsController = fc
        super.init(collectionViewLayout: layout)
    }

    //Required init
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    //Empties operations for NSFetchedResultsControllerDelegate; see extension below.
    deinit {
        // Cancel all block operations when VC deallocates
        for operation: NSBlockOperation in blockOperations {
            operation.cancel()
        }
        
        blockOperations.removeAll(keepCapacity: false)
    }
}

//MARK: CollectionViewDataSource
extension CoreDataCollectionViewController {
    
    //Returns the total number of sections fetched by the FRC, 0 if none
    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController {
            return (fc.sections?.count)!
        }
        else {
            return 0
        }
    }
    
    //Returns the total number of items for the first section in the FRC, or 0 if none
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        }
        else {
            return 0
        }
    }
    
}

//Extension for the cell method
extension CoreDataCollectionViewController {

    //Method to be overriden in subclasses, produces the cell to be displayed
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        fatalError("This method MUST be implemented by a subclass of CoreDataCollectionViewController")
    }
    
    
}

//Fetches
extension CoreDataCollectionViewController {
    
    //Performs the fetch
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }
            catch let e as NSError{
                print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
            }
        }
    }
}

//Delegate for NSFetchedResultsController, block operations idea from
//https://github.com/AshFurrow/UICollectionView-NSFetchedResultsController/issues/13
extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {
    
    
    //Empties the operations
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        blockOperations.removeAll()
    }
    
    //Stores the operations on sections
    func controller(controller: NSFetchedResultsController,
                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                     atIndex sectionIndex: Int,
                                             forChangeType type: NSFetchedResultsChangeType) {
        let set = NSIndexSet(index: sectionIndex)
        switch type {
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(set)
                    }
                    })
            )
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(set)
                    }
                    })
            )
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(set)
                    }
                    })
            )
        default:
            break
        
        }
        
        
        
        
    }
    
    //Stores the operations on items
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {
        
        switch(type){
            
        case .Insert:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItemsAtIndexPaths([newIndexPath!])
                        //Invalidate to force layout recalculation
                        this.collectionView!.collectionViewLayout.invalidateLayout()
                    }
                    })
            )
            
        case .Delete:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
            
        case .Update:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItemsAtIndexPaths([indexPath!])
                    }
                    })
            )
            
        case .Move:
            blockOperations.append(
                NSBlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItemAtIndexPath(indexPath!, toIndexPath: newIndexPath!)
                    }
                    })
            )
        }
        
    }
    
    //Applies the soted operations
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        collectionView!.performBatchUpdates({ () -> Void in
            for operation: NSBlockOperation in self.blockOperations {
                operation.start()
            }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepCapacity: false)
        })
    }
    
    
}