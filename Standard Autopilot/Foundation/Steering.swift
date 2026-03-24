//
//  Steering.swift
//  XBolo
//
//  Converts high-level navigation goals into low-level tank commands.
//

import Foundation
import BoloKit

// MARK: - Steering Output

struct SteeringOutput {
    var accelerate = false
    var decelerate = false
    var left = false
    var right = false
}

// MARK: - Steering Controller

class SteeringController {

    /// Steer the tank toward a target position.
    /// Returns steering commands (accelerate/brake/turn).
    func steerToward(target: Vec2f, gameState: GSRobotGameState) -> SteeringOutput {
        var output = SteeringOutput()
        let tankPos = gameState.tankposition

        let dist = distance(tankPos, target)
        if dist < 0.3 {
            // Close enough, just brake
            output.decelerate = true
            return output
        }

        // Calculate desired angle to target
        let desiredAngle = angleTo(from: tankPos, to: target)

        // Current tank angle from direction (0-15)
        let currentAngle = directionToRadians(Int(gameState.tankdirection))

        // Calculate angular difference
        let angleDiff = normalizeAngle(desiredAngle - currentAngle)

        // Turn toward target.
        // The tank has 16 discrete headings (22.5° each). Use half a step as the
        // dead zone so we accept the nearest available heading without oscillating.
        let turnThreshold: Float = .pi / 16 // 11.25° — half a direction step
        if angleDiff > turnThreshold {
            output.left = true
        } else if angleDiff < -turnThreshold {
            output.right = true
        }

        // Accelerate if roughly facing target, brake if facing away
        let facingThreshold: Float = .pi / 3 // 60 degrees
        if abs(angleDiff) < facingThreshold {
            output.accelerate = true
            // Slow down when close to avoid overshooting
            if dist < 2.0 && abs(angleDiff) > turnThreshold {
                output.accelerate = false
                output.decelerate = true
            }
        } else if abs(angleDiff) > .pi / 2 {
            // Facing away from target - brake and turn
            output.decelerate = true
        }

        return output
    }

    /// Reference to the world model for checking terrain near waypoints.
    var world: WorldModel?

    /// Last waypoint index we were near — used to prevent backtracking on U-shaped paths.
    private var lastWaypointIdx = 0

    /// Reset path progress tracking (call when path changes).
    func resetPathProgress() {
        lastWaypointIdx = 0
    }

    /// Follow a path by steering toward the next appropriate waypoint.
    func followPath(_ path: PathResult, gameState: GSRobotGameState) -> SteeringOutput {
        let tankPos = gameState.tankposition
        let waypoints = path.waypoints

        guard waypoints.count > 0 else {
            return SteeringOutput(decelerate: true)
        }

        // Find the nearest waypoint, searching forward from our last known
        // position. This prevents backtracking on U-shaped paths where a
        // spatially close waypoint on a different path segment could be picked.
        let searchStart = min(lastWaypointIdx, waypoints.count - 1)
        var startIdx = searchStart
        var bestDist: Float = .infinity
        // Search forward from last position, plus a small window behind
        // in case the tank drifted backward slightly
        let searchFrom = max(0, searchStart - 2)
        for i in searchFrom..<waypoints.count {
            let d = distanceSquared(tankPos, waypoints[i].vec2f)
            if d < bestDist {
                bestDist = d
                startIdx = i
            }
        }
        lastWaypointIdx = startIdx

        // Look ahead along the path. In open terrain, extend lookahead along
        // straight segments (and at least 2 ahead for centering). In tight
        // corridors (walls adjacent), use only 1 waypoint to avoid cutting corners.
        let nextIdx = min(startIdx + 1, waypoints.count - 1)
        var lookAheadIdx = nextIdx

        // Check if the next waypoint needs precise steering:
        // - In a corridor (impassable neighbor like walls)
        // - On a boat with land adjacent (drifting onto land loses the boat)
        let needsPrecision = world.map { w in
            let wp = waypoints[nextIdx]
            let onBoat = w.hasBoat
            for dy in -1...1 {
                for dx in -1...1 {
                    if dx == 0 && dy == 0 { continue }
                    let neighbor = TilePos(x: wp.x + dx, y: wp.y + dy)
                    if w.movementCost(at: neighbor) == nil {
                        return true  // Wall/impassable — corridor
                    }
                    if onBoat && !w.isWaterTile(at: neighbor) {
                        return true  // Land next to water while on boat
                    }
                }
            }
            return false
        } ?? false

        let minLookAhead = needsPrecision ? nextIdx : min(startIdx + 2, waypoints.count - 1)
        lookAheadIdx = max(lookAheadIdx, minLookAhead)

        if nextIdx < waypoints.count - 1 {
            let firstDx = waypoints[nextIdx].x - waypoints[startIdx].x
            let firstDy = waypoints[nextIdx].y - waypoints[startIdx].y

            for i in (nextIdx + 1)..<min(startIdx + 5, waypoints.count) {
                let dx = waypoints[i].x - waypoints[i - 1].x
                let dy = waypoints[i].y - waypoints[i - 1].y
                if dx == firstDx && dy == firstDy {
                    lookAheadIdx = max(lookAheadIdx, i)
                } else if i <= minLookAhead {
                    lookAheadIdx = max(lookAheadIdx, i)
                } else {
                    break // Direction changed — don't cut the corner
                }
            }
        }

        NSLog("[Steer] tank=(%.1f,%.1f) dir=%d startIdx=%d lookAhead=%d target=(%.1f,%.1f) prec=%d",
              tankPos.x, tankPos.y, gameState.tankdirection, startIdx, lookAheadIdx,
              steerTarget.x, steerTarget.y, needsPrecision ? 1 : 0)

        // In precision mode, offset the steering target away from adjacent
        // walls/land. Waypoints are at tile centers (0.5 from walls), but
        // TANKRADIUS is 0.375, leaving only 0.125 margin. Nudging the target
        // gives the steering a clear correction vector away from the wall.
        var steerTarget = waypoints[lookAheadIdx].vec2f
        if needsPrecision, let w = world {
            let wp = waypoints[lookAheadIdx]
            var nudgeX: Float = 0
            var nudgeY: Float = 0
            let nudgeAmount: Float = 0.25

            // Check each cardinal direction for walls/land-while-on-boat
            let left = TilePos(x: wp.x - 1, y: wp.y)
            let right = TilePos(x: wp.x + 1, y: wp.y)
            let up = TilePos(x: wp.x, y: wp.y - 1)
            let down = TilePos(x: wp.x, y: wp.y + 1)

            func shouldAvoid(_ pos: TilePos) -> Bool {
                if w.movementCost(at: pos) == nil { return true }
                if w.hasBoat && w.isWaterTile(at: wp) && !w.isWaterTile(at: pos) { return true }
                return false
            }

            if shouldAvoid(left) { nudgeX += nudgeAmount }
            if shouldAvoid(right) { nudgeX -= nudgeAmount }
            if shouldAvoid(up) { nudgeY += nudgeAmount }
            if shouldAvoid(down) { nudgeY -= nudgeAmount }

            steerTarget.x += nudgeX
            steerTarget.y += nudgeY
        }

        var output = steerToward(target: steerTarget, gameState: gameState)

        // In precision mode (corridors, boat near land): slow down before
        // corners. Measure distance to the CORNER waypoint (where the turn
        // actually happens), not the intermediate waypoint before it.
        if needsPrecision && output.accelerate {
            // Find the corner: where direction changes within the next few waypoints
            if let cornerWpIdx = (lookAheadIdx + 1..<min(lookAheadIdx + 4, waypoints.count)).first(where: { i in
                let dx1 = waypoints[i].x - waypoints[i - 1].x
                let dy1 = waypoints[i].y - waypoints[i - 1].y
                let dx0 = waypoints[i - 1].x - waypoints[max(i - 2, 0)].x
                let dy0 = waypoints[i - 1].y - waypoints[max(i - 2, 0)].y
                return dx1 != dx0 || dy1 != dy0
            }) {
                let distToCorner = distance(tankPos, waypoints[cornerWpIdx].vec2f)
                if distToCorner < 1.5 {
                    output.accelerate = false
                    output.decelerate = true
                }
            }
        }

        NSLog("[Steer] accel=%d decel=%d left=%d right=%d",
              output.accelerate ? 1 : 0, output.decelerate ? 1 : 0,
              output.left ? 1 : 0, output.right ? 1 : 0)

        return output
    }

}
