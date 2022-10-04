//
//  XBoloBuildGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 18/04/20.
//  Copyright © 2020 Robert Chrzanowski. All rights reserved.
//

import Foundation
import SpriteKit

class XBoloBuildGestureRecognizer: UIGestureRecognizer {

  @objc var scene: SKScene?
  
  private var nextBuildLocation: CGPoint?

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {

  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    for touch in touches {
      self.ignore(touch, for: event)
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let touch = touches.first else {
      return
    }

    if touch.tapCount == 1 {
      let point = touch.location(in: view)
      if let scene = self.scene {
        nextBuildLocation = scene.convertPoint(fromView: point)
      }
      state = .recognized
      print("build recognized")
    }
  }

  @objc func readNextBuildLocation() -> CGPoint {
    if let p = nextBuildLocation {
      nextBuildLocation = nil
      return p
    } else {
      return CGPoint.zero
    }
  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    print("build cancelled")
  }

}
