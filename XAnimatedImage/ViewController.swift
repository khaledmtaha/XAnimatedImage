//
//  ViewController.swift
//  XAnimatedImage
//
//  Created by Khaled Taha on 11/24/15.
//  Copyright © 2015 Khaled Taha. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var animatedImageA : XAnimatedImage!
    var animatedImageViewA = XAnimatedImageView()
    var debugViewA = DebugView()

    var animatedImageB : XAnimatedImage!
    var animatedImageViewB = XAnimatedImageView()
    var debugViewB = DebugView()

    var animatedImageC : XAnimatedImage!
    var animatedImageViewC = XAnimatedImageView()
    var debugViewC = DebugView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        // A
        
        animatedImageViewA.translatesAutoresizingMaskIntoConstraints = false
        animatedImageViewA.contentMode = UIViewContentMode.ScaleAspectFit
        
        let urlString = "https://i.imgur.com/7Hpfb0o.gif"
        let url = NSURL(string: urlString)
        self.loadAnimatedImageWithURL(url!) { (animatedImage) -> () in
            self.animatedImageA = animatedImage
            self.animatedImageViewA.animatedImage = self.animatedImageA
            self.animatedImageA.debug_delegate = self.debugViewA
            self.animatedImageViewA.debug_delegate = self.debugViewA
            self.debugViewA.image = self.animatedImageA

            
        }
        
//        animatedImageA = XAnimatedImage(initWithAnimatedGIFData: NSData(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("low", ofType: "gif")!))!)
//        animatedImageViewA.animatedImage = animatedImageA

        self.view.insertSubview(animatedImageViewA, atIndex: 0)
        
        /* 
        
//      Used for centering a single view**

        let screenWidth = UIScreen.mainScreen().bounds.size.width
        let imageHeightModifier = (animatedImageA.size.width - screenWidth)/animatedImageA.size.width
        let newHeight = (1 - imageHeightModifier) * animatedImageA.size.height

        */
        
        let distributedHeightMultiplier:CGFloat = 1/3
        
        let wConstraintAnimatedViewA = NSLayoutConstraint(item: animatedImageViewA, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        
        let hConstraintAnimatedViewA = NSLayoutConstraint(item: animatedImageViewA, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: distributedHeightMultiplier, constant:0)
        
        let xConstraintAnimatedViewA = NSLayoutConstraint(item: animatedImageViewA, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        
        let yConstraintAnimatedViewA = NSLayoutConstraint(item: animatedImageViewA, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0)

        self.view.addConstraints([wConstraintAnimatedViewA, hConstraintAnimatedViewA, xConstraintAnimatedViewA, yConstraintAnimatedViewA])
        
//        animatedImageA.debug_delegate = debugViewA
//        animatedImageViewA.debug_delegate = debugViewA
//        debugViewA.image = animatedImageA
        debugViewA.translatesAutoresizingMaskIntoConstraints = false
        
        self.animatedImageViewA.insertSubview(debugViewA, atIndex: 1)
        
        let wConstraintDebugViewA = NSLayoutConstraint(item: debugViewA, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewA, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let hConstraintDebugViewA = NSLayoutConstraint(item: debugViewA, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewA, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        let xConstraintDebugViewA = NSLayoutConstraint(item: debugViewA, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewA, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
        let yConstraintDebugViewA = NSLayoutConstraint(item: debugViewA, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewA, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        

        self.animatedImageViewA.addConstraints([wConstraintDebugViewA, hConstraintDebugViewA, xConstraintDebugViewA, yConstraintDebugViewA])
        
        // B
        
        animatedImageViewB.translatesAutoresizingMaskIntoConstraints = false
        animatedImageViewB.contentMode = UIViewContentMode.ScaleAspectFit
        animatedImageB = XAnimatedImage(initWithAnimatedGIFData: NSData(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("mid", ofType: "gif")!))!)
        animatedImageViewB.animatedImage = animatedImageB
        
        self.view.insertSubview(animatedImageViewB, atIndex: 0)
        
        let wConstraintAnimatedViewB = NSLayoutConstraint(item: animatedImageViewB, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        
        let hConstraintAnimatedViewB = NSLayoutConstraint(item: animatedImageViewB, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: distributedHeightMultiplier, constant:1)
        
        let xConstraintAnimatedViewB = NSLayoutConstraint(item: animatedImageViewB, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        
        let yConstraintAnimatedViewB = NSLayoutConstraint(item: animatedImageViewB, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: animatedImageViewA, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        self.view.addConstraints([wConstraintAnimatedViewB, hConstraintAnimatedViewB, xConstraintAnimatedViewB, yConstraintAnimatedViewB])
        
        animatedImageB.debug_delegate = debugViewB
        animatedImageViewB.debug_delegate = debugViewB
        debugViewB.image = animatedImageB
        debugViewB.translatesAutoresizingMaskIntoConstraints = false
        
        self.animatedImageViewB.insertSubview(debugViewB, atIndex: 1)
        
        let wConstraintDebugViewB = NSLayoutConstraint(item: debugViewB, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewB, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let hConstraintDebugViewB = NSLayoutConstraint(item: debugViewB, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewB, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        let xConstraintDebugViewB = NSLayoutConstraint(item: debugViewB, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewB, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
        let yConstraintDebugViewB = NSLayoutConstraint(item: debugViewB, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewB, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        
        debugViewB.frame = animatedImageViewB.frame
        self.animatedImageViewB.addConstraints([wConstraintDebugViewB, hConstraintDebugViewB, xConstraintDebugViewB, yConstraintDebugViewB])
        
        // C
        
        animatedImageViewC.translatesAutoresizingMaskIntoConstraints = false
        animatedImageViewC.contentMode = UIViewContentMode.ScaleAspectFit
        animatedImageC = XAnimatedImage(initWithAnimatedGIFData: NSData(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("hi", ofType: "gif")!))!)
        animatedImageViewC.animatedImage = animatedImageC
            
            self.view.insertSubview(animatedImageViewC, atIndex: 0)
        
        let wConstraintAnimatedViewC = NSLayoutConstraint(item: animatedImageViewC, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        
        let hConstraintAnimatedViewC = NSLayoutConstraint(item: animatedImageViewC, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: distributedHeightMultiplier, constant:1)
        
        let xConstraintAnimatedViewC = NSLayoutConstraint(item: animatedImageViewC, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1, constant: 0)
        
        let yConstraintAnimatedViewC = NSLayoutConstraint(item: animatedImageViewC, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        self.view.addConstraints([wConstraintAnimatedViewC, hConstraintAnimatedViewC, xConstraintAnimatedViewC, yConstraintAnimatedViewC])
        
        animatedImageC.debug_delegate = debugViewC
        animatedImageViewC.debug_delegate = debugViewC
        debugViewC.image = animatedImageC
        debugViewC.translatesAutoresizingMaskIntoConstraints = false
        
        self.animatedImageViewC.insertSubview(debugViewC, atIndex: 1)
        
        let wConstraintDebugViewC = NSLayoutConstraint(item: debugViewC, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewC, attribute: NSLayoutAttribute.Width, multiplier: 1, constant: 0)
        let hConstraintDebugViewC = NSLayoutConstraint(item: debugViewC, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewC, attribute: NSLayoutAttribute.Height, multiplier: 1, constant: 0)
        let xConstraintDebugViewC = NSLayoutConstraint(item: debugViewC, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewC, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
        let yConstraintDebugViewC = NSLayoutConstraint(item: debugViewC, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.animatedImageViewC, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0)
        
        
        debugViewC.frame = animatedImageViewC.frame
        self.animatedImageViewC.addConstraints([wConstraintDebugViewC, hConstraintDebugViewC, xConstraintDebugViewC, yConstraintDebugViewC])

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// Even though NSURLCache *may* cache the results for remote images, it doesn't guarantee it.
    /// Cache control headers or internal parts of NSURLCache's implementation may cause these images to become uncache.
    /// Here we enfore strict disk caching so we're sure the images stay around.
    
    func loadAnimatedImageWithURL(url:NSURL, completion:(animatedImage:XAnimatedImage)-> ()) {
        
        // Create a file to store the GIF and its corresponding data
        
        let fileName = url.lastPathComponent!
        let diskPath = (NSHomeDirectory() as NSString).stringByAppendingPathComponent(fileName)
        var animatedImageData = NSFileManager.defaultManager().contentsAtPath(diskPath)
        
        var animatedImage = XAnimatedImage()
        
        if animatedImageData?.bytes == nil {
            
            // Newly created, then download
            
            NSURLSession.sharedSession().dataTaskWithURL(url) { (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
                
                if error == nil {
                    animatedImageData = data
                    animatedImage = XAnimatedImage(initWithAnimatedGIFData: animatedImageData!)
                    if let _ = animatedImage.posterImage {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            completion(animatedImage: animatedImage)
                        })
                        
                        data?.writeToFile(diskPath, atomically: true)
                    }
                } else {
                    print("error exists")
                }
                

                
                
                
                } .resume()

            

        } else {
            animatedImage = XAnimatedImage(initWithAnimatedGIFData: animatedImageData!)
                completion(animatedImage: animatedImage)
            
        }
        
        
        

        }
        
}
     
        
    
        
        
        
        





