//
//  SVProgressAnimatedView.swift
//
//
//  Created by Alan DeGuzman on 10/2/22.
//

import UIKit

public class SVProgressAnimatedView: UIView {
  
  var radius: CGFloat {
    didSet {
      if oldValue != radius {
        internalRingAnimatedLayer?.removeFromSuperlayer()
        internalRingAnimatedLayer = nil
        if superview != nil {
          layoutAnimatedLayer()
        }
      }
    }
  }
  
  var strokeThickness: CGFloat {
    didSet {
      internalRingAnimatedLayer?.lineWidth = strokeThickness
    }
  }
  
  var strokeColor: UIColor {
    didSet {
      internalRingAnimatedLayer?.strokeColor = strokeColor.cgColor
    }
  }
  
  var strokeEnd: CGFloat {
    didSet {
      internalRingAnimatedLayer?.strokeEnd = strokeEnd
    }
  }
  
  public override init(frame: CGRect) {
    self.radius = 0
    self.strokeThickness = 0
    self.strokeColor = .clear
    self.strokeEnd = 0
    super.init(frame: frame)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private var internalRingAnimatedLayer: CAShapeLayer?
  
  var ringAnimatedLayer: CAShapeLayer? {
    get {
      if internalRingAnimatedLayer == nil {
        internalRingAnimatedLayer = self.createRingAnimatedLayer()
      }
      return internalRingAnimatedLayer
    }
    set {
      internalRingAnimatedLayer = newValue
    }
  }
  
  public override func willMove(toSuperview newSuperview: UIView?) {
    if newSuperview != nil {
      layoutAnimatedLayer()
    } else {
      internalRingAnimatedLayer?.removeFromSuperlayer()
      internalRingAnimatedLayer = nil
    }
  }
  
  private func layoutAnimatedLayer() {
    guard let theLayer = ringAnimatedLayer else { return }
    layer.addSublayer(theLayer)
    
    let widthDiff = CGRectGetWidth(bounds) - CGRectGetWidth(theLayer.bounds)
    let heightDiff = CGRectGetHeight(bounds) - CGRectGetHeight(theLayer.bounds)
    
    theLayer.position = CGPointMake(CGRectGetWidth(bounds) - CGRectGetWidth(theLayer.bounds) / 2 - widthDiff / 2, CGRectGetHeight(self.bounds) - CGRectGetHeight(theLayer.bounds) / 2 - heightDiff / 2)
    
  }
  
  private func createRingAnimatedLayer() -> CAShapeLayer {
    let arcCenter = CGPoint(x: radius + strokeThickness / 2 + 5, y: radius + strokeThickness / 2 + 5)
    let smoothedPath = UIBezierPath(arcCenter: arcCenter,
                                    radius: radius,
                                    startAngle: -.pi / 2, endAngle: .pi + .pi / 2, clockwise: true)
    let layer = CAShapeLayer()
    layer.contentsScale = UIScreen.main.scale
    layer.frame = CGRect(x: 0, y: 0, width: arcCenter.x * 2, height: arcCenter.y * 2)
    layer.fillColor = UIColor.clear.cgColor
    layer.strokeColor = strokeColor.cgColor
    layer.lineWidth = strokeThickness
    layer.lineCap = .round
    layer.lineJoin = .bevel
    layer.path = smoothedPath.cgPath
    return layer
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
