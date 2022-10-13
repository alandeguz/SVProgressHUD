//
//  SVImageResource.swift
//  
//
//  Created by Alan DeGuzman on 10/4/22.
//

import UIKit

public enum SVImageResource: String, CaseIterable {
  case angleMask = "angle-mask"
  case error = "error"
  case info = "info"
  case success = "success"
  
  public func getImage() -> UIImage? {
    return UIImage(named: self.rawValue, in: Bundle.module, with: nil)
  }
}
