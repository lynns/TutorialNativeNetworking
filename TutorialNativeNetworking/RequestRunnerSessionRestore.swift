//
//  RequestRunnerSessionRestore.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 3/12/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import UIKit

class RequestRunnerSessionRestore: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
  let logCB: (message: String) -> ()
  let sessionId: String
  
  var session: NSURLSession!
  
  init(logCB: (message:String) -> (), sessionId: String) {
    self.logCB = logCB
    self.sessionId = sessionId
  }
  
  //MARK: - GET simple
  
  func performGETRequest() {
    let url = NSURL(string: "https://beta.familysearch.org/platform/memories/users/cis.user.MM9X-XF1T/memories")!
    
    let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    sessionConfig.timeoutIntervalForResource = 30 //seconds for total request
    sessionConfig.timeoutIntervalForRequest = 15 //seconds for partial responses
    sessionConfig.HTTPAdditionalHeaders = [
      "Authorization": "Bearer INVALIDSESSIONID",
      "Accept": "application/json"
    ]
    session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
    
    //MARK: Making GET request - shared session with json header just for this request
    
    //NOTE: You can set headers on a single request by using NSMutableURLRequest
    let request = NSMutableURLRequest(URL: url)
    var headers = request.allHTTPHeaderFields ?? [String: String]()
    headers["mySpecialHeader"] = "specialValue"
    request.allHTTPHeaderFields = headers
    
    let task = session.dataTaskWithRequest(request, completionHandler: self.labeledResponseHandler("Custom header GET", request: request, self.parseStringResponse))
    task.resume()
  }
  
  //MARK: - Helper Functions
  
  func parseStringResponse(data: NSData) {
    let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
    println("Response String: \(responseString!.substringToIndex(100))")
  }
  
  func labeledResponseHandler(label: String, request: NSMutableURLRequest, responseParser:((data: NSData)->())) -> ((data: NSData!, response: NSURLResponse!, error: NSError!) -> Void) {
    return {
      (data: NSData!, response: NSURLResponse!, error: NSError!) -> Void in
      
      self.logCB(message: "Response for: \(label)")
      
      //NOTE: http requests will come back with an NSHTTPURLResponse instead of a NSURLResponse
      if let response = response as? NSHTTPURLResponse {
        
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
        
//        if statusCode == "401" {
//          println("Need to restore the session here")
//          var globalHeaders = self.session.configuration.HTTPAdditionalHeaders ?? [String: String]()
//          println("Original headers: \(globalHeaders)")
//          
//          globalHeaders["Authorization"] = "Bearer \(self.sessionId)"
//          self.session.configuration.HTTPAdditionalHeaders = globalHeaders
//          println("Updated headers: \(globalHeaders)")
//            
//          let task = self.session.dataTaskWithRequest(request, completionHandler: self.labeledResponseHandler("Custom header GET", request: request, self.parseStringResponse))
//          task.resume()
//        }
      }
    }
  }
  
  //MARK: Task delegate
  
  func URLSession(session2: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    println("Got an auth challenge")
//    completionHandler(NSURLSessionAuthChallengeDisposition.PerformDefaultHandling, nil)
    //Haven't figured out how to deal with failed auth here so that it actually retries
    //This also seems to get called no matter what error code, even for 404s and I haven't seen a way to tell what the error code is

//    println("Need to restore the session here")
//    var globalHeaders = session2.configuration.HTTPAdditionalHeaders ?? [String: String]()
//    println("Original headers: \(globalHeaders)")
//    
//    globalHeaders["Authorization"] = "Bearer \(self.sessionId)"
//    session2.configuration.HTTPAdditionalHeaders = globalHeaders
//    println("Updated headers: \(globalHeaders)")
//    
////    completionHandler(NSURLSessionAuthChallengeDisposition.CancelAuthenticationChallenge, nil)
//    //tell it to retry
    let credential = NSURLCredential(user: "myUsername", password: "myPassword", persistence: NSURLCredentialPersistence.None)
    completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential, credential)
  }
}