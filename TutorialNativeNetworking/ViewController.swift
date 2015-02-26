//
//  ViewController.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 2/26/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var logTextView: UITextView!
  @IBOutlet weak var sessionIdTextField: UITextField!
  
  let sessionId = "USYS2E95B3301698778CD3A76BD1304025C6_idses-refa02.a.fsglobal.net"
  let runner: RequestRunner!
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.runner = RequestRunner(logCB: self.logMessage, showImage: self.showImage, sessionId: sessionId)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  func logMessage(message:String) -> () {
    let newContent = logTextView.text + "\nLOG: " + message
    
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.logTextView.text = newContent
    })
  }
  
  func showImage(image: UIImage) {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      self.imageView.image = image
    })
  }
  
  @IBAction func doGETRequest(sender: AnyObject) {
    logMessage("START doGETRequest")
    runner.performGETRequests()
  }
  
  @IBAction func doGETImage(sender: AnyObject) {
    logMessage("START doGETImage")
    runner.performGETImageRequest()
  }
  
}

