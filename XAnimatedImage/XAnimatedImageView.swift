//
//  XAnimatedImageView.swift
//  XAnimatedImage
//
//  Created by Khaled Taha on 11/24/15.
//  Copyright © 2015 Khaled Taha. All rights reserved.
//

import UIKit

class XAnimatedImageView: UIImageView {
    
    //  An `FLAnimatedImageView` can take an `FLAnimatedImage` and plays it automatically when in view hierarchy and stops when removed.
    //  The animation can also be controlled with the `UIImageView` methods `-start/stop/isAnimating`.
    //  It is a fully compatible `UIImageView` subclass and can be used as a drop-in component to work with existing code paths expecting to display a `UIImage`.
    //  Under the hood it uses a `CADisplayLink` for playback, which can be inspected with `currentFrame` & `currentFrameIndex`.
    
    // Setting `[UIImageView.image]` to a non-`nil` value clears out existing `animatedImage`.
    // And vice versa, setting `animatedImage` will initially populate the `[UIImageView.image]` to its `posterImage` and then start animating and hold `currentFrame`.
    
    // MARK: Properties
    
    var currentFrame:UIImage!
    var currentFrameIndex:Int = 0
    
    var loopCountdown:Int!
    var accumulator:NSTimeInterval!
    var displayLink:CADisplayLink!
    
    var shouldAnimate:Bool = false // Before checking this value, call `-updateShouldAnimate` whenever the animated image, window or superview has changed.
    var needsDisplayWhenImageBecomesAvailable:Bool?
    
    weak var debug_delegate : XAnimatedImageViewDebugDelegate? // Only intended to report internal state for debugging
    
    // MARK: - Accessors
    // MARK: Public
    
    var animatedImage: XAnimatedImage! {
        
        // TODO: Tidy up this code to become simpler and way less convoluted.
        
        didSet {
            if oldValue != nil {
                if (animatedImage as AnyObject).hashValue != (oldValue as AnyObject).hashValue {
                    if animatedImage != nil {
                        // Clear out the image.
                        super.image = nil
                        // Ensure disabled highlighting; it's not supported (see `-setHighlighted:`).
                        super.highlighted = false
                        // UIImageView seems to bypass some accessors when calculating its intrinsic content size, so this ensures its intrinsic content size comes from the animated image.
                        self.invalidateIntrinsicContentSize()
                    } else {
                        // Stop animating before the animated image gets cleared out.
                        self.stopAnimating()
                    }
                    
                    self.currentFrame = animatedImage!.posterImage
                    self.currentFrameIndex = 0
                    if animatedImage.loopCount > 0 {
                        self.loopCountdown = animatedImage.loopCount
                    } else {
                        self.loopCountdown = LONG_MAX
                    }
                    
                    self.accumulator = 0
                    
                    // Start animating after the new animated image has been set.
                    
                    self.updateShouldAnimate()
                    if shouldAnimate {
                        self.startAnimating()
                    }
                    
                    self.layer.setNeedsDisplay()
                }
            } else {
                if animatedImage != nil {
                    // Clear out the image.
                    super.image = nil
                    // Ensure disabled highlighting; it's not supported (see `-setHighlighted:`).
                    super.highlighted = false
                    // UIImageView seems to bypass some accessors when calculating its intrinsic content size, so this ensures its intrinsic content size comes from the animated image.
                    self.invalidateIntrinsicContentSize()
                } else {
                    // Stop animating before the animated image gets cleared out.
                    self.stopAnimating()
                }
                
                self.currentFrame = animatedImage!.posterImage
                self.currentFrameIndex = 0
                if animatedImage.loopCount > 0 {
                    self.loopCountdown = animatedImage.loopCount
                } else {
                    self.loopCountdown = LONG_MAX
                }
                
                self.accumulator = 0
                
                // Start animating after the new animated image has been set.
                
                self.updateShouldAnimate()
                if shouldAnimate {
                    self.startAnimating()
                }
                
            }
            
        }
    }
    
    
    
    // MARK: - Life Cycle
    
    deinit {
        //        displayLink.invalidate()
    }
    
    // MARK: - UIView Method Overrides
    // MARK: Observing View-Related Changes
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        self.updateShouldAnimate()
        if self.shouldAnimate {
            self.startAnimating()
        } else {
            self.stopAnimating()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        self.updateShouldAnimate()
        if self.shouldAnimate {
            self.startAnimating()
        } else {
            self.stopAnimating()
        }
    }
    
    
    // MARK: Autolayout
    
    override func intrinsicContentSize() -> CGSize {
        
        // Default to let UIImageView handle the sizing of its image, and anything else it might consider.
        
        var intrinsicContentSize = super.intrinsicContentSize()
        
        // If we have have an animated image, use its image size.
        // UIImageView's intrinsic content size seems to be the size of its image. The obvious approach, simply calling `-invalidateIntrinsicContentSize` when setting an animated image, results in UIImageView steadfastly returning `{UIViewNoIntrinsicMetric, UIViewNoIntrinsicMetric}` for its intrinsicContentSize.
        // (Perhaps UIImageView bypasses its `-image` getter in its implementation of `-intrinsicContentSize`, as `-image` is not called after calling `-invalidateIntrinsicContentSize`.)
        
        if self.animatedImage != nil {
            intrinsicContentSize = self.image!.size
        }
        
        return intrinsicContentSize
    }
    
    // MARK: - UIImageView Method Overrides
    // MARK: Image Data
    
    override var image:UIImage? {
        get {
            var imageToReturn = UIImage()
            if self.animatedImage != nil {
                imageToReturn = self.currentFrame
            } else {
                imageToReturn = super.image!
            }
            return imageToReturn
            
        } set {
            if image != nil {
                // Clear out the animated image and implicitly pause animation playback.
                self.animatedImage = nil
            }
            
            super.image = image
        }
        
    }
    
    // MARK: Animating Images
    
    override func startAnimating() {
        if self.animatedImage != nil {
            // Lazily create the display link.
            if self.displayLink == nil {
                // It is important to note the use of a weak proxy here to avoid a retain cycle. `-displayLinkWithTarget:selector:`
                // will retain its target until it is invalidated. We use a weak proxy so that the image view will get deallocated
                // independent of the display link's lifetime. Upon image view deallocation, we invalidate the display
                // link which will lead to the deallocation of both the display link and the weak proxy.
                
                let weakProxy:XWeakProxy = XWeakProxy(weakProxyForObject: self)
                self.displayLink = CADisplayLink(target: weakProxy, selector: "displayDidRefresh:")
                
                // Enable playback during scrolling by allowing timer events (i.e. animation) with `NSRunLoopCommonModes`.
                // But too keep scrolling smooth, only do this for hardware with more than one core and otherwise keep it at the default `NSDefaultRunLoopMode`.
                // The only devices with single-core chips (supporting iOS 6+) are iPhone 3GS/4 and iPod Touch 4th gen.
                // Key off `activeProcessorCount` (as opposed to `processorCount`) since the system could shut down cores in certain situations.
                
                let mode : String = {
                    
                    var modeToReturn =  NSDefaultRunLoopMode
                    
                    if NSProcessInfo.processInfo().activeProcessorCount > 1 {
                        modeToReturn = NSRunLoopCommonModes
                    }
                    
                    return modeToReturn
                }()
                
                // Note: The display link's `.frameInterval` value of 1 (default) means getting callbacks at the refresh rate of the display (~60Hz).
                // Setting it to 2 divides the frame rate by 2 and hence calls back at every other frame.
                
                self.displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: mode)
            }
            self.displayLink.paused = false
            
        } else {
            super.startAnimating()
        }
    }
    
    
    override func stopAnimating() {
        if self.animatedImage != nil {
            if displayLink != nil {
                self.displayLink.paused = true
            }
            
        } else {
            super.stopAnimating()
        }
    }
    
    override func isAnimating() -> Bool {
        var isAnimating = false
        if self.animatedImage != nil {
            isAnimating = self.displayLink != nil && !self.displayLink.paused ? true : false
        }
        return isAnimating
    }
    
    // MARK: Highlight Image Support
    
    override var highlighted:Bool {
        didSet {
            // Highlighted image is unsupported for animated images, but implementing it breaks the image view when embedded in a UICollectionViewCell.
            if self.animatedImage == nil {
                super.highlighted = true
            }
        }
    }
    
    // MARK: - Private Methods
    // MARK: Animation
    
    // Don't repeatedly check our window & superview in `-displayDidRefresh:` for performance reasons.
    // Just update our cached value whenever the animated image, window or superview is changed.
    
    func updateShouldAnimate() {
        self.shouldAnimate = self.animatedImage != nil && self.window != nil && self.superview != nil ? true : false
    }
    
    func displayDidRefresh(displayLink:CADisplayLink) {
        
        // If for some reason a wild call makes it through when we shouldn't be animating, bail.
        // Early return!
        
        if self.shouldAnimate == false {
            print("Trying to animate image when we shouldn't")
            return
        }
        
        let delayTimeNumber = self.animatedImage.delayTimesForIndexes[currentFrameIndex]
        // If we don't have a frame delay (e.g. corrupt frame), don't update the view but skip the playhead to the next frame (in else-block).
        
        if delayTimeNumber != nil {
            
            
            let delayTime = Float(delayTimeNumber!)
            let image:UIImage? = self.animatedImage.imageLazilyCachedAtIndex(currentFrameIndex)
            
            self.currentFrame = image
            
            if image != nil {
                if let _ = self.needsDisplayWhenImageBecomesAvailable {
                    self.layer.setNeedsDisplay()
                    self.needsDisplayWhenImageBecomesAvailable = false
                }
            } else {
                
                debug_delegate?.debug_animatedImageView(self, waitingForFrame: self.currentFrameIndex, withDuration: self.displayLink.duration)
            }
            
            
            self.accumulator = self.accumulator + Double(displayLink.duration)
            
            
            while self.accumulator >= NSTimeInterval(delayTime) {
                self.accumulator = self.accumulator - NSTimeInterval(delayTime)
                self.currentFrameIndex++
                if self.currentFrameIndex >= self.animatedImage.frameCount {
                    // If we've looped the number of times that this animated image describes, stop looping.
                    loopCountdown = loopCountdown - 1
                    
                    if self.loopCountdown == 0 {
                        self.stopAnimating()
                        return
                    }
                    self.currentFrameIndex = 0
                }
                
                // Calling `-setNeedsDisplay` will just paint the current frame, not the new frame that we may have moved to.
                // Instead, set `needsDisplayWhenImageBecomesAvailable` to `YES` -- this will paint the new image once loaded.
                self.needsDisplayWhenImageBecomesAvailable = true
                
            }
        } else {
            self.currentFrameIndex++
        }
        
    }
    
    
    // MARK: - CALayerDelegate (Informal)
    // MARK: Providing the Layer's Content
    
    override func displayLayer(layer: CALayer) {
        layer.contents = self.image?.CGImage
    }
    
    
}

protocol XAnimatedImageViewDebugDelegate: class {
    func debug_animatedImageView(animatedImageView:XAnimatedImageView, waitingForFrame index:Int, withDuration duration:NSTimeInterval)
}
