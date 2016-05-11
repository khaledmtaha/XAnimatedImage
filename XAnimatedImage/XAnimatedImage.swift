//
//  XAnimatedImage.swift
//  XAnimatedImage
//
//  Created by Khaled Taha on 11/24/15.
//  Copyright © 2015 Khaled Taha. All rights reserved.
//

import UIKit
import ImageIO
import MobileCoreServices
import QuartzCore

public class XAnimatedImage {
    
    // MARK: Properties
    
    private var once = dispatch_once_t()
    private lazy var serialQueue: dispatch_queue_t = dispatch_queue_create("com.X.framecachingqueue", DISPATCH_QUEUE_SERIAL)
    private var data:NSData!
    
    var allAnimatedImagesWeak:NSHashTable! // For custom dispatching of memory warnings to avoid deallocation races since NSNotificationCenter doesn't retain objects it is notifying.
    
    // Internal Data Structures
    
    private(set) var cachedFramesForIndexes = [Int:UIImage]()
    private(set) var cachedFrameIndexes:NSMutableIndexSet! // Indexes of cached frames
    private(set) var requestedFrameIndexes:NSMutableIndexSet! // Indexes of frames that are currently produced in the background
    
    private(set) var imageSource:CGImageSourceRef!
    
    private(set) public var loopCount:Int!
    
    private(set) public var posterImage:UIImage!
    private(set) public var size:CGSize!
    private(set) var posterImageFrameIndex:Int! // Index of non-purgable poster image; never changes
    
    private(set) public var delayTimesForIndexes = [Int:NSTimeInterval]()
    
    private(set) public var frameCount:Int!
    
    let MEGABYTE:CGFloat = 1024 * 1024
    
    private(set) var frameCacheSizeOptimal:Int! // The optimal number of frames to cache based on image size & number of frames; never changes
    
    private(set) var allFramesIndexSet:NSIndexSet! // Default index set with the full range of indexes; never changes
    
    private var requestedFrameIndex:Int!    // Most recently requested frame index
    
    weak var  debug_delegate:XAnimatedImageDebugDelegate? // Only intended to report internal state for debugging
    
    // An animated image's data size (dimensions * frameCount) category; its value is the max allowed memory (in MB).
    // E.g.: A 100x200px GIF with 30 frames is ~2.3MB in our pixel format and would fall into the `FLAnimatedImageDataSizeCategoryAll` category.
    
    enum DataSizeCategory: Int {
        case
        All = 10,       // All frames permanently in memory (be nice to the CPU)
        Default = 75,   // A frame cache of default size in memory (usually real-time performance and keeping low memory profile)
        OnDemand = 250 // Only keep one frame at the time in memory (easier on memory, slowest performance)
    }
    
    enum FrameCacheSize : Int {
        case
        NoLimit = 0,                // 0 means no specific limit
        LowMemory = 1,              // The minimum frame cache size; this will produce frames on-demand.
        GrowAfterMemoryWarning = 2, // If we can produce the frames faster than we consume, one frame ahead will already result in a
        Default = 5                 // Build up a comfy buffer window to cope with CPU hiccups etc.
    }
    
    // MARK: Accessors
    
    // This is the definite value the frame cache needs to size itself to.
    
    var frameCacheSizeCurrent: Int{
        get {
            let frameCacheSizeCurrent = self.frameCacheSizeOptimal
            return frameCacheSizeCurrent
        }
        
    }
    
    
    // MARK: Life Cycle
    
    init() {
        
    }
    
    private func initialize() {
        dispatch_once(&once) { () -> Void in
            // UIKit memory warning notification handler shared by all of the instances
            self.allAnimatedImagesWeak = NSHashTable(options: NSHashTableWeakMemory)
            NSNotificationCenter.defaultCenter().addObserverForName(UIApplicationDidReceiveMemoryWarningNotification, object: nil, queue: nil, usingBlock: { (note:NSNotification) -> Void in
                // UIKit notifications are posted on the main thread. didReceiveMemoryWarning: is expecting the main run loop, and we don't lock on allAnimatedImagesWeak
                assert(NSThread.isMainThread(), "Received memory warning on non-main thread")
                // Get a strong reference to all of the images. If an instance is returned in this array, it is still live and has not entered dealloc.
                // Note that FLAnimatedImages can be created on any thread, so the hash table must be locked.
                var images = [UIImage]()
                
                objc_sync_enter(self.allAnimatedImagesWeak)
                images = self.allAnimatedImagesWeak.allObjects as! [UIImage]
                objc_sync_exit(self.allAnimatedImagesWeak)
                // Now issue notifications to all of the images while holding a strong reference to them
                images.forEach({$0.performSelector(#selector(UIViewController.didReceiveMemoryWarning), withObject: note)})
                return
            })
        }
    }
    
    init (initWithAnimatedGIFData data:NSData) {
        
        initialize()
        
        // Early return if no data supplied!
        
        if data.length == 0 {
            print("No data supplied")
        }
        
        // Do one-time initializations of `readonly` properties directly to ivar to prevent implicit actions and avoid need for private `readwrite` property overrides.
        
        // Keep a strong reference to `data` and expose it read-only publicly.
        // However, we will use the `_imageSource` as handler to the image data throughout our life cycle.
        
        self.data = data
        
        // Initialize internal data structures
        
        self.cachedFramesForIndexes = [Int:UIImage]()
        self.cachedFrameIndexes = NSMutableIndexSet()
        self.requestedFrameIndexes = NSMutableIndexSet()
        
        imageSource = CGImageSourceCreateWithData(data, nil)
        
        // Early return on failure!
        
        if imageSource == nil {
            print("Failed to `CGImageSourceCreateWithData` for animated GIF data")
            return
        }
        
        // Early return if not GIF!
        
        let imageSourceContainerType = CGImageSourceGetType(imageSource)
        let isGIFData = UTTypeConformsTo(imageSourceContainerType!, kUTTypeGIF)
        if !isGIFData {
            print("Supplied data is of type \(CGImageSourceGetType(imageSource))and doesn't seem to be GIF data")
            return
        }
        
        // Get `LoopCount`
        
        let imageProperties = CGImageSourceCopyProperties(imageSource,nil)! as NSDictionary
        loopCount = imageProperties.objectForKey(kCGImagePropertyGIFDictionary)?.objectForKey(kCGImagePropertyGIFLoopCount) as! Int
        
        // Iterate through frame images
        
        let imageCount = CGImageSourceGetCount(imageSource)
        var skippedFrameCount: Int = 0
        
        for i in 0..<imageCount {
            let frameImageRef = CGImageSourceCreateImageAtIndex(imageSource, i, nil)
            if let _ = frameImageRef {
                let frameImage = UIImage(CGImage: frameImageRef!)
                
                // Check for valid `frameImage` before parsing its properties as frames can be corrupted (and `frameImage` even `nil` when `frameImageRef` was valid).
                
                if let _ = frameImage as AnyObject? {
                    
                    if posterImage == nil {
                        //Set poster image
                        
                        posterImage = frameImage
                        
                        // Set its size to proxy our size.
                        
                        size = posterImage.size
                        
                        // Remember index of poster image so we never purge it; also add it to the cache.
                        
                        posterImageFrameIndex = i
                        cachedFramesForIndexes[posterImageFrameIndex] = posterImage
                        cachedFrameIndexes.addIndex(self.posterImageFrameIndex)
                        
                    }
                    
                    
                }
                
                // Get `DelayTime`
                
                let frameProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, i , nil)! as NSDictionary
                let framePropertiesGIF = frameProperties.objectForKey(kCGImagePropertyGIFDictionary)
                
                // Try to use the unclamped delay time; fall back to the normal delay time.
                // If we don't get a delay time from the properties, fall back to `kDelayTimeIntervalDefault`
                
                var delayTime:NSTimeInterval!
                let kDelayTimeIntervalDefault:NSTimeInterval = 0.1
                if let time = framePropertiesGIF?.objectForKey(kCGImagePropertyGIFUnclampedDelayTime) as! Double? {
                    delayTime = time
                } else if let time = framePropertiesGIF?.objectForKey(kCGImagePropertyGIFDelayTime) as! Double?{
                    delayTime = time
                } else {
                    if i == 0 {
                        delayTime = kDelayTimeIntervalDefault
                    } else {
                        delayTime = delayTimesForIndexes[i - 1]
                    }
                }
                
                // Support frame delays as low as `kDelayTimeIntervalMinimum`, with anything below being rounded up to `kDelayTimeIntervalDefault` for legacy compatibility.
                // This is how the fastest browsers do it as per 2012: http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser-compatibility
                
                let kDelayTimeIntervalMinimum:NSTimeInterval = 0.02
                
                // To support the minimum even when rounding errors occur, use an epsilon when comparing. We downcast to float because that's what we get for delayTime from ImageIO.
                
                if Float(delayTime) < Float(kDelayTimeIntervalMinimum) - FLT_EPSILON {
                    print("Rounding frame \(i)'s `delayTime` from \(delayTime)  up to default \(kDelayTimeIntervalDefault) (minimum supported: \(kDelayTimeIntervalMinimum)).")
                    delayTime = kDelayTimeIntervalDefault
                }
                
                delayTimesForIndexes[i] = delayTime
                
            } else {
                skippedFrameCount += 1
                print("Dropping frame \(i) because valid `CGImageRef` \(frameImageRef) did result in `nil`-`UIImage`.")
            }
            
        }
        
        frameCount = imageCount
        
        if frameCount == 0 {
            print("Failed to create any valid frames for GIF with properties \(imageProperties)")
        } else if frameCount == 1 {
            // Warn when we only have a single frame but return a valid GIF.
            print("Created valid GIF but with only a single frame. Image properties: \(imageProperties)")
        } else {
            // We have multiple frames, rock on!
        }
        
        // Calculate the optimal frame cache size: try choosing a larger buffer window depending on the predicted image size.
        // It's only dependent on the image size & number of frames and never changes.
        
        let animatedImageDataSize = CGFloat(CGImageGetBytesPerRow(self.posterImage.CGImage) * Int(self.size.height) * (self.frameCount - skippedFrameCount)) / MEGABYTE
        
        if animatedImageDataSize <= CGFloat(XAnimatedImage.DataSizeCategory.All.rawValue) {
            // All frames permanently in memory (be nice to the CPU) == 10
            frameCacheSizeOptimal = frameCount
        } else if animatedImageDataSize <= CGFloat(XAnimatedImage.DataSizeCategory.Default.rawValue) {
            // A frame cache of default size in memory (usually real-time performance and keeping low memory profile) == 75
            frameCacheSizeOptimal = XAnimatedImage.FrameCacheSize.Default.rawValue
        } else if animatedImageDataSize <= CGFloat(XAnimatedImage.DataSizeCategory.OnDemand.rawValue) {
            // Only keep one frame at the time in memory (easier on memory, slowest performance) == 250
            frameCacheSizeOptimal = XAnimatedImage.FrameCacheSize.LowMemory.rawValue
        } else {
            // Even for one frame too large, computer says no. > 250
            print("GIF File is too large, the program will continue to execute but memory problems may appear. Size: \(animatedImageDataSize)")
            frameCacheSizeOptimal = XAnimatedImage.FrameCacheSize.LowMemory.rawValue
        }
        
        // In any case, cap the optimal cache size at the frame count.
        
        frameCacheSizeOptimal = Int(min(frameCount, frameCacheSizeOptimal))
        
        // Convenience/minor performance optimization; keep an index set handy with the full range to return in `-frameIndexesToCache`.
        
        allFramesIndexSet = NSIndexSet(indexesInRange: NSMakeRange(0, frameCount))
        
        // Register this instance in the weak table for memory notifications. The NSHashTable will clean up after itself when we're gone.
        // Note that FLAnimatedImages can be created on any thread, so the hash table must be locked.
        
        objc_sync_enter(allAnimatedImagesWeak)
        
        allAnimatedImagesWeak = NSHashTable()
        allAnimatedImagesWeak.addObject(self)
        
        objc_sync_exit(allAnimatedImagesWeak)
        
        
    }
    
    // See header for more details.
    // Note: both consumer and producer are throttled: consumer by frame timings and producer by the available memory (max buffer window size).
    
    func imageLazilyCachedAtIndex(index:Int) -> UIImage? {
        
        // Early return if the requested index is beyond bounds.
        // Note: We're comparing an index with a count and need to bail on greater than or equal to.
        
        if index >= self.frameCount {
            print("Skipping requested frame %lu beyond bounds (total frame count: \(index)) for animated image: \(frameCount)")
        }
        
        // Remember requested frame index, this influences what we should cache next.
        self.requestedFrameIndex = index
        
        self.debug_delegate?.debug_animatedImage(self, didRequestCachedFrame: index)
        
        // Quick check to avoid doing any work if we already have all possible frames cached, a common case.
        if cachedFramesForIndexes.count < self.frameCount {
            let frameIndexesToAddToCacheMutable = frameIndexesToCache().mutableCopy()
            
            // Flush existing indexes
            
            frameIndexesToAddToCacheMutable.removeIndexes(cachedFrameIndexes)
            frameIndexesToAddToCacheMutable.removeIndexes(requestedFrameIndexes)
            frameIndexesToAddToCacheMutable.removeIndex(posterImageFrameIndex)
            
            let frameIndexesToAddToCache = frameIndexesToAddToCacheMutable.copy() as! NSIndexSet
            
            if frameIndexesToAddToCache.count > 0 {
                self.addFrameIndexesToCache(frameIndexesToAddToCache)
            }
        }
        
        let image = cachedFramesForIndexes[index]
        purgeFrameCacheIfNeeded()
        return image
    }
    
    // Only called once from `-imageLazilyCachedAtIndex` but factored into its own method for logical grouping.
    
    func addFrameIndexesToCache(frameIndexesToAddToCache:NSIndexSet) {
        
        // Order matters. First, iterate over the indexes starting from the requested frame index.
        // Then, if there are any indexes before the requested frame index, do those.
        
        let firstRange = NSMakeRange(self.requestedFrameIndex, self.frameCount - self.requestedFrameIndex)
        let secondRange = NSMakeRange(0, self.requestedFrameIndex)
        
        if firstRange.length + secondRange.length != self.frameCount {
            print("Two-part frame cache range doesn't equal full range.")
        }
        
        // Add to the requested list before we actually kick them off, so they don't get into the queue twice.
        
        requestedFrameIndexes.addIndexes(frameIndexesToAddToCache)
        
        // Start streaming requested frames in the background into the cache.
        // Avoid capturing self in the block as there's no reason to keep doing work if the animated image went away.
        
        weak var weakSelf = self
        
        // TODO: Ensure that the GCD is setup in the most efficient way possible.
        
        // Produce and cache next needed frame.
        
        dispatch_async(serialQueue) { () -> Void in
            
            let frameRangeBlock : (NSRange, UnsafeMutablePointer<ObjCBool>) -> Void = { (range, stop) in
                // Iterate through contiguous indexes; can be faster than `enumerateIndexesInRange:options:usingBlock:`. - TEST REQUIRED
                for i in range.location..<NSMaxRange(range) {
                    
                    let image = weakSelf?.predrawnImageAtIndex(i)
                    
                    // The results get returned one by one as soon as they're ready (and not in batch).
                    // The benefits of having the first frames as quick as possible outweigh building up a buffer to cope with potential hiccups when the CPU suddenly gets busy.
                    
                    // TODO: Dispatch asyncrhonously on main queue
                    
                    
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        weakSelf?.cachedFramesForIndexes[i] = image
                    })
                    
                    weakSelf?.cachedFrameIndexes.addIndex(i)
                    weakSelf?.requestedFrameIndexes.removeIndex(i)
                    
                    
                    weakSelf?.debug_delegate?.debug_animatedImage(weakSelf!, didUpdateCachedFrames: (weakSelf?.cachedFrameIndexes)!)
                }
            }
            
            frameIndexesToAddToCache.enumerateRangesInRange(firstRange, options: NSEnumerationOptions.Concurrent, usingBlock: frameRangeBlock)
            frameIndexesToAddToCache.enumerateRangesInRange(secondRange, options: NSEnumerationOptions.Concurrent, usingBlock: frameRangeBlock)
            
            
        }
        
        
        
        
    }
    
    
    // MARK: Public Methods
    
    
    
    // MARK: Frame Loading
    
    func predrawnImageAtIndex(index:Int) -> UIImage {
        
        // It's very important to use the cached `imageSource` since the random access to a frame with `CGImageSourceCreateImageAtIndex` turns from an O(1) into an O(n) operation when re-initializing the image source every time.
        let imageRef = CGImageSourceCreateImageAtIndex(imageSource, index, nil)
        var image = UIImage(CGImage: imageRef!)
        
        // Loading in the image object is only half the work, the displaying image view would still have to synchronosly wait and decode the image, so we go ahead and do that here on the background thread.
        weak var klass = self
        image = klass!.predrawnImageFromImage(image)!
        
        
        return image
        
    }
    // MARK: Frame Caching
    
    func frameIndexesToCache () -> NSIndexSet {
        
        // Returns an index set of all the frame indexes for caching
        
        var indexesToCache = NSIndexSet()
        
        // Quick check: Avoid building the index set unnecessarily if the 'number of frames to cache' = 'total frame count'.
        
        if frameCacheSizeCurrent ==  frameCount {
            indexesToCache = allFramesIndexSet
        } else {
            let indexesToCacheMutable = NSMutableIndexSet()
            
            // Add indexes to the set in two separate blocks- the first starting from the requested frame index, up to the limit or the end.
            // The second, if needed, the remaining number of frames beginning at index zero.
            
            // -----*-------------------------------*------
            //  secondLength                    firstLength
            
            // 1 - Calculate Lengths
            
            let firstLength = min(frameCacheSizeCurrent, frameCount - self.requestedFrameIndex)
            let secondLength = self.frameCacheSizeCurrent - firstLength
            
            // 2 - Add Range(s)
            
            let firstRange = NSMakeRange(self.requestedFrameIndex, firstLength)
            indexesToCacheMutable.addIndexesInRange(firstRange)
            
            if (secondLength > 0) {
                let secondRange = NSMakeRange(0, secondLength)
                indexesToCacheMutable.addIndexesInRange(secondRange)
            }
            
            // 3 - Double check our math, before we add the poster image index which may increase it by one.
            
            if indexesToCacheMutable.count != self.frameCacheSizeCurrent {
                print("Number of frames to cache doesn't equal expected cache size.")
            }
            
            indexesToCacheMutable.addIndex(posterImageFrameIndex)
            indexesToCache = indexesToCacheMutable.copy() as! NSIndexSet
            
        }
        
        
        
        return indexesToCache
    }
    
    func purgeFrameCacheIfNeeded () {
        // Purge frames that are currently cached but don't need to be.
        // But not if we're still under the number of frames to cache.
        // This way, if all frames are allowed to be cached (the common case), we can skip all the `NSIndexSet` math below.
        
        if cachedFrameIndexes.count > frameCacheSizeCurrent {
            let indexesToPurge = cachedFrameIndexes.mutableCopy()
            indexesToPurge.removeIndexes(self.frameIndexesToCache())
            indexesToPurge.enumerateRangesUsingBlock({ (range, stop) -> Void in
                // Iterate through contiguous indexes; can be faster than `enumerateIndexesInRange:options:usingBlock:`.
                for i in range.location..<NSMaxRange(range) {
                    self.cachedFrameIndexes.removeIndex(i)
                    self.cachedFramesForIndexes.removeValueForKey(i)
                    
                    // Note: Don't `CGImageSourceRemoveCacheAtIndex` on the image source for frames that we don't want cached any longer to maintain O(1) time access.
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.debug_delegate?.debug_animatedImage(self, didUpdateCachedFrames: self.cachedFrameIndexes)
                    })
                    
                }
                
            })
        }
    }
    
    // MARK: System Memory Warnings Notification Handler
    
    // MARK: Image Decoding
    
    // Decodes the image's data and draws it off-screen fully in memory; it's thread-safe and hence can be called on a background thread.
    // On success, the returned object is a new `UIImage` instance with the same content as the one passed in.
    // On failure, the returned object is the unchanged passed in one; the data will not be predrawn in memory though and an error will be logged.
    // First inspired by & good Karma to: https://gist.github.com/steipete/1144242
    
    func predrawnImageFromImage(imageToPredraw:UIImage) -> UIImage? {
        
        // Always use a device RGB color space for simplicity and predictability what will be going on.
        let colorSpaceDeviceRGBRef = CGColorSpaceCreateDeviceRGB()
        
        // Early return on failure!
        
        if colorSpaceDeviceRGBRef == nil {
            print("Failed to `CGColorSpaceCreateDeviceRGB` for image: \(imageToPredraw)")
            return nil
        }
        
        // Even when the image doesn't have transparency, we have to add the extra channel because Quartz doesn't support other pixel formats than 32 bpp/8 bpc for RGB:
        // kCGImageAlphaNoneSkipFirst, kCGImageAlphaNoneSkipLast, kCGImageAlphaPremultipliedFirst, kCGImageAlphaPremultipliedLast
        // (source: docs "Quartz 2D Programming Guide > Graphics Contexts > Table 2-1 Pixel formats supported for bitmap graphics contexts") - Latest Checked Date: Nov 1st 2015
        
        let numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpaceDeviceRGBRef) + 1 // [RGB + A] - The number of color components in the specified color space, not including the alpha value. For example, for an RGB color space, CGColorSpaceGetNumberOfComponents returns a value of 3.
        
        let width = imageToPredraw.size.width
        let height = imageToPredraw.size.height
        let bitsPerComponent = Int(CHAR_BIT)
        
        let bitsPerPixel = bitsPerComponent * numberOfComponents
        let bytesPerPixel = bitsPerPixel/Int(BYTE_SIZE)
        let bytesPerRow = bytesPerPixel * Int(width)
        
        dispatch_async(dispatch_queue_create("com.X.memoryUsage", DISPATCH_QUEUE_SERIAL)) { () -> Void in
            var bytesPerRowForSize:CGFloat!
            if bytesPerRow % 16 == 0 {
                bytesPerRowForSize = CGFloat(((bytesPerRow / 16) + 1) * 16)
            } else {
                bytesPerRowForSize = CGFloat(bytesPerRow)
            }
            
            let dataSize = ((height) * bytesPerRowForSize)/(1024*1024)
            self.debug_delegate?.debug_animatedImage(self, didDrawFrame: dataSize)
        }
        
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo.ByteOrderDefault
        
        var alphaInfo = CGImageGetAlphaInfo(imageToPredraw.CGImage)
        
        // If the alpha info doesn't match to one of the supported formats (see above), pick a reasonable supported one.
        // "For bitmaps created in iOS 3.2 and later, the drawing environment uses the premultiplied ARGB format to store the bitmap data." (source: docs)
        
        switch alphaInfo {
        case .None, .Only:
            alphaInfo = CGImageAlphaInfo.NoneSkipFirst
        case .First:
            alphaInfo = CGImageAlphaInfo.PremultipliedFirst
        case .Last:
            alphaInfo = CGImageAlphaInfo.PremultipliedLast
        default:
            break
        }
        
        // "The constants for specifying the alpha channel information are declared with the `CGImageAlphaInfo` type but can be passed to this parameter safely." (source: docs)
        
        let info = bitmapInfo.rawValue | alphaInfo.rawValue
        
        // Create our own graphics context to draw to; `UIGraphicsGetCurrentContext`/`UIGraphicsBeginImageContextWithOptions` doesn't create a new context but returns the current one which isn't thread-safe (e.g. main thread could use it at the same time).
        // Note: It's not worth caching the bitmap context for multiple frames ("unique key" would be `width`, `height` and `hasAlpha`), it's ~50% slower. Time spent in libRIP's `CGSBlendBGRA8888toARGB8888` suddenly shoots up -- not sure why.
        
        let bitmapContextRef = CGBitmapContextCreate(nil, Int(width), Int(height), bitsPerComponent, bytesPerRow, colorSpaceDeviceRGBRef, info)
        
        // Early return on failure!
        
        if bitmapContextRef == nil {
            print("Failed to `CGBitmapContextCreate` with color space \(colorSpaceDeviceRGBRef) and parameters (width: \(width) height: \(height) bitsPerComponent: \(bitsPerComponent) bytesPerRow: \(bytesPerRow)) for image \(imageToPredraw)")
            return nil
        }
        
        // Draw image in bitmap context and create image by preserving receiver's properties.
        
        CGContextDrawImage(bitmapContextRef, CGRectMake(0, 0, imageToPredraw.size.width, imageToPredraw.size.height), imageToPredraw.CGImage)
        let predrawnImageRef = CGBitmapContextCreateImage(bitmapContextRef)
        let predrawnImage = UIImage(CGImage: predrawnImageRef!, scale: imageToPredraw.scale, orientation: imageToPredraw.imageOrientation)
        
        
        return predrawnImage
        
    }
    
    // MARK: Description
    
}

protocol XAnimatedImageDebugDelegate:class {
    func debug_animatedImage(animatedImage:XAnimatedImage, didUpdateCachedFrames indexesOfFramesInCache:NSIndexSet)
    func debug_animatedImage(animatedImage:XAnimatedImage, didRequestCachedFrame index:Int)
    func debug_animatedImage(animatedImage:XAnimatedImage, didDrawFrame size:CGFloat)
    
    // TODO: Add support for func debug_animatedImagePredrawingSlowdownFactor...
    /*
    func debug_animatedImagePredrawingSlowdownFactor(animatedImage:XAnimatedImage) -> CGFloat?
    */
}


