//
//  RequestRunner.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 2/26/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import UIKit

//NOTE: Helpful tutorial - http://www.raywenderlich.com/51127/nsurlsession-tutorial

class RequestRunner: NSObject, NSURLSessionDelegate {
  let logCB: (message: String) -> ()
  let showImageCB: (image: UIImage) -> ()
  let sessionId: String
  
  init(logCB: (message:String) -> (), showImage: (image: UIImage) -> (), sessionId: String) {
    self.logCB = logCB
    self.showImageCB = showImage
    self.sessionId = sessionId
  }
  
  //NOTE: Executes request on background thread by default and returns on the background thread
  //NOTE: Can create a custom config that affects all requests from a given session
  
  //MARK: - GET simple
  
  func performGETRequests() {
    let url = NSURL(string: "https://beta.familysearch.org/platform/memories/users/cis.user.MM9X-XF1T/memories")!
    
    //    let session: NSURLSession = NSURLSession.sharedSession() //just gives you a preconfigured session
    let session = self.customSession()
    
    //MARK: Making GET request - shared session with json header just for this request
    
    //NOTE: You can set headers on a single request by using NSMutableURLRequest
    let request = NSMutableURLRequest(URL: url)
    var headers = request.allHTTPHeaderFields ?? [String: String]()
    headers["mySpecialHeader"] = "specialValue"
    request.allHTTPHeaderFields = headers
    
    let task = session.dataTaskWithRequest(request, completionHandler: self.labeledResponseHandler("Custom header GET", self.parseJSONResponse))
    task.resume()
    
    //MARK: Making GET request - all default
    
    //NOTE: header from previous request didn't affect this request
    let task2: NSURLSessionDataTask = session.dataTaskWithURL(url, completionHandler: self.labeledResponseHandler("Simple default GET", self.parseStringResponse))
    task2.resume()
  }
  
  //MARK: - GET Image
  
  func performGETImageRequest() {
    let imageUrl = NSURL(string: "https://beta.familysearch.org/patron/v2/TH-801-46819-13-94/dist.jpg?ctx=ArtCtxPublic")!
    let sessionConfig = customSessionConfig("image/jpg")
    let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    
    let task = session.downloadTaskWithURL(imageUrl) {
      (location: NSURL!, response: NSURLResponse!, error: NSError!) -> Void in
      
      if error != nil {
        println("Error getting image: \(error!)")
        
      } else {
        if let location = location {
          println("Got image back at location: \(location.absoluteString)")
          if let data = NSData(contentsOfURL: location) {
            if let image = UIImage(data: data) {
              self.showImageCB(image: image)
              
            } else {
              println("Couldn't convert image data to a UIImage object")
            }
            
          } else {
            println("Couldn't find image data on disk")
          }
        }
      }
    }
    
    task.resume()
  }
  
  func performPOSTMultipartImageUpload(image: UIImage) {
    let url = NSURL(string: "https://beta.familysearch.org/artifactmanager/artifacts/multipart")!
    
    let sessionConfig = customSessionConfig("application/json")
    let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    
    let imageData = UIImageJPEGRepresentation(image, 1.0)
    let params = [
      "artifactCategory": "IMAGE",
      "artifactContentCategory": "PHOTO",
      "title": "This is my title from the test networking project"
    ]
    let requestParts = createMultipartRequestParts(imageData, fields: params)
    
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    var headers = request.allHTTPHeaderFields ?? [String: String]()
    headers["Content-Type"] = requestParts.contentType
    request.allHTTPHeaderFields = headers
    
    let task = session.uploadTaskWithRequest(request, fromData: requestParts.body, completionHandler: self.labeledResponseHandler("Upload image POST", self.parseJSONResponse))
    task.resume()
  }
  
  func performPOSTImageUpload(image: UIImage) {
    let url = NSURL(string: "https://beta.familysearch.org/platform/memories/memories?type=IMAGE")!
    
    let sessionConfig = customSessionConfig("application/json")
    let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
    
    let imageData = UIImageJPEGRepresentation(image, 1.0)
    
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    var headers = request.allHTTPHeaderFields ?? [String: String]()
    headers["Content-Type"] = "image/jpeg"
    headers["Content-Disposition"] = "attachment; filename=\"mobilefile.jpg\""
    request.allHTTPHeaderFields = headers
    
    let task = session.uploadTaskWithRequest(request, fromData: imageData, completionHandler: self.labeledResponseHandler("Upload image POST", self.parseJSONResponse))
    task.resume()
  }
  
  //MARK: - Helper Functions
  
  func createQueryString(params: [String:String]) -> String {
    let pairs = map(params.keys, {"\($0)=\(params[$0])"})
    let queryString = "&".join(pairs)
    
    return queryString
  }
  
  func createMultipartRequestParts(data: NSData?, fields: [String:String]?) -> (contentType: String, body: NSData) {
    let boundary = "FSMobileBoundary"
    var body = NSMutableData()
    var paramString = ""
    
    for (key,value) in fields! {
      paramString += "--\(boundary)\r\n"
      paramString += "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n"
      paramString += "\(value)\r\n"
    }
    
    body.appendData(paramString.dataUsingEncoding(NSUTF8StringEncoding)!)
    
    if let data = data {
      paramString = "--\(boundary)\r\n"
      paramString += "Content-Disposition: form-data; name=\"file\"; filename=\"file.jpg\"\r\n"
      paramString += "Content-Type: image/jpeg\r\n\r\n"
      
      body.appendData(paramString.dataUsingEncoding(NSUTF8StringEncoding)!)
      body.appendData(data)
    }
    
    body.appendData("\r\n--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
    
    let contentType = "multipart/form-data; boundary=\(boundary)"
    return (contentType, body)
  }
  
  func customSessionConfig(acceptType: String?) -> NSURLSessionConfiguration {
    //NOTE: Setup session config that applies to all requests that come from this session
    let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
    sessionConfig.timeoutIntervalForResource = 30 //seconds for total request
    sessionConfig.timeoutIntervalForRequest = 15 //seconds for partial responses
    sessionConfig.HTTPAdditionalHeaders = [
      "Authorization": "Bearer \(sessionId)",
      "Accept": acceptType ?? "application/json"
    ]
    
    return sessionConfig
  }
  
  func customSession() -> NSURLSession {
    let sessionConfig = self.customSessionConfig(nil)
    
    let session = NSURLSession(configuration: sessionConfig)
    
    return session
  }
  
  func parseStringResponse(data: NSData) {
    let responseString = NSString(data: data, encoding: NSUTF8StringEncoding)
    println("Response String: \(responseString!.substringToIndex(40))")
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
      }
    }
  }
}