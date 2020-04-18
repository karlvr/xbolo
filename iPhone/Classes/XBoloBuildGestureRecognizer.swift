//
//  XBoloBuildGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 18/04/20.
//  Copyright © 2020 Robert Chrzanowski. All rights reserved.
//

import Foundation

class XBoloBuildGestureRecognizer: UIGestureRecognizer {

  private var nextBuildLocation: CGPoint?

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {

  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    state = .failed
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let touch = touches.first else {
      return
    }

    if touch.tapCount == 1 {
      nextBuildLocation = touch.location(in: view)
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
