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

    /// Follow a path by steering toward the next appropriate waypoint.
    func followPath(_ path: PathResult, gameState: GSRobotGameState) -> SteeringOutput {
        let tankPos = gameState.tankposition
        let waypoints = path.waypoints

        guard waypoints.count > 0 else {
            return SteeringOutput(decelerate: true)
        }

        // Find the nearest waypoint to our current position.
        // We used to require an exact tile match, but if the tank drifted
        // off-path (dodging, momentum, stale path), startIdx fell back to 0
        // and the tank steered toward the path start — into walls.
        var startIdx = 0
        var bestDist: Float = .infinity
        for (i, wp) in waypoints.enumerated() {
            let d = distanceSquared(tankPos, wp.vec2f)
            if d < bestDist {
                bestDist = d
                startIdx = i
            }
        }

        // Look ahead along the path, extending while consecutive waypoints
        // maintain the same direction. Stop at direction changes to avoid
        // cutting corners around obstacles.
        // Always look at least 2 waypoints ahead (when available) so the
        // tank gets enough angular correction to stay centered on the path.
        // With only 1 waypoint ahead, the angle to the next tile center
        // can fall within the steering dead zone, leaving the tank slightly
        // off-center and unable to pass through narrow gaps.
        let minLookAhead = min(startIdx + 2, waypoints.count - 1)
        let nextIdx = min(startIdx + 1, waypoints.count - 1)
        var lookAheadIdx = minLookAhead

        if nextIdx < waypoints.count - 1 {
            let firstDx = waypoints[nextIdx].x - waypoints[startIdx].x
            let firstDy = waypoints[nextIdx].y - waypoints[startIdx].y

            for i in (nextIdx + 1)..<min(startIdx + 5, waypoints.count) {
                let dx = waypoints[i].x - waypoints[i - 1].x
                let dy = waypoints[i].y - waypoints[i - 1].y
                if dx == firstDx && dy == firstDy {
                    lookAheadIdx = max(lookAheadIdx, i)
                } else if i <= minLookAhead {
                    // Even if direction changed, include at least 2 ahead
                    lookAheadIdx = max(lookAheadIdx, i)
                } else {
                    break // Direction changed beyond minimum lookahead
                }
            }
        }

        NSLog("[Steer] tank=(%.1f,%.1f) startIdx=%d lookAheadIdx=%d target=(%d,%d) wpCount=%d",
              tankPos.x, tankPos.y, startIdx, lookAheadIdx,
              waypoints[lookAheadIdx].x, waypoints[lookAheadIdx].y, waypoints.count)

        var output = steerToward(target: waypoints[lookAheadIdx].vec2f, gameState: gameState)

        NSLog("[Steer] accel=%d decel=%d left=%d right=%d",
              output.accelerate ? 1 : 0, output.decelerate ? 1 : 0,
              output.left ? 1 : 0, output.right ? 1 : 0)

        // Slow down before corners: if there's a direction change within
        // the next few waypoints, brake so we don't overshoot the turn.
        // Don't brake on very short paths — the destination is close enough
        // that steerToward's own close-range braking handles it.
        let remainingWaypoints = waypoints.count - startIdx
        if output.accelerate && remainingWaypoints > 4 {
            let cornerIdx = findUpcomingCorner(waypoints: waypoints, fromIdx: startIdx, lookAhead: 4)
            if let cornerIdx = cornerIdx {
                let cornerPos = waypoints[cornerIdx].vec2f
                let distToCorner = distance(tankPos, cornerPos)
                // Brake when approaching a corner to avoid overshooting into
                // walls or water. At road speed (~3 tiles/sec) and 50 ticks/sec,
                // braking from 2 tiles away gives enough room to slow down.
                if distToCorner < 2.0 {
                    output.accelerate = false
                    output.decelerate = true
                }
            }
        }

        return output
    }

    /// Find the next direction change (corner) in the path within lookAhead steps.
    /// Returns the waypoint index where the turn occurs, or nil if the path is straight.
    private func findUpcomingCorner(waypoints: [TilePos], fromIdx: Int, lookAhead: Int) -> Int? {
        guard fromIdx + 1 < waypoints.count else { return nil }

        let firstDx = waypoints[fromIdx + 1].x - waypoints[fromIdx].x
        let firstDy = waypoints[fromIdx + 1].y - waypoints[fromIdx].y

        let endIdx = min(fromIdx + lookAhead, waypoints.count - 1)
        for i in (fromIdx + 2)...endIdx {
            let dx = waypoints[i].x - waypoints[i - 1].x
            let dy = waypoints[i].y - waypoints[i - 1].y
            if dx != firstDx || dy != firstDy {
                return i - 1 // The last waypoint before the direction change
            }
        }
        return nil
    }
}
