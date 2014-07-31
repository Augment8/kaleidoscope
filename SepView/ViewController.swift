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

func randi(n: NSNumber) -> NSNumber {
    return randf() * CGFloat(n)
}

enum PlusMode {
    case Plus,Minus
}

enum ModeType {
    case Grid,Circle
}

class ViewController: UIViewController {
    let mainView: UIView = UIView()
    var imageViews: [UIImageView] = []
    let motionManager: CMMotionManager = CMMotionManager()
    let creators: [ALBoxViewCreator] = [ALBoxViewCreator(),ALBoxViewCreator()]
    var secondWindow: UIWindow? = nil
    var size: NSInteger = 3
    var tapAddTimer: NSTimer? = nil
    var tapPlusMinusTimer: NSTimer? = nil
    var plusMinusMode: PlusMode = .Plus
    var modeTimer: NSTimer? = nil
    var mode: ModeType  = .Grid
    var simulatorTimer: NSTimer? = nil
    var maskView: UIImageView = UIImageView(image: UIImage(named: "mask00.png"))
    var maskTimer: NSTimer? = nil

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
        // Do any additional setup after loading the view, typically from a nib.
        UIApplication.sharedApplication().idleTimerDisabled = true
        setUpScreenConnectionNotificationHandlers()
        checkForExistingScreenAndInitilaizePresent()
        srand(CUnsignedInt(time(nil)))
        self.view.backgroundColor = UIColor.blackColor()

        for creator: ALBoxViewCreator in creators {
           creator.createView();
        }

        setMotion()

        var x: CGFloat = 0
        for creator: ALBoxViewCreator in creators {
            creator.view.frame = CGRectMake(x, 0, 100, 100)
            self.view.addSubview(creator.view)
            x += 100
        }
        
        setTimers()

        if (!motionManager.accelerometerAvailable) {
            simulatorTimer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "emulatorAcceleromenter", userInfo: nil, repeats: true)
        }
    }
    
    func setMotion() {
        motionManager.accelerometerUpdateInterval = 0.04;
        if (self.motionManager.accelerometerAvailable) {
            let handler: CMAccelerometerHandler = { data, error in
                for creator: ALBoxViewCreator in self.creators {
                    creator.accelerometerHandler(data, error: error)
                }
            }
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:handler)
            
            let motionHandler: CMDeviceMotionHandler = { motion, error in
                self.mainView.transform = CGAffineTransformMakeRotation(CGFloat(motion.attitude.yaw))
                let color: UIColor = UIColor(hue: 0, saturation: 0, brightness: CGFloat(motion.attitude.pitch) * 0.2, alpha: 1)
                self.mainView.backgroundColor = color
            }
            motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:motionHandler)
        }
    }
    
    func setTimers() {
        let displayLink = CADisplayLink(target: self, selector: "loop:")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

        tapAddTimer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: "tapAdd:", userInfo: nil, repeats: true)
        tapPlusMinusTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "plusMinus", userInfo: nil, repeats: true)
        modeTimer = NSTimer.scheduledTimerWithTimeInterval(300, target: self, selector: "switchOtherMode", userInfo: nil, repeats: true)
        maskTimer = NSTimer.scheduledTimerWithTimeInterval(20, target: self, selector: "randomMask", userInfo: nil, repeats: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loop(link: CADisplayLink) {
        let views: [UIView] = creators.map{ (var creator) -> UIView in return creator.view}
        let image: UIImage = ViewController.capturedImageWithView(views)
        for imageView in imageViews {
            imageView.image = image
        }
    }
    
    func randomMask() {
        let name = String(format: "mask%02d.png", randi(4).integerValue);
        maskView.image = UIImage(named: name)
    }
    
    func emulatorAcceleromenter() {
        for creator in creators {
            creator.gravity.angle = randf() * M_PI * 2
            creator.gravity.magnitude = 0.2
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
        switch mode {
        case .Grid:
            createMainViewForGrid(newBounds)
        case .Circle:
            createMainViewForCircle(newBounds)
        }
    }
    
    func switchOtherMode() {
        switch mode {
        case .Grid:
            mode = .Circle
        case .Circle:
            mode = .Grid
        }
        checkForExistingScreenAndInitilaizePresent()
    }

    func createMainViewForGrid(newBounds: CGRect) {
        var viewWidth = newBounds.width > newBounds.height ? newBounds.height : newBounds.width
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
                let i_2: CGFloat = CGFloat(i) + 0.5 - center
                let j_2: CGFloat = CGFloat(j) + 0.5 - center
                let alpha: CGFloat = 1 - (abs(i_2) + abs(j_2)) / CGFloat(size)
            }
        }
        maskView.frame = CGRect(x: 0, y: 0, width: mainView.frame.size.width, height: mainView.frame.size.height)
        mainView.addSubview(maskView)
    }

    func createMainViewForCircle(newBounds: CGRect) {
        var viewWidth = newBounds.width > newBounds.height ? newBounds.height : newBounds.width
        viewWidth *= 0.90
        mainView.frame = CGRectMake((newBounds.width - viewWidth)/2, (newBounds.height - viewWidth) / 2, viewWidth, viewWidth)
        let imageRect = CGRect(x: viewWidth / 4, y: 0, width: viewWidth/2, height: viewWidth/2)
        var n: CGFloat = 0
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
        maskView.removeFromSuperview()
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
    
    func plusMinus() {
        switch plusMinusMode {
        case .Plus:
            plus()
            if size == 12 {
                plusMinusMode = .Minus
            }
        case .Minus:
            minus()
            if size == 4 {
                plusMinusMode = .Plus
            }
        }
    }
    
    func plus() {
        size += 1
        createMainView(mainView.superview.frame)
    }
    
    func minus() {
        if size > 1 {
            size -= 1
        }
        createMainView(mainView.superview.frame)
    }

    @IBAction func tapPlus(sender: AnyObject) {
        plus()
    }

    @IBAction func tapMinus(sender: AnyObject) {
        minus()
    }

    func handleScreenDidDisconnectNotification(notification: NSNotification) {
        secondWindow = nil;
        createMainView(self.view.frame)
        self.view.addSubview(mainView)
    }

    @IBAction func tapAdd(sender: AnyObject) {
        let n = creators.map { (var creator) -> Int in return creator.objs.count }.reduce(0, combine: { (let a,let b) -> Int in return a+b })
        if n > 40 {
            for creator in creators {
                creator.reset()
            }
        }
        for creator in creators {
            creator.addObject(randi(3).integerValue+1)
        }
    }

    @IBAction func tapReset(sender: AnyObject) {
        for creator in creators {
            creator.reset()
            creator.createView()
        }
    }
}
