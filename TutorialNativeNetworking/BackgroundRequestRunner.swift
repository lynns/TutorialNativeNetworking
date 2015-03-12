//
//  RequestRunner.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 2/26/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import UIKit

class BackgroundRequestRunner: NSObject {
  let logCB: (message: String) -> ()
  let sessionId: String
  
  init(logCB: (message:String) -> (), sessionId: String) {
    self.logCB = logCB
    self.sessionId = sessionId
  }
  
  //https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/URLLoadingSystem/Articles/UsingNSURLSession.html#//apple_ref/doc/uid/TP40013509-SW1
  func performBackgroundPOSTImageUpload(image: UIImage) {
    let sessionConfig = NSURLSessionConfiguration.backgroundSessionConfiguration("backgroundSessionId")
    sessionConfig.HTTPAdditionalHeaders = [
      "Authorization": "Bearer \(sessionId)",
      "Accept": "application/json"
    ]
    
    //this url will throw an error because the title is too long
//    let url = NSURL(string: "https://beta.familysearch.org/platform/memories/memories?type=IMAGE&title=12345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890")!
    //this url is valid
    let url = NSURL(string: "https://beta.familysearch.org/platform/memories/memories?type=IMAGE&title=ThisIsTheTitle")!
    
    let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
    let session = NSURLSession(configuration: sessionConfig, delegate: appDelegate.backgroundSessionDelegate, delegateQueue: nil)
    let imageDiskPath = saveImageToDisk(image)
    
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    var headers = request.allHTTPHeaderFields ?? [String: String]()
    headers["Content-Type"] = "image/jpeg"
    headers["Content-Disposition"] = "attachment; filename=\"mobilefile.jpg\""
    headers["theArbitraryID"] = "This is my id to see if we can pass stuff through"
    request.allHTTPHeaderFields = headers
    
    let task = session.uploadTaskWithRequest(request, fromFile: imageDiskPath!)
    println("Starting background upload task")
    task.resume()
  }
  
  //MARK: - Helper Functions
  
  func saveImageToDisk(image: UIImage) -> NSURL? {
    let fileManager = NSFileManager.defaultManager()
    
    let urls = fileManager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    
    if let documentDirectory: NSURL = urls.first as? NSURL {
      let finalURL = documentDirectory.URLByAppendingPathComponent("imageToUpload.jpg")
      UIImageJPEGRepresentation(image, 1.0).writeToURL(finalURL, atomically: true)
      return finalURL
    }
    
    return nil
  }
}