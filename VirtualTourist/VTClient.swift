//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Alfonso Sosa on 9/12/16.
//  Copyright © 2016 Alfonso Sosa. All rights reserved.
//

import UIKit

//Network client
class VTClient : NSObject {
    
    //url session to create requests
    var session: NSURLSession
    
    //Inits the url session
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]?) -> String {
        if let parameters = parameters {
            
            var urlVars = [String]()
            
            for (key, value) in parameters {
                
                /* Make sure that it is a string value */
                let stringValue = "\(value)"
                
                /* Escape it */
                let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
                
                /* Append it */
                urlVars += [key + "=" + "\(escapedValue!)"]
                
            }
            
            return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
        }
        else {
            return ""
        }
        
    }
    
    //Parses the specified data as JSON and returns the result in the completion handler.
    class func parseJSONWithCompletionHandler(data: NSData,
                                              skip: Int,
                                              completionHandler: (result: AnyObject!, error: NSError?) -> Void){
        var parsedResult: AnyObject!
        do {
            //Remove {skip} characters, 1st 5 chars for Udacity API
            let newData = data.subdataWithRange(NSMakeRange(skip, data.length-skip))
            parsedResult = try NSJSONSerialization.JSONObjectWithData(newData, options: .AllowFragments)
            //print("Parsed JSON \(NSString(data: newData, encoding: NSUTF8StringEncoding))")
        }
        catch {
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as json \(data)"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
            return
        }
        completionHandler(result: parsedResult, error: nil)
    }
    
    //Performs a GET request
    func taskForGET(baseURL: String,
                    method: String,
                    parameters: [String : AnyObject]?,
                    headerValues: [String: String]?,
                    resultIndex: Int = 0,
                    completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 2/3. Build the URL and configure the request */
        let urlString = baseURL + method + VTClient.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        if let headerValues = headerValues {
            for (header, value) in headerValues {
                request.addValue(value, forHTTPHeaderField: header)
            }
        }
        
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                completionHandler(result: nil, error: error)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                var statusCode : Int = -1
                var errorDescription : String? = nil
                if let response = response as? NSHTTPURLResponse {
                    errorDescription = "Request returned invalid response. Status \(response.statusCode)"
                    statusCode = response.statusCode
                }
                else if let response = response {
                    errorDescription = "Request returned invalid response. Status \(response)"
                }
                else {
                    errorDescription = "Request returned invalid response."
                }
                completionHandler(result: nil,
                                  error: NSError(domain: "taskForGET",
                                    code: statusCode,
                                    userInfo: [NSLocalizedDescriptionKey: errorDescription!]))
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request")
                completionHandler(result: nil, error: NSError(domain: "taskForGET",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "No data returned by request"]))
                return
            }
            
            /* 5/6. Parse the data and use the data (happens in completion handler) */
            VTClient.parseJSONWithCompletionHandler(data, skip: resultIndex,  completionHandler: completionHandler)
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
    }
    
    //Singleton pattern
    static let sharedInstance = VTClient()
}

// MARK: Constants
extension VTClient {
    
    struct Constants {
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
        static let API_KEY = "487543e16cb6481c1dde3cfa91f177e6"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let PER_PAGE = "21"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        
        
        static let RESULT_PHOTOS = "photos"
        static let RESULT_PHOTO_LIST = "photo"
    }
    
}

// MARK: Helper methods
extension VTClient {
    
    //Adds a new argument to the flickr call, to get a random page which will be the
    //minimum between the total number of pages and the maximum allowed to get to the 
    //4000 photos flickr limit
    func getFlickrRandomPageArguments(result: [String:AnyObject],
                                      methodArguments: [String : AnyObject]) -> [String : AnyObject]{
        let resultData = result[Constants.RESULT_PHOTOS] as! [String: AnyObject]
        //total number of pages
        let totalPages = resultData["pages"] as! Int
        NSLog("======Total Pages \(totalPages)")
        //max page we can request is = limit / number of photos per page
        let maxAllowed = 4000 / Int(Constants.PER_PAGE)!
        let pageLimit = min(totalPages, maxAllowed)
        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        NSLog("======Page to get: \(randomPage)")
        var newArguments = methodArguments
        newArguments["page"] = randomPage
        return newArguments
    }
    
    //Downloads the metadata of a random flickr photo set, for the specified arguments
    func getImagesFromFlickr(methodArguments: [String : AnyObject],
                             completionHandler: (success: Bool,
                                                    images: [[String: AnyObject]]?,
                                                    error: String?) -> Void) {
        //First get for the total number of available photos
        taskForGET(Constants.BASE_URL, method: "", parameters: methodArguments, headerValues: nil) { (result, error) in
            if let error = error {
                completionHandler(success:false, images: nil, error: error.localizedDescription)
            }
            else if let result = result as? [String:AnyObject]  {
                //Second get gets the actual random set of photos
                self.taskForGET(Constants.BASE_URL, method: "",
                                parameters: self.getFlickrRandomPageArguments(result, methodArguments: methodArguments),
                                headerValues: nil,
                                completionHandler: { (result, error) in
                    if let error = error {
                        completionHandler(success:false, images: nil, error: error.localizedDescription)
                    }
                    //No errors, completion handler with the resulting photos information
                    else if let result = result as? [String:AnyObject]  {
                        let resultData = result[Constants.RESULT_PHOTOS] as! [String: AnyObject]
                        let photos = resultData[Constants.RESULT_PHOTO_LIST] as! [[String:AnyObject]]
                        completionHandler(success: true, images: photos, error: nil)
                    }
                    else {
                        completionHandler(success: false, images: nil, error: "Could not parse response")
                    }
                })
            }
            else {
                completionHandler(success: false, images: nil, error: "Could not parse response")
            }
        }
    }
    
    
    
    //Gets the photo for the specified url string.
    //Gives it back to the caller as NSData in the completion handler
    func getImageFromFlickr(urlString url: String, completionHandler handler: (imageData: NSData) -> Void){
        //Fixed comment: Download in background queue, so it doesn't block UI, but only if called from the main queue
        if (NSThread.isMainThread()){
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0)){
                () -> Void in
                if let url = NSURL(string: url) {
                    let imageData = NSData(contentsOfURL: url)
                    //Runs completion handler in the main queue, so the caller can modify Views
                    dispatch_async(dispatch_get_main_queue(), {
                        handler(imageData: imageData!)
                    })
                }
            }
        }
        else {
            if let url = NSURL(string: url) {
                let imageData = NSData(contentsOfURL: url)
                handler(imageData: imageData!)
            }
        }
    }
}