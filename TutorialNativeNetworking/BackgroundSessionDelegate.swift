//
//  BackgroundSessionDelegate.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 3/11/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import Foundation

class BackgroundSessionDelegate: NSObject, NSURLSessionDelegate, NSURLSessionTaskDelegate {
  
  var completionHandlers: Dictionary<String, () -> Void> = [:]
  
  func registerCompletionHandler(completionHandler: (() -> Void), identifier: String) {
    if completionHandlers[identifier] != nil {
      println("ERROR: Trying to register multiple completion handlers for identifier: \(identifier)")
    }
    
    completionHandlers[identifier] = completionHandler
  }
  
  //MARK: NSURLSessionDelegate
  
  func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
    println("DONE DOING BACKGROUND FETCH TASKS - CALL COMPLETION HANDLER")
    
    let identifier = session.configuration.identifier
    
    if let completionHandler = completionHandlers[identifier] {
      completionHandlers.removeValueForKey(identifier)
      completionHandler()
    }
  }
  
  //MARK: NSURLSessionTaskDelegate
  
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    let percent = round((Double(totalBytesSent) / Double(totalBytesExpectedToSend)) * 100)
    println("Sent data: \(totalBytesSent) of \(totalBytesExpectedToSend) (\(percent)%)")
  }
  
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
    println("TASK REPORTED COMPLETE\nTask: \(task)\nERROR: \(error)")
    println(task.originalRequest.allHTTPHeaderFields)
    
    if let response = task.response as? NSHTTPURLResponse {
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
      
      println("\(items)")
    }
  }
  
  func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    println("INto the challenge: \(challenge)")
  }
  
  func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    println("Into task challenge: \(challenge)")
  }
  
}