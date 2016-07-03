//
//  BuilderStatusView.swift
//  XBolo
//
//  Created by C.W. Betts on 5/28/16.
//  Copyright © 2016 Robert Chrzanowski. All rights reserved.
//

import UIKit

class XBuilderStatusView : UIView {
  @objc(XBuilderStatusViewState) enum State: Int32 {
    case Ready
    case Direction
    case Dead
  }
  
  var state: State = State.Ready {
    didSet {
      if state != oldValue {
        setNeedsDisplay()
      }
    }
  }
  var direction: CGFloat = 0 {
    didSet {
      if direction != oldValue && state == .Direction {
        setNeedsDisplay()
      }
    }
  }
  
  override func drawRect(dirtyRect: CGRect) {
    switch state {
    case .Direction:
      let bounds = self.bounds;
      UIColor.whiteColor().set()
      let p = UIBezierPath(ovalInRect: CGRect(x: -2, y: -2, width: 4, height: 4))
      p.moveToPoint(CGPoint(x: bounds.size.width*0.25, y: bounds.size.height*0.125))
      p.addLineToPoint(CGPoint(x: bounds.size.width*0.5, y: 0.0))
      p.addLineToPoint(CGPoint(x: bounds.size.width*0.25, y: -bounds.size.height*0.125))
      p.moveToPoint(.zero)
      p.addLineToPoint(CGPoint(x: bounds.size.width*0.5, y: 0.0))
      
      var t = CGAffineTransformMakeTranslation(bounds.size.width*0.5, bounds.size.height*0.5)
      t = CGAffineTransformRotate(t, direction)
      p.applyTransform(t)
      p.stroke()
      p.fill()
      
    case .Dead:
      UIColor(patternImage: UIImage(named: "StipplePattern")!).set()
      UIBezierPath(ovalInRect: bounds).fill()
      break;
      
    case .Ready:
      break;
    }
  }
}
