//
//  ViewController.swift
//  SepView
//
//  Copyright (c) 2014 Tomohiko Himura. All rights reserved.
//

import UIKit
import QuartzCore
import CoreMotion

func randf() -> CGFloat {
    return CGFloat(rand()) / CGFloat(RAND_MAX)
}

class BoxViewCreator {
    let animator: UIDynamicAnimator
    let view: UIView = UIView()
    let gravity: UIGravityBehavior = UIGravityBehavior()
    var objs: [UIView] = []
    var collison: UICollisionBehavior = UICollisionBehavior()

    init () {
        animator = UIDynamicAnimator(referenceView: view)
        animator.addBehavior(gravity)
    }

    func createView() {
        UIViewAutoresizing.None;
        let size = 4
        let saturation: CGFloat = randf()
        for i in 0..<size {
            let obj = UIView()
            let width: CGFloat = randf() * 15 + 10
            let height: CGFloat = randf() * 15 + 10
            obj.frame = CGRectMake(CGFloat(i+14),CGFloat(i+14),width,height)
            obj.backgroundColor = UIColor(hue: randf() , saturation: 0.3, brightness: 0.7, alpha: 0.6)
            view.addSubview(obj)
            gravity.addItem(obj)
            collison.addItem(obj)
            objs.append(obj)
        }
        collison.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collison)
    }

    func accelerometerHandler(data: CMAccelerometerData!,error: NSError! ) {
        let x: CDouble = data.acceleration.x
        let y: CDouble = data.acceleration.y
        if x != 0 {
            gravity.angle = CGFloat(atan2(-y, x))
            gravity.magnitude = CGFloat(sqrt(y*y + x*x))
        }
    }

    func reset() {
        for obj in objs {
            obj.removeFromSuperview()
            gravity.removeItem(obj)
            collison.removeItem(obj)
        }
        objs.removeAll(keepCapacity: false)
    }
}

class ViewController: UIViewController {
    let mainView: UIView = UIView()
    var imageViews: [UIImageView] = []
    let motionManager: CMMotionManager = CMMotionManager()
    let creators: [BoxViewCreator] = [BoxViewCreator(),BoxViewCreator()]
    var secondWindow: UIWindow? = nil
    var size: NSInteger = 1

    class func capturedImageWithView (views: [UIView]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(views[0].bounds.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        CGContextSetBlendMode(ctx,kCGBlendModePlusLighter)
        for view : UIView in views {
            let layer : AnyObject! = view.layer
            layer.renderInContext(ctx)
            CGContextTranslateCTM(ctx, views[0].bounds.size.width/2, views[0].bounds.size.height/2)
            CGContextRotateCTM(ctx, CGFloat(M_PI))
            CGContextTranslateCTM(ctx, -views[0].bounds.size.width/2, -views[0].bounds.size.height/2)
        }
        let tempImg = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRestoreGState(ctx);
        UIGraphicsEndImageContext();
        return tempImg;
    }

    init(coder aDecoder: NSCoder!) {
        super.init(coder: aDecoder)
    }
                            
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpScreenConnectionNotificationHandlers()
        checkForExistingScreenAndInitilaizePresent()
        srand(CUnsignedInt(time(nil)))
        self.view.backgroundColor = UIColor.blackColor()
        // Do any additional setup after loading the view, typically from a nib.
        motionManager.accelerometerUpdateInterval = 0.04;
        for creator: BoxViewCreator in creators {
           creator.createView();
        }

        if (self.motionManager.accelerometerAvailable) {
            let handler: CMAccelerometerHandler = { data, error in
                for creator: BoxViewCreator in self.creators {
                    creator.accelerometerHandler(data, error: error)
                }
            }
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:handler)
            
            let motionHandler: CMDeviceMotionHandler = { motion, error in
                self.mainView.transform = CGAffineTransformMakeRotation(CGFloat(motion.attitude.yaw))
                let color: UIColor = UIColor(hue: CGFloat(motion.attitude.pitch), saturation: 0.3, brightness: 0.2, alpha: 1)
                self.mainView.backgroundColor = color
            }
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:motionHandler)
        }
        let displayLink = CADisplayLink(target: self, selector: "loop:")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

        var x: CGFloat = 0
        for creator: BoxViewCreator in creators {
            creator.view.frame = CGRectMake(x, 0, 100, 100)
            self.view.addSubview(creator.view)
            x += 100
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loop(link: CADisplayLink) {
        if (!motionManager.accelerometerAvailable) {
            for creator in creators {
                creator.gravity.angle += CGFloat(randf()) * 0.5 + 0.4
            }
        }
        let views: [UIView] = creators.map{ (var creator) -> UIView in return creator.view}
        let image: UIImage = ViewController.capturedImageWithView(views)
        for imageView in imageViews {
            imageView.image = image
        }
    }

    func setupWindow(newScreen: UIScreen) {
        let screenBounds: CGRect = newScreen.bounds
        secondWindow = UIWindow(frame: screenBounds)
        secondWindow!.screen = newScreen
        secondWindow!.hidden = false
        secondWindow!.addSubview(mainView)
        createMainView(newScreen.bounds)
    }

    func createMainView(newBounds: CGRect) {
        mainView.transform = CGAffineTransformIdentity
        for subview in mainView.subviews as [UIView] {
            subview.removeFromSuperview()
        }
        imageViews = []
        createMainViewForGrid(newBounds)
    }

    func createMainViewForGrid(newBounds: CGRect) {
        var viewWidth = newBounds.width > newBounds.height ? newBounds.height : newBounds.width
        viewWidth *= 0.7
        mainView.frame = CGRectMake((newBounds.width - viewWidth)/2, (newBounds.height - viewWidth) / 2, viewWidth, viewWidth)
        for i in 0..<size {
            for j in 0..<size {
                let imageView = UIImageView()
                mainView.addSubview(imageView)
                imageViews.append(imageView)
                let width = viewWidth / CGFloat(size)
                let imageRect = CGRect(x: CGFloat(i) * width, y: CGFloat(j) * width, width: width, height: width)
                imageView.frame = imageRect
                var transform: CGAffineTransform = CGAffineTransformIdentity
                if i % 2 == 1 {
                    transform = CGAffineTransformScale(transform, -1, 1)
                }
                if j % 2 == 1 {
                    transform = CGAffineTransformScale(transform, 1, -1)
                }
                imageView.transform = transform
                let center: CGFloat = CGFloat(size) / 2
                let center_2: CGFloat = center * center
                let i_2: CGFloat = CGFloat(i+1) - center
                let j_2: CGFloat = CGFloat(j+1) - center
                let alpha: CGFloat = 1 - (abs(i_2) + abs(j_2)) / CGFloat(size)
                NSLog("%f %f %d %f", i_2, j_2, size, alpha)
                if (size != 1) {
                    imageView.alpha = alpha
                }
            }
        }
    }

    func createMainViewForCircle(newBounds: CGRect) {
        var viewWidth = newBounds.width > newBounds.height ? newBounds.height : newBounds.width
        viewWidth *= 0.90
        mainView.frame = CGRectMake((newBounds.width - viewWidth)/2, (newBounds.height - viewWidth) / 2, viewWidth, viewWidth)
        let imageRect = CGRect(x: viewWidth / 4, y: 0, width: viewWidth/2, height: viewWidth/2)
        var n: CGFloat = 0
        let size = 7
        for i in 0..<size {
            let imageView = UIImageView()
            imageView.frame = imageRect
            mainView.addSubview(imageView)
            imageViews.append(imageView)
            
            let height = imageView.frame.height
            var transform = CGAffineTransformMakeTranslation(0, viewWidth/4);
            let angle:CGFloat = n * CGFloat(M_PI) / 180.0;
            transform = CGAffineTransformRotate(transform, angle)
            transform = CGAffineTransformTranslate(transform, 0,-viewWidth/4)
            let toggle = 0 % 2
            imageView.transform = CGAffineTransformRotate(transform, CGFloat(M_PI) * CGFloat(toggle) / 2)
            n += 360 / CGFloat(size)
        }
    }

    func checkForExistingScreenAndInitilaizePresent() {
        if UIScreen.screens().count > 1 {
            let newScreen: UIScreen = UIScreen.screens()[1] as UIScreen
            setupWindow(newScreen)
        } else {
            createMainView(self.view.frame)
            self.view.addSubview(mainView)
        }
    }

    func setUpScreenConnectionNotificationHandlers() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: "handleScreenDidConnectNotification:", name: UIScreenDidConnectNotification, object: nil)
        center.addObserver(self, selector: "handleScreenDidDisconnectNotification:", name: UIScreenDidDisconnectNotification, object: nil)
    }

    func handleScreenDidConnectNotification(notification: NSNotification) {
        let newScreen: UIScreen = notification.object as UIScreen
        if (!secondWindow) {
            setupWindow(newScreen)
        }
    }

    @IBAction func tapPlus(sender: AnyObject) {
        size += 1
        createMainView(mainView.superview.frame)
    }

    @IBAction func tapMinus(sender: AnyObject) {
        if size > 1 {
            size -= 1
        }
        createMainView(mainView.superview.frame)
    }

    func handleScreenDidDisconnectNotification(notification: NSNotification) {
        secondWindow = nil;
        createMainView(self.view.frame)
        self.view.addSubview(mainView)
    }

    @IBAction func tapAdd(sender: AnyObject) {
        for creator in creators {
            creator.createView()
        }
    }

    @IBAction func tapReset(sender: AnyObject) {
        for creator in creators {
            creator.reset()
            creator.createView()
        }
    }
}
