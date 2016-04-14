//
//  FrameCacheView.swift
//  XAnimatedImage
//
//  Created by Khaled Taha on 11/24/15.
//  Copyright © 2015 Khaled Taha. All rights reserved.
//

import UIKit

class FrameCacheView:UIView {
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Properties
    
    var progessBarBackground = UIView()
    var progressBarCurrentStatus = UIView()
    var progressBarCurrentCache = UIView()
    
    var image:XAnimatedImage! {
        didSet {
            
            subviews.forEach {
                $0.removeFromSuperview()
            }
            
            self.drawFrames()
            self.setNeedsLayout()
            
        }
    }
    
    var framesInCache:NSIndexSet! {
        didSet {
            self.setNeedsLayout()
        }
    }
    var requestedFrameIndex:Int! {
        
        didSet {
            self.setNeedsLayout()
//            if requestedFrameIndex == image.frameCount {
//                
//            }
        }
    }
    
    // MARK: - Functions
    // MARK: Custom Functions
    
    var updateComplete:Bool?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if image != nil {
            
            if let _ = framesInCache {
                let wFrameForEachIndexedImage:CGFloat = self.bounds.size.width/CGFloat(image.frameCount)
                self.progressBarCurrentCache.frame = CGRectMake(self.progressBarCurrentStatus.bounds.maxX, self.bounds.minY, wFrameForEachIndexedImage * CGFloat(self.framesInCache.count), self.progressBarCurrentCache.bounds.height)
            }
            
            if let _ =  requestedFrameIndex {
                let xFrameForEachSubview:CGFloat = CGFloat(requestedFrameIndex) * self.bounds.width/CGFloat(image.frameCount)
                self.progressBarCurrentStatus.frame = CGRectMake(self.progressBarCurrentStatus.bounds.minX, self.progressBarCurrentStatus.bounds.minY, xFrameForEachSubview, self.progressBarCurrentStatus.bounds.height)
            }
        }
    }
    
    
    
    func drawFrames() {
        if let _ = updateComplete {
            
        } else {
            
            progessBarBackground.frame = self.bounds
            progessBarBackground.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
            
            self.insertSubview(progessBarBackground, atIndex: 0)
            
            progressBarCurrentStatus.frame = CGRectMake(self.bounds.minX, self.bounds.minY, 0, self.bounds.height)
            progressBarCurrentStatus.backgroundColor = UIColor(red: 202/255, green: 71/255, blue: 39/255, alpha: 0.8)
            
            self.insertSubview(progressBarCurrentStatus, atIndex: 1)
            
            progressBarCurrentCache.frame = CGRectMake(self.bounds.minX, self.bounds.minY, 0, self.bounds.height)
            progressBarCurrentCache.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.8)
            
            self.insertSubview(progressBarCurrentCache, atIndex: 1)
            
            updateComplete = true
            
        }
    }
    
}


