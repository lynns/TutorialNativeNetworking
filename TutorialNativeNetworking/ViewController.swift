//
//  ViewController.swift
//  TutorialNativeNetworking
//
//  Created by Stephen Lynn on 2/26/15.
//  Copyright (c) 2015 FamilySearch. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var logTextView: UITextView!
  @IBOutlet weak var sessionIdTextField: UITextField!
  
  let sessionId = "USYSF33EA41513EE572E4AE5D7792AC8C18D_idses-refa02.a.fsglobal.net"
  let runner: RequestRunner!
  let runnerSessionRestore: RequestRunnerSessionRestore!
  let backgroundRunner: BackgroundRequestRunner!
  
  var imagePicker = UIImagePickerController()
  
  required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.runner = RequestRunner(logCB: self.logMessage, showImage: self.showImage, sessionId: sessionId)
    self.runnerSessionRestore = RequestRunnerSessionRestore(logCB: self.logMessage, sessionId: sessionId)
    self.backgroundRunner = BackgroundRequestRunner(logCB: self.logMessage, sessionId: sessionId)
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
  
  @IBAction func doGETRequestWithSessionRestore(sender: AnyObject) {
    logMessage("START doGETRequestWithSessionRestore")
    runnerSessionRestore.performGETRequest()
  }
  
  @IBAction func doGETRequest(sender: AnyObject) {
    logMessage("START doGETRequest")
    runner.performGETRequests()
  }
  
  @IBAction func doGETImage(sender: AnyObject) {
    logMessage("START doGETImage")
    runner.performGETImageRequest()
  }
  
  @IBAction func doPOSTMultipartImage(sender: AnyObject) {
    logMessage("START doPOSTMultipartImage")
    runner.performPOSTMultipartImageUpload(imageView.image!)
  }
  
  @IBAction func doPOSTImage(sender: AnyObject) {
    logMessage("START doPOSTImage")
    runner.performPOSTImageUpload(imageView.image!)
  }
  
  @IBAction func doBackgroundPOSTImage(sender: AnyObject) {
    logMessage("START doBackgroundPOSTImage")
    backgroundRunner.performBackgroundPOSTImageUpload(imageView.image!)
  }
  
  @IBAction func pickImage(sender: AnyObject) {
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
      imagePicker.delegate = self
      imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
      imagePicker.allowsEditing = false
      
      self.presentViewController(imagePicker, animated: true, completion: nil)
    }
  }
  
  func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
    self.dismissViewControllerAnimated(true, completion: nil)
    imageView.image = image
  }
}

