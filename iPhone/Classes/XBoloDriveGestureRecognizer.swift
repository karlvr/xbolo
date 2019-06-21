//
//  XBoloDriveGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 14/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

import Foundation

func CGPointDist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
  return sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

class XBoloDriverGestureRecognizer: UIGestureRecognizer {

  @objc private(set) var accelerateRate = 0.0
  @objc private(set) var brakeRate = 0.0
  @objc private(set) var turnLeftRate = 0.0
  @objc private(set) var turnRightRate = 0.0

  private var trackingTouch: UITouch?
  private var originalLocation: CGPoint?
  private var currentLocation: CGPoint?
  private var recognized = false

  private let deadZone = CGFloat(10.0)
  private let maxZone = CGFloat(100.0)

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
    /* If we are already tracking a touch ignore all new touches,
       or if is a multi-touch event, ignore it.
     */
    guard self.trackingTouch == nil && touches.count == 1 else {
      touches.forEach { (touch) in
        self.ignore(touch, for: event)
      }
      return
    }

    /* Grab our touch to track */
    guard let trackingTouch = touches.first else {
      return
    }

    self.state = .began

    self.trackingTouch = trackingTouch
    self.originalLocation = trackingTouch.location(in: self.view)
    self.currentLocation = self.originalLocation
    self.recognized = false
    self.accelerateRate = 0.0
    self.brakeRate = 0.0
    self.turnLeftRate = 0.0
    self.turnRightRate = 0.0
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let trackingTouch = self.trackingTouch, let originalLocation = self.originalLocation else {
      return
    }
    let currentLocation = trackingTouch.location(in: self.view)

    if !recognized {
      let distance = CGPointDist(originalLocation, currentLocation)
      if distance > 10 {
        NSLog("recognized drive gesture!")
//        self.state = .recognized
        recognized = true
      }
    }

    guard recognized else {
      return
    }

    let ydiff = originalLocation.y - currentLocation.y
    if ydiff > deadZone {
      accelerateRate = Double((ydiff - deadZone) / maxZone)
      brakeRate = 0
    } else if ydiff < -deadZone {
      accelerateRate = 0
      brakeRate = Double((-ydiff - deadZone) / maxZone)
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
      self.state = .ended

      clearKeys()
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
    self.accelerateRate = 0.0
    self.brakeRate = 0.0
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
