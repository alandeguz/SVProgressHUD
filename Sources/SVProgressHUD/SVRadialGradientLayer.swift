//
//  SVRadialGradientLayer.swift
//
//
//  Created by Alan DeGuzman on 10/2/22.
//

import QuartzCore
import UIKit

public class SVRadialGradientLayer: CALayer {
  
  var gradientCenter: CGPoint = .zero
  
  public override init() {
    super.init()
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public override func draw(in context: CGContext) {
    let locationsCount: size_t = 2
    var locations: [CGFloat] = [0.0, 1.0]
    let colors: [CGFloat] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.75]
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradient = CGGradient(colorSpace: colorSpace, colorComponents: colors, locations: &locations, count: locationsCount)
    let radius = Float(min(bounds.size.width, bounds.size.height))
    guard let gradient = gradient else { return }
    context.drawRadialGradient(gradient, startCenter: gradientCenter, startRadius: 0, endCenter: gradientCenter, endRadius: CGFloat(radius), options: .drawsAfterEndLocation)
  }
  
}
