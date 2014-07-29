//  Copyright (c) 2014年 Tomohiko Himura. All rights reserved.

import UIKit
import CoreMotion

// 箱がいっぱいつまったViewを作成するクラス
//
// ALBoxViewCreator().createView() とすると view が作成される
class ALBoxViewCreator {
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
            let width: CGFloat = randf() * 20 + 5
            let height: CGFloat = randf() * 20 + 5
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
            gravity.magnitude = CGFloat(sqrt(y*y + x*x)) * 0.2
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

