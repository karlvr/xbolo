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

        // Check if the next waypoint is in a tight corridor (impassable neighbor)
        let inCorridor = world.map { w in
            let wp = waypoints[nextIdx]
            for dy in -1...1 {
                for dx in -1...1 {
                    if dx == 0 && dy == 0 { continue }
                    if w.movementCost(at: TilePos(x: wp.x + dx, y: wp.y + dy)) == nil {
                        return true
                    }
                }
            }
            return false
        } ?? false

        let minLookAhead = inCorridor ? nextIdx : min(startIdx + 2, waypoints.count - 1)
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

//        NSLog("[Steer] tank=(%.1f,%.1f) startIdx=%d lookAheadIdx=%d target=(%d,%d) wpCount=%d",
//              tankPos.x, tankPos.y, startIdx, lookAheadIdx,
//              waypoints[lookAheadIdx].x, waypoints[lookAheadIdx].y, waypoints.count)

        var output = steerToward(target: waypoints[lookAheadIdx].vec2f, gameState: gameState)

        // Corner braking removed — it was causing the tank to permanently
        // stall. The braking kicked in whenever a corner was within 2 tiles,
        // but after stopping the corner was STILL within 2 tiles, so the
        // tank could never restart. The steerToward function's own close-range
        // handling is sufficient.

//        NSLog("[Steer] accel=%d decel=%d left=%d right=%d",
//              output.accelerate ? 1 : 0, output.decelerate ? 1 : 0,
//              output.left ? 1 : 0, output.right ? 1 : 0)

        return output
    }

}
