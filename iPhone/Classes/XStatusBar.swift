//
//  XStatusBar.swift
//  XBolo
//
//  Created by C.W. Betts on 5/29/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import UIKit

@IBDesignable
class XStatusBar: UIView {
  
  @objc(XStatusBarType) enum BarType: Int {
    case horizontal
    case vertical
  }
  
  @IBInspectable
  @objc var barType: BarType = BarType.horizontal {
    didSet {
      if oldValue != barType {
        setNeedsDisplay()
      }
    }
  }
  
  @IBInspectable
  @objc var value: CGFloat = 0 {
    didSet {
      if oldValue != value {
        setNeedsDisplay()
      }
    }
  }
  
  // Only override drawRect: if you perform custom drawing.
  // An empty implementation adversely affects performance during animation.
  override func draw(_ rect: CGRect) {
    switch barType {
    case .horizontal:
      UIColor.green.set()
      let path = UIBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: self.frame.width * value, height: self.frame.height))
      path.fill()
      
    case .vertical:
      UIColor.green.set()
      let path = UIBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: self.frame.width, height: self.frame.height * value))
      path.fill()
    }
  }
}
