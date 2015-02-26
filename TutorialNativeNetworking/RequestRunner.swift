//
//  RequestRunner.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 2/26/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import Foundation

class RequestRunner {
  let logCB: (message:String) -> ()
  let sessionId: String
  
  init(logCB: (message:String) -> (), sessionId: String) {
    self.logCB = logCB
    self.sessionId = sessionId
  }
  
  //NOTE: Executes request on background thread by default and returns on the background thread
  //NOTE: Can create a custom config that affects all requests from a given session
  
  func performGETRequests() {
    let url = NSURL(string: "https://beta.familysearch.org/platform/memories/users/cis.user.MM9X-XF1T/memories")!
    
    //NOTE: Setup session config that applies to all requests that come from this session
    let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    sessionConfig.timeoutIntervalForResource = 30 //seconds for total request
    sessionConfig.timeoutIntervalForRequest = 15 //seconds for partial responses
    sessionConfig.HTTPAdditionalHeaders = [
      "Authorization": "Bearer \(sessionId)"
    ]
    
    //    let session: NSURLSession = NSURLSession.sharedSession() //just gives you a preconfigured session
    let session = NSURLSession(configuration: sessionConfig)
    
    //MARK: Making GET request - shared session with json header just for this request
    
    //NOTE: You can set headers on a single request by using NSMutableURLRequest
    let request = NSMutableURLRequest(URL: url)
    var headers = request.allHTTPHeaderFields ?? [String: String]()
    headers["Accept"] = "application/json"
    request.allHTTPHeaderFields = headers
    
    let task = session.dataTaskWithRequest(request, completionHandler: self.labeledResponseHandler("Custom header GET", self.parseJSONResponse))
    task.resume()
    
    //MARK: Making GET request - all default
    
    //NOTE: header from previous request didn't affect this request
    let task2: NSURLSessionDataTask = session.dataTaskWithURL(url, completionHandler: self.labeledResponseHandler("Simple default GET", self.parseStringResponse))
    task2.resume()
  }
  
  //MARK: - Helper Functions
  
  func parseStringResponse(data: NSData) {
    let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
    println("Response String: \(responseString?.substringToIndex(40))")
  }
  
  func parseJSONResponse(data: NSData) {
    var error: NSError?
    let props: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: &error) as NSDictionary
    
    if error != nil {
      println("Error parsing response: \(error!)")
      
    } else {
      println("Response JSON: \(props)")
    }
  }
  
  func labeledResponseHandler(label: String, responseParser:((data: NSData)->())) -> ((data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
    return {
      (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
      
      self.logCB(message: "Response for: \(label)")
      
      //NOTE: http requests will come back with an NSHTTPURLResponse instead of a NSURLResponse
      let response = response as NSHTTPURLResponse
      
      assert(!NSThread.isMainThread(), "This should have returned on a background thread")
      
      let statusCode = String(response.statusCode)
      let contentLength = String(response.expectedContentLength)
      let contentType = response.allHeaderFields["Content-Type"] as String
      
      let items: Dictionary<String,AnyObject> = [
        "mimetype": response.MIMEType!,
        "expectedContentLength": contentLength,
        "statusCode": statusCode,
        "contentType": contentType
      ]
      
      if error == nil {
        responseParser(data: data)
      }
      
      self.logCB(message: "\(items)")
    }
  }
}