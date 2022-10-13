//
//  SVIndefiniteAnimatedView.swift
//
//
//  Created by Alan DeGuzman on 10/3/22.
//

import UIKit

public class SVIndefiniteAnimatedView: UIView {
  
  public override init(frame: CGRect) {
    self.radius = 0
    self.strokeThickness = 0
    self.strokeColor = .clear
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview != nil {
      layoutAnimatedLayer()
    } else {
      internalIndefiniteAnimatedLayer?.removeFromSuperlayer()
      internalIndefiniteAnimatedLayer = nil
    }
  }
  
  private var internalIndefiniteAnimatedLayer: CAShapeLayer?
  
  var indefiniteAnimatedLayer: CAShapeLayer? {
    get {
      if internalIndefiniteAnimatedLayer == nil {
        internalIndefiniteAnimatedLayer = self.createIndefiniteAnimatedLayer()
      }
      return internalIndefiniteAnimatedLayer
    }
    set {
      internalIndefiniteAnimatedLayer = newValue
    }
  }
  
  var radius: CGFloat {
    didSet {
      if oldValue != radius {
        internalIndefiniteAnimatedLayer?.removeFromSuperlayer()
        internalIndefiniteAnimatedLayer = nil
        if superview != nil {
          layoutAnimatedLayer()
        }
      }
    }
  }
  
  var strokeThickness: CGFloat {
    didSet {
      internalIndefiniteAnimatedLayer?.lineWidth = strokeThickness
    }
  }
  
  var strokeColor: UIColor {
    didSet {
      internalIndefiniteAnimatedLayer?.strokeColor = strokeColor.cgColor
    }
  }
  
  private func createIndefiniteAnimatedLayer() -> CAShapeLayer {
    let arcCenter = CGPoint(x: radius + strokeThickness / 2 + 5, y: radius + strokeThickness / 2 + 5)
    let smoothedPath = UIBezierPath(arcCenter: arcCenter,
                                    radius: radius,
                                    startAngle: .pi * 1.5,
                                    endAngle: .pi / 2 + .pi * 5,
                                    clockwise: true)
    let layer = CAShapeLayer()
    layer.contentsScale = UIScreen.main.scale
    layer.frame = CGRect(x: 0, y: 0, width: arcCenter.x * 2, height: arcCenter.y * 2)
    layer.fillColor = UIColor.clear.cgColor
    layer.strokeColor = strokeColor.cgColor
    layer.lineWidth = strokeThickness
    layer.lineCap = .round
    layer.lineJoin = .bevel
    layer.path = smoothedPath.cgPath
    
    let maskLayer = CALayer()
    let img = SVImageResource.angleMask.getImage().unsafelyUnwrapped
    maskLayer.contents = img.cgImage
    maskLayer.frame = layer.bounds
    layer.mask = maskLayer
    
    let animationDuration: Double = 1
    let linearCurve = CAMediaTimingFunction(name: .linear)
    
    let animation = CABasicAnimation(keyPath: "transform.rotation")
    animation.fromValue = 0
    animation.toValue = .pi * 2.0
    animation.duration = animationDuration
    animation.timingFunction = linearCurve
    animation.isRemovedOnCompletion = false
    animation.repeatCount = Float.infinity
    animation.fillMode = .forwards
    animation.autoreverses = false
    layer.mask?.add(animation, forKey: "rotate")
    
    let animationGroup = CAAnimationGroup()
    animationGroup.duration = animationDuration
    animationGroup.repeatCount = Float.infinity
    animationGroup.isRemovedOnCompletion = false
    animationGroup.timingFunction = linearCurve
    
    let strokeStartAnimation = CABasicAnimation(keyPath: "strokeStart")
    strokeStartAnimation.fromValue = 0.015
    strokeStartAnimation.toValue = 0.515
    
    let strokeEndAnimation = CABasicAnimation(keyPath: "strokeEnd")
    strokeEndAnimation.fromValue = 0.485
    strokeEndAnimation.toValue = 0.985
    
    animationGroup.animations = [strokeStartAnimation, strokeEndAnimation]
    
    layer.add(animationGroup, forKey: "progress")
    
    return layer
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    layoutAnimatedLayer()
  }
  
  private func layoutAnimatedLayer() {
    guard let theLayer = indefiniteAnimatedLayer else { return }
    layer.addSublayer(theLayer)
    
    let widthDiff = CGRectGetWidth(bounds) - CGRectGetWidth(theLayer.bounds)
    let heightDiff = CGRectGetHeight(bounds) - CGRectGetHeight(theLayer.bounds)
    
    theLayer.position = CGPointMake(CGRectGetWidth(bounds) - CGRectGetWidth(theLayer.bounds) / 2 - widthDiff / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(theLayer.bounds) / 2 - heightDiff / 2)
    
  }
  
  override public var frame: CGRect {
    set {
      if !CGRectEqualToRect(newValue, super.frame) {
        super.frame = newValue
        
        if superview != nil {
          layoutAnimatedLayer()
        }
      }
    }
    get {
      return super.frame
    }
  }
  
  public override func sizeThatFits(_ size: CGSize) -> CGSize {
    let val = (radius + strokeThickness / 2 + 5) * 2
    return CGSize(width: val, height: val)
  }
  
}
