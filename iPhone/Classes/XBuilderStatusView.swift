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
  
  override func draw(_ dirtyRect: CGRect) {
    switch state {
    case .Direction:
      let bounds = self.bounds;
      UIColor.white.set()
      let p = UIBezierPath(ovalIn: CGRect(x: -2, y: -2, width: 4, height: 4))
      p.move(to: CGPoint(x: bounds.size.width*0.25, y: bounds.size.height*0.125))
      p.addLine(to: CGPoint(x: bounds.size.width*0.5, y: 0.0))
      p.addLine(to: CGPoint(x: bounds.size.width*0.25, y: -bounds.size.height*0.125))
      p.move(to: .zero)
      p.addLine(to: CGPoint(x: bounds.size.width*0.5, y: 0.0))
      
      var t = CGAffineTransform(translationX: bounds.size.width*0.5, y: bounds.size.height*0.5)
      t = t.rotated(by: direction)
      p.apply(t)
      p.stroke()
      p.fill()
      
    case .Dead:
      UIColor(patternImage: UIImage(named: "StipplePattern")!).set()
      UIBezierPath(ovalIn: bounds).fill()
      break;
      
    case .Ready:
      break;
    }
  }
}
