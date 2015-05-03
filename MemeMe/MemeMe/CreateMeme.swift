//
//  ViewController.swift
//  MemeMe
//
//  Created by Ken Hahn on 4/18/15.
//  Copyright (c) 2015 Ken Hahn. All rights reserved.
//

import UIKit

// TODO: organize methods by protocol, overrides, etc.
public final class CreateMemeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var upperToolbar: UIToolbar!
    @IBOutlet weak var lowerToolbar: UIToolbar!

    @IBOutlet weak var upperText: UITextField!
    @IBOutlet weak var lowerText: UITextField!
    
    
    
    /* overrides start */
    
    override public func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupLowerToolbar()
        setupUpperToolbar()
        setupTextFields()
    }
    
    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.subscribeToKeyboardNotifications()
        imageView.layer.zPosition = -1
    }
    
    override public func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.unsubscribeFromKeyboardNotifications()
    }
    
    /* overrides end */
    
    
    
    /* UITextFieldDelegate start */
    
    public func textFieldDidBeginEditing(textField: UITextField) {
        if !upperTextEdited && textField == upperText {
            upperTextEdited = true
            textField.text = ""
        }
        
        if !lowerTextEdited && textField == lowerText {
            lowerTextEdited = true
            textField.text = ""
        }
    }
    
    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    /* UITextFieldDelegate stop */
    
    
    
    /* UIImagePickerControllerDelegate start */

    public func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        if let img:UIImage = info["UIImagePickerControllerOriginalImage"] as! UIImage? {
            imageView.image = img
            shareButton.enabled = true
        }
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    /* UIImagePickerControllerDelegate end */
    
    
    
    private func subscribeToKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "keyboardWillShow:",
            name: UIKeyboardWillShowNotification,
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "keyboardWillHide:",
            name: UIKeyboardWillHideNotification,
            object: nil
        )
    }
    
    private func unsubscribeFromKeyboardNotifications() {
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIKeyboardWillShowNotification,
            object: nil
        )
        
        NSNotificationCenter.defaultCenter().removeObserver(
            self,
            name: UIKeyboardWillHideNotification,
            object: nil
        )
    }
    
    internal func keyboardWillShow(notification: NSNotification) {
        if lowerText.isFirstResponder() {
            self.view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    internal func keyboardWillHide(notification: NSNotification) {
        if lowerText.isFirstResponder() {
            self.view.frame.origin.y += getKeyboardHeight(notification)
        }
    }
    
    private func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }
    
    private let memeTextAttributes = [
        NSStrokeColorAttributeName : UIColor.blackColor(),
        NSForegroundColorAttributeName : UIColor.whiteColor(),
        NSFontAttributeName : UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSStrokeWidthAttributeName : -3
    ]
    
    private func setupTextFields() {
        upperText.text = "TOP"
        upperText.defaultTextAttributes = memeTextAttributes
        upperText.textAlignment = NSTextAlignment.Center
        upperText.delegate = self
        
        lowerText.text = "BOTTOM"
        lowerText.defaultTextAttributes = memeTextAttributes
        lowerText.textAlignment = NSTextAlignment.Center
        lowerText.delegate = self
    }
    
    private var upperTextEdited = false
    private var lowerTextEdited = false
    
    private var shareButton: UIBarButtonItem!
    
    private func setupUpperToolbar() {
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
            target: nil,
            action: nil
        )
        
        shareButton = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.Action,
            target: self,
            action: "share"
        )
        shareButton.enabled = false
        
        // TODO: show sent memes view
        let cancelButton = UIBarButtonItem(
            title: "Cancel",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: "goToSentMemesView"
        )
        
        upperToolbar.setItems(
            [shareButton, flexibleSpace, cancelButton],
            animated: false
        )
    }
    
    public var goToSentMemesFn: (() -> Void)?
    
    internal func goToSentMemesView() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    private func generateMemedImage() -> UIImage {
        upperToolbar.hidden = true
        lowerToolbar.hidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        let memedImage : UIImage =
        UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // TODO:  Show toolbar and navbar
        upperToolbar.hidden = false
        lowerToolbar.hidden = false
        
        return memedImage
    }
    
    private func saveMeme(memedImage: UIImage) {
        let meme = Meme(
            upperText: upperText.text,
            lowerText: lowerText.text,
            image: imageView.image!,
            memedImage: memedImage
        )
        
        let object = UIApplication.sharedApplication().delegate
        let appDelegate = object as! AppDelegate
        appDelegate.memes.append(meme)
    }
    
    internal func share() {
        let memedImage: UIImage = generateMemedImage()
        let activityVc = UIActivityViewController(
            // TODO: generate meme image using this: https://www.udacity.com/course/viewer#!/c-ud788-nd/l-3669378557/m-3771758758
            // TODO: then save a Meme object using a shared model
            activityItems: [memedImage],
            applicationActivities: nil
        )
        
        activityVc.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) in
            self.saveMeme(memedImage)
            self.goToSentMemesView()
        }
       
        presentViewController(activityVc, animated: true, completion: nil)
    }
    
    private func setupLowerToolbar() {
        let flexibleSpace = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace,
            target: nil,
            action: nil
        )
        
        // Do any additional setup after loading the view, typically from a nib.
        let cameraButton = UIBarButtonItem(
            barButtonSystemItem: UIBarButtonSystemItem.Camera,
            target: self,
            action: "pickAnImageFromCamera"
        )
        
        cameraButton.enabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        
        let albumButton = UIBarButtonItem(
            title: "Album",
            style: UIBarButtonItemStyle.Plain,
            target: self,
            action: "pickAnImageFromAlbum"
        )
        
        lowerToolbar.setItems(
            [flexibleSpace, cameraButton, flexibleSpace, albumButton, flexibleSpace],
            animated: false
        )
    }

    internal func pickAnImageFromCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.Camera
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    internal func pickAnImageFromAlbum() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    public func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem!) {
        if item.title == "Album" {
            pickAnImageFromAlbum()
        } else if item.title == "Camera" {
            pickAnImageFromCamera()
        }
    }
}

