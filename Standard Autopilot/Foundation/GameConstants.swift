//
//  GameConstants.swift
//  XBolo
//
//  Tank game constants mirrored from bolo.h for use in Swift brains.
//

import Foundation
import BoloKit

// MARK: - World

let kWorldWidth = 256
let kWorldHeight = 256

// MARK: - Tank Resources

let kMaxShells = 40
let kMaxArmor = 40
let kMaxMines = 40
let kMaxTrees = 40

// MARK: - Speeds (tiles per second)

let kTicksPerSec = 50
let kBoatMaxSpeed: Float = 3.125
let kRoadMaxSpeed: Float = 3.125
let kGrassMaxSpeed: Float = 2.34375
let kForestMaxSpeed: Float = 1.171875
let kRubbleMaxSpeed: Float = 0.5859375

// MARK: - Shells

let kShellVelocity: Float = 7.0
let kMinRange: Float = 1.0
let kMaxRange: Float = 7.0

// MARK: - Thresholds for brain decision-making

let kLowArmorThreshold = 10
let kLowShellsThreshold = 5
let kCriticalArmorThreshold = 5

// MARK: - Direction helpers

/// Convert a 0-15 tank direction to radians.
/// The game's angle convention: 0=East, PI/2=North(-Y), PI=West, 3PI/2=South.
/// GSRobot.m quantizes: dir = (int)(angle * 8/PI - 0.5), giving bin k the range
/// [(k+0.5)*PI/8, (k+1.5)*PI/8) centered at (k+1)*PI/8.
func directionToRadians(_ dir: Int) -> Float {
    return (Float(dir) + 1.0) * .pi / 8.0
}

/// Convert radians to 0-15 direction
func radiansToDirection(_ radians: Float) -> Int {
    var dir = Int(radians * 8.0 / .pi - 0.5)
    dir = ((dir % 16) + 16) % 16
    return dir
}

// MARK: - Vec2f helpers

func distance(_ a: Vec2f, _ b: Vec2f) -> Float {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return sqrtf(dx * dx + dy * dy)
}

func distanceSquared(_ a: Vec2f, _ b: Vec2f) -> Float {
    let dx = a.x - b.x
    let dy = a.y - b.y
    return dx * dx + dy * dy
}

/// Angle from point `from` to point `to` in radians.
/// Uses game coordinate system where Y increases downward.
func angleTo(from: Vec2f, to: Vec2f) -> Float {
    let dx = to.x - from.x
    let dy = to.y - from.y
    // atan2(-dy, dx) because Y is inverted in screen coords
    // This matches the game's internal angle convention
    return atan2f(-dy, dx)
}

/// Normalize an angle to [-PI, PI]
func normalizeAngle(_ angle: Float) -> Float {
    var a = angle
    while a > .pi { a -= 2 * .pi }
    while a < -.pi { a += 2 * .pi }
    return a
}

/// Make a Vec2f
func makeVec2f(_ x: Float, _ y: Float) -> Vec2f {
    return Vec2f(x: x, y: y)
}
