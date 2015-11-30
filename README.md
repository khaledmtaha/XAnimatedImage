
![XAnimatedImage: Performant animated GIF engine for iOS (`FLAnimatedImage` in Swift)](http://i.imgur.com/UIGV69u.png)

[![Platform](https://img.shields.io/badge/platform-ios-lightgrey.svg)]()

`XAnimatedImage` is a performant animated GIF engine for iOS written in Swift based on [`FLAnimatedImage`](https://github.com/Flipboard/FLAnimatedImage). An illustration is shown below:

![XAnimatedImage playing multiple GIFs](http://i.imgur.com/mU1zR3J.gif)

## Features

- [x] Plays multiple GIFs simultaneously with a playback speed comparable to desktop browsers
- [x] Honors variable frame delays
- [x] Eliminates delays or blocking during the first playback loop
- [x] Interprets the frame delays of fast GIFs the same way modern browsers do
 
## Who is this for?

- Apps that don't support animated GIFs yet
- Apps that already support animated GIFs but want a higher performance solution
- People who want to tinker with the code ([the corresponding blog post](http://engineering.flipboard.com/2014/05/animated-gif/) describing the original [FLAnimatedImage](https://github.com/Flipboard/FLAnimatedImage) repo is a great place to start; also see the *To Do* section below)

## Requirements

- iOS 7.1+ 
- Xcode 7.1+

## Installation

`XAnimatedImage`, like it's original counterpart [`FLAnimatedImage`](https://github.com/Flipboard/FLAnimatedImage), is a well encapsulated drop-in component. Simply replace your `UIImageView` instances with instances of `XAnimatedImageView` to get animated GIF support. There is no central cache or state to manage.

### Manually

You can integrate XAnimatedImage into your project manually.
You can do it by copying the "Classes" folder in your project (make sure that "Create groups" option is selected).

### Other

Other installation methods are currently being integrated into the project. Currently, this repository supports only manual installation. Planned, future installation methods will include:

- CocoaPods
- Carthage

##Usage

```swift
var animatedImage = XAnimatedImage(initWithAnimatedGIFData: NSData(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("example", ofType: "gif")!))!)
var animatedImageView = XAnimatedImageView()
animatedImageView.animatedImage = animatedImage
animatedImageView.frame = CGRectMake(0,0,100,100)
self.view.addSubview(animatedImageView)
```

##To Do

- Support other animated image formats such as APNG or WebP
- Integration into network libraries and image caches
- Investigate whether `FLAnimatedImage` should become a `UIImage` subclass
- Smarter buffering
- Investigate the usage of `GPUImage` for less CPU intensive image processing.
- Support `CocoaPods` and `Carthage` for installation methods.

##Contributions

This project owes most in part to the original [`FLAnimatedImage`](https://github.com/Flipboard/FLAnimatedImage) [contributors](https://github.com/Flipboard/FLAnimatedImage/graphs/contributors) namely Raphael Schaad ([github](https://github.com/raphaelschaad) | [@raphaelschaad](https://twitter.com/raphaelschaad)). 

If there any issues to be directed at me, you can reach me, Khaled Taha, [@iamktothed](https://twitter.com/iamktothed). 

