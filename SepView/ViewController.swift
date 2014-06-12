//
//  ViewController.swift
//  SepView
//
//  Created by えいる on 2014/06/06.
//  Copyright (c) 2014年 Tomohiko Himura. All rights reserved.
//

import UIKit
import QuartzCore
import CoreMotion

class ViewController: UIViewController {
    let wrapView = UIView(frame: CGRectMake(0,0,40,100))
    var imageViews: UIImageView[] = []
    var animator: UIDynamicAnimator? = nil
    let gravity: UIGravityBehavior = UIGravityBehavior()
    let motionManager: CMMotionManager = CMMotionManager()
    
    class func capturedImageWithView (aView: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(aView.bounds.size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()
        let pt = aView.layer.frame.origin
        CGContextSaveGState(ctx)
        CGContextTranslateCTM(ctx, pt.x, pt.y)
        let layer : AnyObject! = aView.layer
        layer.renderInContext(ctx)
        let tempImg = UIGraphicsGetImageFromCurrentImageContext();
        CGContextRestoreGState(ctx);
        UIGraphicsEndImageContext();
        return tempImg;
    }

                            
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        motionManager.accelerometerUpdateInterval = 0.01;
        
        let handler: CMAccelerometerHandler = { data, error in
            let x: CDouble = data.acceleration.x
            let y: CDouble = data.acceleration.y
            let z: CDouble = data.acceleration.z
//            NSLog("x: %f, y: %f, z: %f", x, y, z);
            if (x != 0) {
                self.gravity.angle = CGFloat(atan2(-y, x))
                self.gravity.magnitude = CGFloat(sqrt(y*y + x*x))
//                NSLog("angle: %f, magnitude: %f", self.gravity.angle, self.gravity.magnitude);
            }
        };
        
        // センサーの利用開始
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.currentQueue(), withHandler:handler)
        
        // (不必要になったら)センサーの停止
        if (motionManager.accelerometerActive) {
            motionManager.stopAccelerometerUpdates();
        }
        
        let displayLink = CADisplayLink(target: self, selector: "loop:")
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)

        wrapView.autoresizingMask = UIViewAutoresizing.None
        wrapView.backgroundColor = UIColor.blackColor()
        self.view.addSubview(wrapView)
        
        
        animator = UIDynamicAnimator(referenceView: wrapView)
        
        animator?.addBehavior(gravity)
        var objs: UIView[] = []
        for i in 1..40 {
            let obj = UIView()
            let red: CGFloat = CGFloat(rand()) / CGFloat(RAND_MAX)
            let green: CGFloat = CGFloat(rand()) / CGFloat(RAND_MAX)
            let blue: CGFloat = CGFloat(rand()) / CGFloat(RAND_MAX)
            let width: CGFloat = CGFloat(rand()) / CGFloat(RAND_MAX) * 10
            let height: CGFloat = CGFloat(rand()) / CGFloat(RAND_MAX) * 10
            obj.frame = CGRectMake(10,10,width,height)
            obj.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 0.9);
            wrapView.addSubview(obj)
            gravity.addItem(obj)
            objs.append(obj)
        }

        let collison = UICollisionBehavior(items:objs)
        collison.translatesReferenceBoundsIntoBoundary = true
        animator?.addBehavior(collison)
        
        let size = 24
        let imageRect = CGRect(x: 80,y: 100,width: 100,height: 100);
        for i in 0..size {
            let imageView = UIImageView()
            imageView.frame = imageRect
            self.view.addSubview(imageView)
            imageViews.append(imageView)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loop(link: CADisplayLink) {
        let image = ViewController.capturedImageWithView(wrapView)
        var n: CGFloat = 0
        let transform = CGAffineTransformMakeTranslation(50, 50);
        for imageView in imageViews {
            imageView.image = image
            let angle:CGFloat = n * CGFloat(M_PI) / 180.0;
            imageView.transform = CGAffineTransformTranslate(CGAffineTransformRotate(transform, angle), -50,-50)
            n += 360 / CGFloat(imageViews.count)
        }
    }


}

