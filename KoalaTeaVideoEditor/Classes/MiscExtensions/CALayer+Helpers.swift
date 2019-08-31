//
//  CALayer+Helpers.swift
//  KoalaTeaAssetPlayer
//
//  Created by Craig Holliday on 8/31/19.
//

import Foundation

extension CALayer {
    func addStrokeEndAnimation(toValue: Double, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation(keyPath: #keyPath(CAShapeLayer.strokeEnd))
        animation.fromValue = 0
        animation.toValue = toValue
        animation.beginTime = beginTime
        animation.duration = duration
        animation.autoreverses = false
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards

        self.add(animation, forKey: UUID().uuidString)
    }

    func addAnimatePositionAlongPath(path: CGPath, beginTime: Double, duration: Double, repeatCount: Float) {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.position))
        animation.path = path
        animation.calculationMode = CAAnimationCalculationMode.paced
        animation.duration = duration
        animation.beginTime = beginTime
        animation.isRemovedOnCompletion = false
        animation.repeatCount = repeatCount

        self.add(animation, forKey: UUID().uuidString)
    }

    func addFadeAnimation(fromValue: Float, toValue: Float, beginTime: Double, duration: Double) {
        let animation = CABasicAnimation(keyPath: #keyPath(CALayer.opacity))
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.beginTime = beginTime
        animation.duration = duration
        animation.autoreverses = false
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards

        self.add(animation, forKey: UUID().uuidString)
    }

    func addFadeInAnimation(beginTime: Double, duration: Double) {
        self.addFadeAnimation(fromValue: 0.0, toValue: 1.0, beginTime: beginTime, duration: duration)
    }

    func addFadeOutAnimation(beginTime: Double, duration: Double) {
        self.addFadeAnimation(fromValue: 1.0, toValue: 0.0, beginTime: beginTime, duration: duration)
    }

    func addRotateAnimation(duration: Double, repeatCount: Float) {
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.fromValue = 0.0
        animation.toValue = CGFloat(.pi * 2.0)
        animation.duration = duration
        animation.repeatCount = repeatCount

        self.add(animation, forKey: UUID().uuidString)
    }
}
