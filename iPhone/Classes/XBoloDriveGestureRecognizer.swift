//
//  XBoloDriveGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 14/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

import Foundation

class XBoloDriveGestureRecognizer: UIGestureRecognizer {

  @objc private(set) var accelerateRate = 0.0
  @objc private(set) var brakeRate = 0.0

  private var trackingTouch: UITouch?
  private var originalLocation: CGPoint?
  private var currentLocation: CGPoint?
  private var recognized = false

  private let deadZone = CGFloat(5.0)
  private let maxZone = CGFloat(30.0)

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
  }

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    guard let trackingTouch = self.trackingTouch, let originalLocation = self.originalLocation else {
      return
    }
    let currentLocation = trackingTouch.location(in: self.view)

    if !recognized {
      let distance = abs(originalLocation.y - currentLocation.y)
      if distance > deadZone {
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
//    if let controller = self.controller {
//      controller.keyEvent(false, forKnownKey: GSAccelerate)
//      controller.keyEvent(false, forKnownKey: GSBrake)
//      controller.keyEvent(false, forKnownKey: GSTurnLeft)
//      controller.keyEvent(false, forKnownKey: GSTurnRight)
//    }
  }
}
