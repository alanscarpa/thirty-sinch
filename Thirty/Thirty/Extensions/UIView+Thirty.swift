//
//  UIView+Thirty.swift
//  Thirty
//
//  Created by Alan Scarpa on 3/13/18.
//  Copyright © 2018 Thirty. All rights reserved.
//

import UIKit

extension UIView: Explodable {}

extension UIView {
    
    func setButtonStyle() {
        backgroundColor = .thSecondaryPurple
        layer.cornerRadius = 7
    }
    
    func makeCircle() {
        clipsToBounds = true
        layer.cornerRadius = frame.size.width / 2
    }
    
    func shake(duration: Double = 1.0) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.duration = duration
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    func rotate360Degrees(duration: CFTimeInterval = 2.0, andScaleUp scaleUp: Bool = false, infinitely: Bool = false, completionDelegate: CAAnimationDelegate? = nil) {
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue = CGFloat(Double.pi * 2.0)
        rotateAnimation.duration = duration
        if infinitely {
            rotateAnimation.repeatCount = Float.infinity
        }
        
        if let delegate = completionDelegate {
            rotateAnimation.delegate = delegate
        }
        
        let scaleAnimationDown = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimationDown.duration = duration
        scaleAnimationDown.fromValue = 1.0
        scaleAnimationDown.toValue = 0.2
        scaleAnimationDown.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let scaleAnimationUp = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimationUp.duration = duration
        scaleAnimationUp.fromValue = 0.2
        scaleAnimationUp.toValue = 2.0
        scaleAnimationUp.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        let scaleAnimationToDefault = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimationToDefault.duration = duration
        scaleAnimationToDefault.fromValue = 2.0
        scaleAnimationToDefault.toValue = 1.0
        scaleAnimationToDefault.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        
        self.layer.add(rotateAnimation, forKey: nil)
        if scaleUp {
            self.layer.add(scaleAnimationDown, forKey: nil)
            self.layer.add(scaleAnimationUp, forKey: nil)
            self.layer.add(scaleAnimationToDefault, forKey: nil)
        }
    }
}
