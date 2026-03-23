//
//  Aiming.swift
//  XBolo
//
//  Gun targeting and firing control.
//

import Foundation
import BoloKit

// MARK: - Aiming Output

struct AimingOutput {
    var gunup = false
    var gundown = false
    var fire = false
}

// MARK: - Aiming Controller

class AimingController {

    /// Aim and fire at a stationary target position (e.g., a base or pillbox tile).
    /// The gun range is the distance from tank to gunsight.
    func aimAtStationary(target: Vec2f, gameState: GSRobotGameState) -> AimingOutput {
        var output = AimingOutput()
        let tankPos = gameState.tankposition
        let gunsight = gameState.gunsightposition

        let targetDist = distance(tankPos, target)

        // Check if target is within shell range
        if targetDist > kMaxRange || targetDist < kMinRange {
            return output // Out of range, don't fire
        }

        // Current gunsight distance from tank
        let currentRange = distance(tankPos, gunsight)

        // Adjust range to match target distance
        let rangeDiff = targetDist - currentRange
        let rangeThreshold: Float = 0.5

        if rangeDiff > rangeThreshold {
            output.gunup = true
        } else if rangeDiff < -rangeThreshold {
            output.gundown = true
        }

        // Check if we're aimed roughly at the target
        let desiredAngle = angleTo(from: tankPos, to: target)
        let currentAngle = directionToRadians(Int(gameState.tankdirection))
        let angleDiff = abs(normalizeAngle(desiredAngle - currentAngle))

        // Fire if aimed within ~22 degrees and range is close
        let aimThreshold: Float = .pi / 8
        if angleDiff < aimThreshold && abs(rangeDiff) < 1.0 {
            output.fire = true
        }

        return output
    }

    /// Aim at a moving tank with lead prediction.
    func aimAtTank(tank: Tank, gameState: GSRobotGameState) -> AimingOutput {
        // For now, just aim at current position.
        // Lead prediction would need velocity info we don't have from the Tank struct.
        return aimAtStationary(target: tank.position, gameState: gameState)
    }

    /// Check if a target position is roughly in our line of fire.
    func isTargetInFiringArc(target: Vec2f, gameState: GSRobotGameState, arcRadians: Float = .pi / 6) -> Bool {
        let desiredAngle = angleTo(from: gameState.tankposition, to: target)
        let currentAngle = directionToRadians(Int(gameState.tankdirection))
        let angleDiff = abs(normalizeAngle(desiredAngle - currentAngle))
        return angleDiff < arcRadians
    }

    /// Get the distance from the tank to a target.
    func distanceToTarget(_ target: Vec2f, gameState: GSRobotGameState) -> Float {
        return distance(gameState.tankposition, target)
    }
}
