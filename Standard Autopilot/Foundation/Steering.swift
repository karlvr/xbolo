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
        let currentTile = tilePosFromVec2f(gameState.tankposition)

        // Look ahead in the path for a waypoint that's not our current tile
        // and try to look 2-3 tiles ahead for smoother movement
        var targetWaypoint: TilePos?

        if let waypoints = Optional(path.waypoints), waypoints.count > 0 {
            // Find our approximate position in the path
            var startIdx = 0
            for (i, wp) in waypoints.enumerated() {
                if wp == currentTile {
                    startIdx = i
                }
            }

            // Look 2-3 waypoints ahead for smooth steering
            let lookAhead = min(startIdx + 3, waypoints.count - 1)
            targetWaypoint = waypoints[lookAhead]
        }

        guard let target = targetWaypoint else {
            return SteeringOutput(decelerate: true)
        }

        return steerToward(target: target.vec2f, gameState: gameState)
    }
}
