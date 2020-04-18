//
//  XBoloSteerGestureRecognizer.swift
//  iPhone
//
//  Created by Karl von Randow on 14/06/19.
//  Copyright © 2019 Robert Chrzanowski. All rights reserved.
//

import Foundation

private func CGPointDist(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
  return sqrt((a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y));
}

class XBoloSteerGestureRecognizer: UIGestureRecognizer {

  @objc private(set) var angle = 0.0
  @objc private(set) var angleSet = false
  @objc var tankdir = 0.0

  private var trackingTouch: UITouch?
  private var originalCentre = CGPoint.zero

  private let deadZone = CGFloat(1.0)

  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
    /* If we are already tracking a touch ignore all new touches. */
    if let trackingTouch = self.trackingTouch {
      if !touches.contains(trackingTouch) {
        touches.forEach { (touch) in
          self.ignore(touch, for: event)
        }
        return
      }
    }

    /* Acquire a new tracking touch if we don't have one */
    if trackingTouch == nil {
      guard let touch = touches.first else {
        return
      }
      let originalLocation = touch.previousLocation(in: view)
      let currentLocation = touch.location(in: view)
      let distance = CGPointDist(originalLocation, currentLocation)
      if distance < deadZone {
        return
      }

      print("recognized steer gesture!")
      self.state = .began

      self.trackingTouch = touch
      let location = touch.location(in: view)
      let tankAngle = tankDirToAngle(tankdir)
      let radius = CGFloat(10)

      let ydiff = sin(tankAngle) * radius
      let xdiff = cos(tankAngle) * radius
      self.originalCentre = CGPoint(x: location.x - xdiff, y: location.y - ydiff)
      print("touch at \(location) tank angle \(tankAngle) for tank dir \(tankdir) centre at \(self.originalCentre)")
    }

    guard let trackingTouch = self.trackingTouch, let view = self.view else {
      print("Invalid state in steer gesture recognizer")
      return
    }

    let currentLocation = trackingTouch.location(in: view)
//    let previousLocation = trackingTouch.previousLocation(in: view)
    let previousLocation = originalCentre
    let xdiff = currentLocation.x - previousLocation.x
    let ydiff = currentLocation.y - previousLocation.y
    if abs(xdiff) > deadZone || abs(ydiff) > deadZone {
      let angle = atan2(ydiff, xdiff)
      print("steer angle \(angle)")
      self.angle = angleToTankDir(angle)
      self.angleSet = true
    } else {
//      self.angleSet = false
    }
  }

  private func angleToTankDir(_ angle: CGFloat) -> Double {
    let result = Double(-angle)
    if result >= 0 {
      return result
    } else {
      return Double.pi * 2 + result
    }
  }

  private func tankDirToAngle(_ dir: Double) -> CGFloat {
    var result = CGFloat(dir)
    if result > CGFloat.pi {
      result -= CGFloat.pi * 2
    }
    return -result
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
    self.angle = 0
    self.angleSet = false
  }
}
