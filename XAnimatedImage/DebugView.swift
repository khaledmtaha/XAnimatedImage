//
//  DebugView.swift
//  XAnimatedImage
//
//  Created by Khaled Taha on 11/24/15.
//  Copyright © 2015 Khaled Taha. All rights reserved.
//

import UIKit

class DebugView : UIView, XAnimatedImageDebugDelegate, XAnimatedImageViewDebugDelegate{
    
    // MARK: - Properties
    // MARK: Public Properties
    
    weak var image = XAnimatedImage()
    weak var imageView = XAnimatedImageView()
    
    // MARK: Private Properties
    
    var gradientLayer:CAGradientLayer!
    var currentFrameDelay:NSTimeInterval!
    var playPauseButton:UIView!
    var frameCacheView:FrameCacheView!
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func commonInit() {
        image?.debug_delegate = self
    }
    
    // MARK: - Functions
    // MARK: Public Functions
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // MARK: Layout Subviews
        
        let kMargin:CGFloat = 10
//        setupGradientOverlay()
        setupFrameCacheView(kMargin)
    }
    
    // MARK: Setup Views
    
    func setupGradientOverlay () {
        if gradientLayer == nil {
            gradientLayer = CAGradientLayer(layer: layer)
            gradientLayer.colors = [UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.0).CGColor, UIColor(red: 0, green: 0, blue: 0, alpha: 0.5).CGColor]
            gradientLayer.locations = [0.0, 0.30,0.70,1]
            self.layer.addSublayer(gradientLayer)
        }
        
        self.gradientLayer.frame = bounds
    }
    
    func setupPlayPauseButton(margin:CGFloat) {
        if playPauseButton == nil {
            playPauseButton = UIView()
            self.addSubview(playPauseButton)
            playPauseButton.backgroundColor = UIColor.greenColor()
            let wFrame:CGFloat = min(bounds.width,bounds.height)*0.1
            let hFrame:CGFloat = min(bounds.width,bounds.height)*0.1
            let xFrame:CGFloat = (bounds.width - wFrame)/2
            let yFrame:CGFloat = bounds.height - (2*margin + hFrame)
            playPauseButton.frame = CGRectMake(xFrame, yFrame, wFrame, hFrame)
        }
    }
    
    func setupFrameCacheView(margin:CGFloat) {
        if frameCacheView == nil {
            frameCacheView = FrameCacheView()
            self.addSubview(frameCacheView)
            let wFrame:CGFloat = bounds.width
            let hFrame:CGFloat = 0.05 * min(bounds.width,bounds.height)
            let xFrame:CGFloat = 0
            let yFrame = self.bounds.height - hFrame
            frameCacheView.frame = CGRectMake(xFrame, yFrame, wFrame, hFrame)
            frameCacheView.image = image
        }
    }
    
    // MARK: Delegate Functions
    // MARK: XAnimatedImageDebug Delegate
    
    func debug_animatedImage(animatedImage: XAnimatedImage, didUpdateCachedFrames indexesOfFramesInCache: NSIndexSet) {
        frameCacheView.framesInCache = indexesOfFramesInCache
    }
    
    func debug_animatedImage(animatedImage: XAnimatedImage, didRequestCachedFrame index: Int) {
        
        if let _ = frameCacheView.requestedFrameIndex {
            if frameCacheView.requestedFrameIndex != index {
                frameCacheView.requestedFrameIndex = index
            }
        } else {
            frameCacheView.requestedFrameIndex = index
        }
        
        
    }
    
    func debug_animatedImage(animatedImage: XAnimatedImage, didDrawFrame size: CGFloat) {
        
    }
    
    // MARK: XAnimatedImageViewDebug Delegate
    
    func debug_animatedImageView(animatedImageView: XAnimatedImageView, waitingForFrame index: Int, withDuration duration: NSTimeInterval) {
        if let _ = currentFrameDelay {
            currentFrameDelay = currentFrameDelay + duration
        } else {
            currentFrameDelay = duration
        }
        
    }
    
    
}

