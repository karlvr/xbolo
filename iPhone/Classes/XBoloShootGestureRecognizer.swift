//
//  XBoloShootGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 18/04/20.
//  Copyright © 2020 Robert Chrzanowski. All rights reserved.
//

import Foundation

class XBoloShootGestureRecognizer: UIGestureRecognizer {

  private var eventCounter = 0

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let touch = touches.first else {
      return
    }

    if touch.tapCount == 1 {
      eventCounter += 1
      let savedEventCounter = eventCounter
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
        guard let this = self else { return }
        if this.eventCounter == savedEventCounter {
          this.state = .failed
        }
      }
    } else if touch.tapCount > 1 {
      eventCounter += 1
      state = .recognized
    }
  }

}
