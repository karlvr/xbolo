//
//  XBoloShootGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 18/04/20.
//  Copyright © 2020 Robert Chrzanowski. All rights reserved.
//

import Foundation

class XBoloShootGestureRecognizer: UIGestureRecognizer {

  private var waitingForHold = false
  private var holdingTouch: UITouch?

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    if waitingForHold {
      let touch = touches.first!
      state = .began
      print("shoot began")
      holdingTouch = touch
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    if let holdingTouch = self.holdingTouch, touches.contains(holdingTouch) {
      state = .ended
      print("shoot ended")
      return
    }

    let touch = touches.first!
    if touch.tapCount == 1 {
      print("shoot waiting")
      self.waitingForHold = true

      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        guard let this = self else { return }
        this.waitingForHold = false
        if this.state == .possible {
          print("shoot gave up")
          this.state = .failed
        }
      }
    }
  }

}
