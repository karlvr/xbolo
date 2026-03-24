//
//  BaseCollectorBrain.swift
//  XBolo
//
//  A brain that navigates the map collecting bases. Attacks hostile bases
//  and retreats to friendly bases to refuel when low on resources.
//

import Foundation
import BoloKit

// MARK: - Brain State Machine

enum BrainState {
    case scanning              // Looking for a target base
    case navigatingToBase      // Driving toward a target base
    case attackingBase         // Shooting at a hostile base
    case retreatingToRefuel   // Heading back to a friendly base
    case refueling            // Sitting on a friendly base restocking
}

// MARK: - Base Collector Brain

public class BaseCollectorBrain: NSObject, GSRobotProtocol {

    // Components
    private let world = WorldModel()
    private var pathfinder: Pathfinder!
    private let steering = SteeringController()
    private let aiming = AimingController()

    // State
    private var state: BrainState = .scanning
    private var targetBase: BaseInfo?
    private var currentPath: PathResult?
    private var refuelBase: BaseInfo?
    private var tickCount = 0
    private var replanCounter = 0

    // How often to recalculate path (ticks)
    private let replanInterval = 50  // Once per second

    public override required init() {
        super.init()
        pathfinder = Pathfinder(world: world)
    }

    public static var minimumRobotInterfaceVersionRequired: Int32 {
        return GS_ROBOT_CURRENT_INTERFACE_VERSION
    }

    public func stepXBoloRobot(with gameState: GSRobotGameState) -> GSRobotCommandState {
        let cmd = GSRobotCommandState()
        tickCount += 1
        replanCounter += 1

        // Update world model
        world.update(from: gameState)

        let tankTile = tilePosFromVec2f(gameState.tankposition)

        // Check for critical situations that override current state
        if shouldRetreat(gameState: gameState) && state != .retreatingToRefuel && state != .refueling {
            transitionToRetreat(tankTile: tankTile)
        }

        // Run state machine
        switch state {
        case .scanning:
            handleScanning(cmd: cmd, gameState: gameState, tankTile: tankTile)
        case .navigatingToBase:
            handleNavigating(cmd: cmd, gameState: gameState, tankTile: tankTile)
        case .attackingBase:
            handleAttacking(cmd: cmd, gameState: gameState, tankTile: tankTile)
        case .retreatingToRefuel:
            handleRetreating(cmd: cmd, gameState: gameState, tankTile: tankTile)
        case .refueling:
            handleRefueling(cmd: cmd, gameState: gameState, tankTile: tankTile)
        }

        // Always dodge incoming shells regardless of state
        applyShellDodging(cmd: cmd, gameState: gameState)

        return cmd
    }

    // MARK: - State Handlers

    private func handleScanning(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        // Look for the best target base
        if let target = pickTargetBase(tankTile: tankTile) {
            targetBase = target
            planPathToTarget(from: tankTile, to: target.pos)
            state = .navigatingToBase
        } else {
            // No bases found - just drive around exploring
            cmd.accelerate = true
            // Turn occasionally to explore
            if tickCount % 100 < 30 {
                cmd.left = true
            }
        }
    }

    private func handleNavigating(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        guard let target = targetBase else {
            state = .scanning
            return
        }

        // Check if target base ownership changed (someone else captured it)
        let currentTile = world.tile(at: target.pos)
        if currentTile == .friendlyBaseTile {
            // Already ours! Pick a new target.
            state = .scanning
            return
        }

        // Check if we've arrived at the target
        let distToTarget = distance(gameState.tankposition, target.pos.vec2f)
        if distToTarget < 2.0 {
            if target.ownership == .hostile {
                state = .attackingBase
                return
            } else {
                // Neutral base - just drive onto it to capture
                let steer = steering.steerToward(target: target.pos.vec2f, gameState: gameState)
                applySteeringToCmd(steer, cmd: cmd)

                // If we're right on top of it, check if captured
                if distToTarget < 0.8 {
                    state = .scanning // Will re-scan and it should be friendly now
                }
                return
            }
        }

        // Replan periodically
        if replanCounter >= replanInterval || currentPath == nil {
            planPathToTarget(from: tankTile, to: target.pos)
        }

        // Follow the path
        if let path = currentPath, !path.isEmpty {
            let steer = steering.followPath(path, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        } else {
            // No path - drive directly
            let steer = steering.steerToward(target: target.pos.vec2f, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        }
    }

    private func handleAttacking(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        guard let target = targetBase else {
            state = .scanning
            return
        }

        // Check if base is now captured
        let currentTile = world.tile(at: target.pos)
        if currentTile == .friendlyBaseTile || currentTile == .neutralBaseTile {
            // Base is no longer hostile - drive onto it to claim
            if currentTile == .neutralBaseTile {
                let steer = steering.steerToward(target: target.pos.vec2f, gameState: gameState)
                applySteeringToCmd(steer, cmd: cmd)
            } else {
                state = .scanning
            }
            return
        }

        let distToTarget = distance(gameState.tankposition, target.pos.vec2f)

        // Position ourselves at firing range (not too close to the base)
        let idealRange: Float = 4.0
        if distToTarget < idealRange - 1.0 {
            // Too close, back up a bit
            cmd.decelerate = true
        } else if distToTarget > idealRange + 1.5 {
            // Too far, move closer
            let steer = steering.steerToward(target: target.pos.vec2f, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        } else {
            // Good range - face the target and hold position
            let desiredAngle = angleTo(from: gameState.tankposition, to: target.pos.vec2f)
            let currentAngle = directionToRadians(Int(gameState.tankdirection))
            let diff = normalizeAngle(desiredAngle - currentAngle)

            let turnThreshold: Float = .pi / 16 // Half a direction step
            if diff > turnThreshold {
                cmd.left = true
            } else if diff < -turnThreshold {
                cmd.right = true
            }

            // Slight brake to hold position
            cmd.decelerate = true
        }

        // Aim and fire at the base
        let aimResult = aiming.aimAtStationary(target: target.pos.vec2f, gameState: gameState)
        cmd.gunup = aimResult.gunup
        cmd.gundown = aimResult.gundown
        cmd.fire = aimResult.fire

        // Check if we need to retreat for ammo
        if gameState.tankshells <= Int32(kLowShellsThreshold) {
            transitionToRetreat(tankTile: tankTile)
        }
    }

    private func handleRetreating(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        guard let base = refuelBase else {
            // No friendly base known - scan for one
            if let fb = world.nearestFriendlyBase(to: tankTile) {
                refuelBase = fb
            } else {
                // No friendly base at all - just keep fighting
                state = .scanning
                return
            }
            return
        }

        let distToBase = distance(gameState.tankposition, base.pos.vec2f)

        // Check if we've arrived
        if distToBase < 0.8 {
            state = .refueling
            return
        }

        // Replan periodically
        if replanCounter >= replanInterval || currentPath == nil {
            planPathToTarget(from: tankTile, to: base.pos)
        }

        // Follow path to friendly base
        if let path = currentPath, !path.isEmpty {
            let steer = steering.followPath(path, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        } else {
            let steer = steering.steerToward(target: base.pos.vec2f, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        }
    }

    private func handleRefueling(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        // Stay on the base - brake
        cmd.decelerate = true

        // Make sure we're on the base tile
        if let base = refuelBase {
            let dist = distance(gameState.tankposition, base.pos.vec2f)
            if dist > 1.0 {
                // Drifted off the base, steer back
                let steer = steering.steerToward(target: base.pos.vec2f, gameState: gameState)
                applySteeringToCmd(steer, cmd: cmd)
                return
            }

            // Check if base is still friendly
            let tile = world.tile(at: base.pos)
            if tile != .friendlyBaseTile {
                // Base was captured from us!
                state = .scanning
                return
            }
        }

        // Check if fully stocked
        let fullyStocked = gameState.tankshells >= Int32(kMaxShells - 5)
            && gameState.tankarmor >= Int32(kMaxArmor - 5)

        if fullyStocked {
            state = .scanning
        }
    }

    // MARK: - Decision Making

    private func shouldRetreat(gameState: GSRobotGameState) -> Bool {
        return gameState.tankarmor <= Int32(kCriticalArmorThreshold)
            || (gameState.tankarmor <= Int32(kLowArmorThreshold) && gameState.tankshells <= Int32(kLowShellsThreshold))
    }

    private func transitionToRetreat(tankTile: TilePos) {
        state = .retreatingToRefuel
        refuelBase = world.nearestFriendlyBase(to: tankTile)
        currentPath = nil
        replanCounter = replanInterval // Force immediate replan
    }

    /// Pick the best target base to go after.
    private func pickTargetBase(tankTile: TilePos) -> BaseInfo? {
        // Prioritize: neutral bases first (easy capture), then hostile bases
        let neutrals = world.neutralBases.sorted { $0.pos.floatDistance(to: tankTile) < $1.pos.floatDistance(to: tankTile) }
        if let nearest = neutrals.first {
            return nearest
        }

        let hostiles = world.hostileBases.sorted { $0.pos.floatDistance(to: tankTile) < $1.pos.floatDistance(to: tankTile) }
        if let nearest = hostiles.first {
            return nearest
        }

        return nil
    }

    // MARK: - Path Planning

    private func planPathToTarget(from: TilePos, to: TilePos) {
        replanCounter = 0
        currentPath = pathfinder.findPath(from: from, to: to)
    }

    // MARK: - Shell Dodging

    private func applyShellDodging(cmd: GSRobotCommandState, gameState: GSRobotGameState) {
        let shells = UnsafeBufferPointer(start: gameState.shells, count: Int(gameState.shellscount))
        let tankPos = gameState.tankposition

        for shell in shells {
            let shellDist = distance(tankPos, shell.position)
            if shellDist > 5.0 { continue } // Too far to worry about

            // Check if shell is heading roughly toward us
            let shellToTank = angleTo(from: shell.position, to: tankPos)
            let shellDir = shell.direction
            let angleDiff = abs(normalizeAngle(shellToTank - shellDir))

            if angleDiff < .pi / 4 && shellDist < 3.0 {
                // Shell is coming at us! Dodge perpendicular
                // Determine which side to dodge (pick the side we're already slightly offset to)
                let perpAngle = shellDir + .pi / 2
                let dodgeX = cosf(perpAngle)
                let dodgeY = -sinf(perpAngle)
                let offsetX = tankPos.x - shell.position.x
                let offsetY = tankPos.y - shell.position.y

                // Dot product to see which side we're on
                let dot = offsetX * dodgeX + offsetY * dodgeY

                if dot >= 0 {
                    cmd.left = true
                } else {
                    cmd.right = true
                }
                cmd.accelerate = true
                break // Dodge the nearest threat
            }
        }
    }

    // MARK: - Helpers

    private func applySteeringToCmd(_ steer: SteeringOutput, cmd: GSRobotCommandState) {
        if steer.accelerate { cmd.accelerate = true }
        if steer.decelerate { cmd.decelerate = true }
        if steer.left { cmd.left = true }
        if steer.right { cmd.right = true }
    }
}
