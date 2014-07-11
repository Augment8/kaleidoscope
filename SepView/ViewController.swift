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

    init () {
        animator = UIDynamicAnimator(referenceView: view)
    }

    func createView(gravity: UIGravityBehavior) {
        UIViewAutoresizing.None;

        animator.addBehavior(gravity)
        var objs: [UIView] = []
        for i in 1..<10 {
            let obj = UIView()
            let red: CGFloat = randf() * 0.4 + 0.6
            let green: CGFloat = randf() * 0.4 + 0.6
            let blue: CGFloat = randf() * 0.4 + 0.6
            let width: CGFloat = randf() * 10 + 14
            let height: CGFloat = randf() * 10 + 14
            obj.frame = CGRectMake(CGFloat(i),CGFloat(i),width,height)
            obj.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 0.8);
            view.addSubview(obj)
            gravity.addItem(obj)
            objs.append(obj)
        }
        
        let collison = UICollisionBehavior(items:objs)
        collison.translatesReferenceBoundsIntoBoundary = true
        animator.addBehavior(collison)
    }
}

class ViewController: UIViewController {
    let mainView: UIView = UIView()
    var imageViews: [UIImageView] = []
    let motionManager: CMMotionManager = CMMotionManager()
    let gravity: UIGravityBehavior = UIGravityBehavior()
    let gravity2: UIGravityBehavior = UIGravityBehavior()
    let creator: BoxViewCreator = BoxViewCreator()
    let creator2: BoxViewCreator = BoxViewCreator()
    var secondWindow: UIWindow? = nil;

    class func capturedImageWithView (views: [UIView]) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(views[0].bounds.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        CGContextSaveGState(ctx)
        for view : UIView in views {
            let layer : AnyObject! = view.layer
            layer.renderInContext(ctx)
            CGContextTranslateCTM(ctx, views[0].bounds.size.width/2, views[0].bounds.size.height/2)
            CGContextRotateCTM(ctx, 3.1415925)
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
        motionManager.accelerometerUpdateInterval = 0.01;
        creator.createView(gravity)
        creator2.createView(gravity2)
        
        let handler: CMAccelerometerHandler = { data, error in
            let x: CDouble = data.acceleration.x
            let y: CDouble = data.acceleration.y
            let z: CDouble = data.acceleration.z
//            NSLog("x: %f, y: %f, z: %f", x, y, z);
            if (x != 0) {
                self.gravity.angle = CGFloat(atan2(-y, x))
                self.gravity.magnitude = CGFloat(sqrt(y*y + x*x))
                self.gravity2.angle = CGFloat(atan2(-y, x))
                self.gravity2.magnitude = CGFloat(sqrt(y*y + x*x))
//                NSLog("angle: %f, magnitude: %f", self.gravity.angle, self.gravity.magnitude);
            }
        };

        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:handler)
        
        if (motionManager.accelerometerActive) {
//            motionManager.stopAccelerometerUpdates();
        } else {
//            self.gravity.magnitude = 1;
        }
        
        let displayLink = CADisplayLink(target: self, selector: "loop:")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

        creator.view.frame = CGRectMake(0, 0, 100, 100)
        self.view.addSubview(creator.view)
        creator2.view.frame = CGRectMake(100, 0, 100, 100)
        self.view.addSubview(creator2.view)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loop(link: CADisplayLink) {
        let image = ViewController.capturedImageWithView([creator.view,creator2.view])
        for imageView in imageViews {
            imageView.image = image
        }
    }

    func setupWindow(newScreen: UIScreen) {
        let screenBounds: CGRect = newScreen.bounds
        secondWindow = UIWindow(frame: screenBounds)
        secondWindow!.screen = newScreen
        secondWindow!.hidden = false
        mainView.frame = newScreen.bounds
        secondWindow!.addSubview(mainView)

        let size = 18
        let width = newScreen.bounds.width > newScreen.bounds.height ? newScreen.bounds.height : newScreen.bounds.width
        let imageRect = CGRect(x: newScreen.bounds.width / 2,y: newScreen.bounds.height / 8,width: 80,height: width/4)
        var n: CGFloat = 0
        for i in 0..<size {
            let imageView = UIImageView()
            imageView.frame = imageRect
            mainView.addSubview(imageView)
            imageViews.append(imageView)

            let height = imageView.frame.height
            let transform = CGAffineTransformMakeTranslation(0, width/4);
            let angle:CGFloat = n * CGFloat(M_PI) / 180.0;
            imageView.transform = CGAffineTransformTranslate(CGAffineTransformRotate(transform, angle), 0,-width/4)
            n += 360 / CGFloat(size)
        }
    }

    func checkForExistingScreenAndInitilaizePresent() {
        if UIScreen.screens().count > 1 {
            let newScreen: UIScreen = UIScreen.screens()[1] as UIScreen
            setupWindow(newScreen)
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

    func handleScreenDidDisconnectNotification(notification: NSNotification) {
    }
}

