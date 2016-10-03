//
//  VTUIViewController.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 9/13/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit

extension UIViewController {
    
    //Returns the appDelegate
    var appDelegate : AppDelegate {
        get {
            return UIApplication.sharedApplication().delegate as! AppDelegate
        }
    }
    
    //Returns the core data stack
    var coreDataStack : CoreDataStack {
        get {
            return appDelegate.stack
        }
    }
    
    //Convenience method for all controllers to display error messages in a pop up
    func displayError(errorString: String?) {
        if let errorString = errorString {
            let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in } )
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(alert, animated: true) {}
            })
            
        }
    }
    
    //Convenience method for all controllers to display messages in a pop up
    func displayMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in } )
        dispatch_async(dispatch_get_main_queue(), {
            self.presentViewController(alert, animated: true) {}
        })
    }
    
    
}
