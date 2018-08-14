//
//  RevealAnimator.swift
//  LogoReveal
//
//  Created by chang on 2018/8/14.
//  Copyright © 2018年 Razeware LLC. All rights reserved.
//

import UIKit

class RevealAnimator: NSObject,UIViewControllerAnimatedTransitioning,CAAnimationDelegate {

    let animationDuration = 2.0
    var operation: UINavigationControllerOperation = .push
    
    // Since you’re going to create some layer animations for your transition, you’ll need to store the animation context somewhere until the animation ends and the delegate method animationDidStop(_:finished:) executes. At that point, you’ll call completeTransition() from within animationDidStop() to wrap up the transition.
    weak var storedContext: UIViewControllerContextTransitioning?
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return animationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
        if operation == .push {
            storedContext = transitionContext
            
            // You’re trying to cast the “from” view controller to a MasterViewController instance which is true only for the push transition, but not for the pop transition
            // 如果不是 push 而是 pop,此处会 crash,因此需要添加 if 判断
            let fromVC = transitionContext.viewController(forKey:.from) as! MasterViewController
            let toVC = transitionContext.viewController(forKey:.to) as! DetailViewController
            transitionContext.containerView.addSubview(toVC.view)
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
            
            let animation = CABasicAnimation(keyPath: "transform")
            animation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
            animation.toValue = NSValue(caTransform3D:
                CATransform3DConcat(CATransform3DMakeTranslation(0.0, -10.0, 0.0),
                                    CATransform3DMakeScale(150.0, 150.0, 1.0)))
            
            // set the duration of the animation to match the transition duration
            animation.duration = animationDuration
            // set the animator as the delegate
            animation.delegate = self
            // conﬁgure the animation model to leave the animation on screen.this avoids glitches when the transition wraps up since the RW logo will be hidden away anyway
            animation.fillMode = kCAFillModeForwards
            animation.isRemovedOnCompletion = false
            // add easing to make the reveal effect accelerate over time.
            animation.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseIn)
            
            //  This creates a CAShapeLayer to be applied to the DestinationViewController. The maskLayer is positioned in the same location as the “RW” logo on the MasterViewController. Then you simply set maskLayer as the mask of the view controller’s view.
            let maskLayer: CAShapeLayer = RWLogoLayer.logoLayer()
            maskLayer.position = fromVC.logo.position
            toVC.view.layer.mask = maskLayer
            maskLayer.add(animation, forKey: nil)
            
            // make the original logo grow with the mask, matching its shape exactly
            fromVC.logo.add(animation, forKey: nil)
            
            // fade in the new view controller as the reveal animation runs
            let fadeIn = CABasicAnimation(keyPath: "opacity")
            fadeIn.fromValue = 0.0
            fadeIn.toValue = 1.0
            fadeIn.duration = animationDuration
            toVC.view.layer.add(fadeIn, forKey: nil)
        } else {// pop 动画
            let fromView = transitionContext.view(forKey: .from)!
            let toView = transitionContext.view(forKey: .to)!
            
            // 将 fromView 显示在 toView 之上，回到上一页面
            transitionContext.containerView.insertSubview(toView, belowSubview: fromView)
            
            UIView.animate(withDuration: animationDuration, delay: 0.0, options: .curveEaseIn, animations: {
                // Use an animation to scale fromView to 0.01. Don’t use 0.0 for scaling — this will confuse UIKit. For this animation you can use an ordinary view animation – there’s no need to create a layer animation.
                fromView.transform = CGAffineTransform(scaleX: 0.01, y: 0.01)
            }, completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            })
        }
        
    }
    
    // check whether you have a stored transition context; if so, you call completeTransition() on it. This passes the ball back to the navigation controller to wrap up with the transition on UIKit’s side.
    // 不实现此方法的话，pop 会失效，无法返回上一页面
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if let context = storedContext {
            context.completeTransition(!context.transitionWasCancelled)
            // reset logo
            let fromVC = context.viewController(forKey: .from) as! MasterViewController
            fromVC.logo.removeAllAnimations()
            
            // remove the mask after the view has appeared and the transition is complete.
            let toVC = context.viewController(forKey: .to) as! DetailViewController
            toVC.view.layer.mask = nil
        }
        storedContext = nil
    }
    
}
