//
//  XBoloSteerGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 14/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

import Foundation

//func CGPointDist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
//  return sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
//}

class XBoloSteerGestureRecognizer: UIGestureRecognizer {

  @objc private(set) var turnLeftRate = 0.0
  @objc private(set) var turnRightRate = 0.0

  private var trackingTouch: UITouch?
  private var originalLocation: CGPoint?

  private let deadZone = CGFloat(0.0)
  private let maxZone = CGFloat(50.0)

//  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
//    /* If we are already tracking a touch ignore all new touches,
//       or if is a multi-touch event, ignore it.
//     */
//    guard self.trackingTouch == nil else {
//      print("our tracking touch phase \(self.trackingTouch!.phase.rawValue)")
//      touches.forEach { (touch) in
//        self.ignore(touch, for: event)
//      }
//      return
//    }
//
//    /* Grab our touch to track */
//    guard let trackingTouch = touches.first else {
//      return
//    }
//
//    self.state = .began
//
//    self.trackingTouch = trackingTouch
//    self.originalLocation = trackingTouch.location(in: self.view)
//    self.turnLeftRate = 0.0
//    self.turnRightRate = 0.0
//  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let trackingTouch = touches.first else { return }

    /* If we are already tracking a touch ignore all new touches. */
    guard self.trackingTouch == nil || self.trackingTouch == trackingTouch else {
      touches.forEach { (touch) in
        self.ignore(touch, for: event)
      }
      return
    }

    if self.trackingTouch == nil {
      self.trackingTouch = trackingTouch

      self.originalLocation = trackingTouch.previousLocation(in: self.view)
      self.turnLeftRate = 0.0
      self.turnRightRate = 0.0
    }

    guard let originalLocation = self.originalLocation else {
      return
    }
    let currentLocation = trackingTouch.location(in: self.view)

    if self.state == .possible {
      let distance = abs(originalLocation.x - currentLocation.x)
      if distance > deadZone {
        print("recognized steer gesture!")
        self.state = .began
      } else {
        return
      }
    }

    let xdiff = currentLocation.x - originalLocation.x
    if xdiff > deadZone {
      turnLeftRate = 0
      turnRightRate = Double((xdiff - deadZone) / maxZone)
    } else if xdiff < -deadZone {
      turnLeftRate = Double((-xdiff - deadZone) / maxZone)
      turnRightRate = 0
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let trackingTouch = self.trackingTouch else {
      return
    }
    if touches.contains(trackingTouch) {
      self.trackingTouch = nil

      if (self.state == .began) {
        self.state = .cancelled
      } else if (self.state != .possible) {
        self.state = .ended

        clearKeys()
      }
    }

  }

  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let trackingTouch = self.trackingTouch else {
      return
    }
    if touches.contains(trackingTouch) {
      self.trackingTouch = nil
      self.state = .cancelled

      clearKeys()
    }

  }

  private func clearKeys() {
    self.turnLeftRate = 0.0
    self.turnRightRate = 0.0
//    if let controller = self.controller {
//      controller.keyEvent(false, forKnownKey: GSAccelerate)
//      controller.keyEvent(false, forKnownKey: GSBrake)
//      controller.keyEvent(false, forKnownKey: GSTurnLeft)
//      controller.keyEvent(false, forKnownKey: GSTurnRight)
//    }
  }
}
