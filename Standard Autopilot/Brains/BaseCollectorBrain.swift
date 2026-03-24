//
//  BaseCollectorBrain.swift
//  XBolo
//
//  A brain that navigates the map collecting bases. Attacks hostile bases
//  and retreats to friendly bases to refuel when low on resources.
//

import Foundation
import BoloKit

// MARK: - Exploration Chunk

/// A coarse grid position for tracking explored areas.
struct ChunkPos: Hashable {
    let cx: Int
    let cy: Int
}

// MARK: - Brain State Machine

enum BrainState {
    case scanning              // Looking for a target base
    case navigatingToBase      // Driving toward a target base
    case attackingBase         // Shooting at a hostile base
    case retreatingToRefuel   // Heading back to a friendly base
    case refueling            // Sitting on a friendly base restocking
    case exploring             // No known targets — exploring unexplored map areas
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
    private var pathFailCount = 0
    private var lastTankTile = TilePos(x: -1, y: -1)
    private var lastArmor: Int32 = -1
    private var unreachableTargets: [TilePos: Int] = [:]  // pos -> tick when it was blacklisted

    // Exploration state — track which map chunks we've visited
    private var exploredChunks = Set<ChunkPos>()
    private var exploreTarget: TilePos?
    private var exploreFailCount = 0

    // How often to recalculate path (ticks)
    private let replanInterval = 50  // Once per second
    private let maxPathFailures = 3  // Give up on target after this many failures
    private let unreachableCooldown = 500  // Re-try unreachable targets after ~10 seconds
    private let chunkSize = 16  // Exploration chunk size in tiles
    private let maxExploreFailures = 3  // Give up on an explore target after this many failures

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

        // Skip brain execution while the tank is dead. Running the state
        // machine during death corrupts state (shouldRetreat fires because
        // armor is 0, pathfinding fails from invalid position, etc.).
        // Reset state so we start clean on respawn.
        if gameState.tankarmor <= 0 {
            if lastArmor > 0 {
                // Just died — reset everything for respawn
                resetBrainState()
            }
            lastArmor = gameState.tankarmor
            return cmd
        }

        replanCounter += 1

        // Update world model
        world.update(from: gameState)

        let tankTile = tilePosFromVec2f(gameState.tankposition)

        // Mark the current chunk as explored
        let currentChunk = chunkFor(tankTile)
        exploredChunks.insert(currentChunk)

        // Detect respawn: tank teleported far away (spawned at a new location).
        let teleported = lastTankTile.x >= 0
            && (abs(tankTile.x - lastTankTile.x) > 5 || abs(tankTile.y - lastTankTile.y) > 5)
        if teleported {
            resetBrainState()
        }
        lastTankTile = tankTile
        lastArmor = gameState.tankarmor

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
        case .exploring:
            handleExploring(cmd: cmd, gameState: gameState, tankTile: tankTile)
        }

        // Dodge incoming shells — but not if we're hidden in forest.
        // Pillboxes can't see us in forest beyond ~2 tiles, so dodging
        // would just give away our position or move us out of cover.
        let inForest = world.isForestTile(at: tankTile)
        let nearHostilePill = (world.nearestHostilePillDistance(to: tankTile) ?? .infinity) <= 2.0
        if !inForest || nearHostilePill {
            applyShellDodging(cmd: cmd, gameState: gameState)
        }

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
            // No known targets — explore the map to find bases
            transitionToExploring(tankTile: tankTile)
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

        // Check if we've arrived at the target.
        // Use tile adjacency (Manhattan distance) not Euclidean distance,
        // because Euclidean < 2.0 can mean "close but with a wall between us".
        let distToTarget = distance(gameState.tankposition, target.pos.vec2f)
        let tileAdjacent = tankTile.distance(to: target.pos) <= 1

        if tileAdjacent {
            if target.ownership == .hostile {
                state = .attackingBase
                return
            } else {
                // Neutral base — drive directly onto it to capture
                let steer = steering.steerToward(target: target.pos.vec2f, gameState: gameState)
                applySteeringToCmd(steer, cmd: cmd)

                // If we're right on top of it, check if captured
                if distToTarget < 0.8 {
                    state = .scanning // Will re-scan and it should be friendly now
                }
                return
            }
        }

        // Replan periodically and re-evaluate whether this is still the best target.
        // Only replan on the timer — do NOT replan every tick when currentPath is nil,
        // as that runs expensive A* pathfinding 50 times per second.
        if replanCounter >= replanInterval {
            // Re-evaluate: pickTargetBase already returns the best target
            // (nearest neutral first, then nearest hostile). If it differs
            // from our current target, switch — don't cling to a stale goal
            // when a better one is available.
            if let better = pickTargetBase(tankTile: tankTile), better.pos != target.pos {
                targetBase = better
                planPathToTarget(from: tankTile, to: better.pos)
                return
            }

            planPathToTarget(from: tankTile, to: target.pos)
        }

        // Follow the path
        if let path = currentPath, !path.isEmpty {
            let steer = steering.followPath(path, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        } else {
            // No path found — stop and wait for the next scheduled replan.
            // Do NOT drive directly toward the target (ignores obstacles).
            cmd.decelerate = true
            pathFailCount += 1
            if pathFailCount >= maxPathFailures {
                // Can't reach this target — blacklist it temporarily and pick a new one
                if let target = targetBase {
                    unreachableTargets[target.pos] = tickCount
                }
                pathFailCount = 0
                state = .scanning
            }
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

        // Replan periodically (not every tick — A* is expensive)
        if replanCounter >= replanInterval {
            planPathToTarget(from: tankTile, to: base.pos)
        }

        // Follow path to friendly base
        if let path = currentPath, !path.isEmpty {
            let steer = steering.followPath(path, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        } else {
            // No path to friendly base — stop and wait for the next scheduled replan
            cmd.decelerate = true
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

    private func handleExploring(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        // Check if a base target has appeared while exploring
        if let target = pickTargetBase(tankTile: tankTile) {
            targetBase = target
            planPathToTarget(from: tankTile, to: target.pos)
            state = .navigatingToBase
            return
        }

        // Pick an explore target if we don't have one or have arrived
        if let target = exploreTarget {
            let dist = tankTile.floatDistance(to: target)
            if dist < 2.0 {
                // Arrived at explore target — pick a new one
                exploreTarget = nil
                exploreFailCount = 0
            }
        }

        if exploreTarget == nil {
            if let target = pickExploreTarget(tankTile: tankTile) {
                exploreTarget = target
                exploreFailCount = 0
                planPathToTarget(from: tankTile, to: target)
            } else {
                // Everywhere is explored or unreachable — reset and try again
                exploredChunks.removeAll()
                state = .scanning
                return
            }
        }

        // Replan periodically
        if replanCounter >= replanInterval, let target = exploreTarget {
            // Also re-check for bases each replan
            if let base = pickTargetBase(tankTile: tankTile) {
                targetBase = base
                planPathToTarget(from: tankTile, to: base.pos)
                state = .navigatingToBase
                return
            }
            planPathToTarget(from: tankTile, to: target)
        }

        // Follow the path
        if let path = currentPath, !path.isEmpty {
            let steer = steering.followPath(path, gameState: gameState)
            applySteeringToCmd(steer, cmd: cmd)
        } else {
            // Can't reach explore target — give up on it
            cmd.decelerate = true
            exploreFailCount += 1
            if exploreFailCount >= maxExploreFailures {
                // Mark this chunk as explored (even though we couldn't reach it)
                // so we don't keep trying
                if let target = exploreTarget {
                    exploredChunks.insert(chunkFor(target))
                }
                exploreTarget = nil
                exploreFailCount = 0
            }
        }
    }

    // MARK: - Exploration

    private func chunkFor(_ pos: TilePos) -> ChunkPos {
        return ChunkPos(cx: pos.x / chunkSize, cy: pos.y / chunkSize)
    }

    private func chunkCenter(_ chunk: ChunkPos) -> TilePos {
        return TilePos(x: chunk.cx * chunkSize + chunkSize / 2,
                       y: chunk.cy * chunkSize + chunkSize / 2)
    }

    private func transitionToExploring(tankTile: TilePos) {
        state = .exploring
        exploreTarget = nil
        exploreFailCount = 0
        currentPath = nil
    }

    /// Pick the nearest unexplored chunk center to navigate toward.
    private func pickExploreTarget(tankTile: TilePos) -> TilePos? {
        let chunksX = kWorldWidth / chunkSize
        let chunksY = kWorldHeight / chunkSize
        let tankChunk = chunkFor(tankTile)

        var bestTarget: TilePos?
        var bestDist: Float = .infinity

        // Search in expanding rings from the tank's chunk to find nearest unexplored
        let maxRadius = max(chunksX, chunksY)
        for radius in 1...maxRadius {
            for dcx in -radius...radius {
                for dcy in -radius...radius {
                    // Only check the border of this ring
                    if abs(dcx) != radius && abs(dcy) != radius { continue }

                    let cx = tankChunk.cx + dcx
                    let cy = tankChunk.cy + dcy
                    guard cx >= 0, cx < chunksX, cy >= 0, cy < chunksY else { continue }

                    let chunk = ChunkPos(cx: cx, cy: cy)
                    if exploredChunks.contains(chunk) { continue }

                    let center = chunkCenter(chunk)
                    let dist = center.floatDistance(to: tankTile)
                    if dist < bestDist {
                        bestDist = dist
                        bestTarget = center
                    }
                }
            }
            // If we found something in this ring, no need to search further
            if bestTarget != nil { return bestTarget }
        }

        return bestTarget
    }

    // MARK: - State Reset

    private func resetBrainState() {
        state = .scanning
        targetBase = nil
        currentPath = nil
        refuelBase = nil
        replanCounter = 0
        pathFailCount = 0
        unreachableTargets.removeAll()
        exploreTarget = nil
        exploreFailCount = 0
        // Note: don't clear exploredChunks — we remember what we've seen across respawns
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

    /// Pick the best target base to go after, skipping recently-unreachable targets.
    private func pickTargetBase(tankTile: TilePos) -> BaseInfo? {
        // Expire old blacklist entries
        unreachableTargets = unreachableTargets.filter { tickCount - $0.value < unreachableCooldown }

        func isReachable(_ base: BaseInfo) -> Bool {
            return unreachableTargets[base.pos] == nil
        }

        // Prioritize: neutral bases first (easy capture), then hostile bases
        let neutrals = world.neutralBases
            .filter(isReachable)
            .sorted { $0.pos.floatDistance(to: tankTile) < $1.pos.floatDistance(to: tankTile) }
        if let nearest = neutrals.first {
            return nearest
        }

        let hostiles = world.hostileBases
            .filter(isReachable)
            .sorted { $0.pos.floatDistance(to: tankTile) < $1.pos.floatDistance(to: tankTile) }
        if let nearest = hostiles.first {
            return nearest
        }

        // If everything is blacklisted, clear the blacklist and try again
        if !unreachableTargets.isEmpty {
            unreachableTargets.removeAll()
            return pickTargetBase(tankTile: tankTile)
        }

        return nil
    }

    // MARK: - Path Planning

    private func planPathToTarget(from: TilePos, to: TilePos) {
        replanCounter = 0
        currentPath = pathfinder.findPath(from: from, to: to)
        if currentPath != nil {
            pathFailCount = 0
        }
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
