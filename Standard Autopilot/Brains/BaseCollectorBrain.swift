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
    private var state: BrainState = .scanning {
        didSet {
            if state != oldValue {
                NSLog("[Brain] %@ → %@", "\(oldValue)", "\(state)")
            }
        }
    }
    private var targetBase: BaseInfo?
    private var currentPath: PathResult?
    private var refuelBase: BaseInfo?
    private var tickCount = 0
    private var replanCounter = 0
    private var pathFailCount = 0
    private var lastTankTile = TilePos(x: -1, y: -1)
    private var stuckTickCount = 0
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
    private let stuckThreshold = 150  // ~3 seconds without moving = stuck

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
                NSLog("[Brain] Tank died — resetting state")
                resetBrainState()
            }
            lastArmor = gameState.tankarmor
            return cmd
        }

        replanCounter += 1

        // Update world model
        world.update(from: gameState)

        let tankTile = tilePosFromVec2f(gameState.tankposition)

        // Mark all chunks within the tank's visibility range (14 tiles) as explored.
        // This means the tank doesn't need to travel to the center of each chunk —
        // simply being able to see into it is enough.
        markVisibleChunksExplored(tankTile: tankTile)

        // Detect respawn: tank teleported far away (spawned at a new location).
        let teleported = lastTankTile.x >= 0
            && (abs(tankTile.x - lastTankTile.x) > 5 || abs(tankTile.y - lastTankTile.y) > 5)
        if teleported {
            NSLog("[Brain] Respawn detected at (%d, %d)", tankTile.x, tankTile.y)
            resetBrainState()
        }
        // Detect being stuck: if the tank hasn't moved tiles for several seconds,
        // abandon the current target and try something else.
        if tankTile == lastTankTile {
            stuckTickCount += 1
            if stuckTickCount >= stuckThreshold && state != .scanning {
                NSLog("[Brain] Stuck for %d ticks at (%d, %d) — abandoning current goal",
                      stuckTickCount, tankTile.x, tankTile.y)
                if let target = targetBase {
                    unreachableTargets[target.pos] = tickCount
                }
                stuckTickCount = 0
                currentPath = nil
                state = .scanning
            }
        } else {
            stuckTickCount = 0
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

        NSLog("[Cmd] accel=%d decel=%d left=%d right=%d",
              cmd.accelerate ? 1 : 0, cmd.decelerate ? 1 : 0,
              cmd.left ? 1 : 0, cmd.right ? 1 : 0)

        return cmd
    }

    // MARK: - State Handlers

    private func handleScanning(cmd: GSRobotCommandState, gameState: GSRobotGameState, tankTile: TilePos) {
        // Look for the best target base
        if let target = pickTargetBase(tankTile: tankTile) {
            targetBase = target
            NSLog("[Brain] Target: %@ base at (%d, %d)", "\(target.ownership)", target.pos.x, target.pos.y)
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
                    NSLog("[Brain] Blacklisting unreachable base at (%d, %d)", target.pos.x, target.pos.y)
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
            if let fb = world.nearestSafeFriendlyBase(to: tankTile) {
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

        // Check if we can already see the explore target chunk (no need to walk right up to it)
        if let target = exploreTarget {
            let targetChunk = chunkFor(target)
            if exploredChunks.contains(targetChunk) {
                // We can see it from here — pick a new target
                exploreTarget = nil
                exploreFailCount = 0
            }
        }

        if exploreTarget == nil {
            if let target = pickExploreTarget(tankTile: tankTile) {
                exploreTarget = target
                exploreFailCount = 0
                NSLog("[Brain] Explore target: (%d, %d), %d/%d chunks explored",
                      target.x, target.y, exploredChunks.count,
                      (kWorldWidth / chunkSize) * (kWorldHeight / chunkSize))
                planPathToTarget(from: tankTile, to: target)
            } else {
                // Everywhere is explored or unreachable — reset and try again
                NSLog("[Brain] All chunks explored — resetting exploration")
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

    /// The tank's visibility radius in tiles (the game uses a 29x29 rect = 14 tiles each side).
    private let visibilityRange = 14

    /// Mark all chunks that fall within the tank's visibility as explored.
    private func markVisibleChunksExplored(tankTile: TilePos) {
        let minCX = max(0, (tankTile.x - visibilityRange) / chunkSize)
        let maxCX = min(kWorldWidth / chunkSize - 1, (tankTile.x + visibilityRange) / chunkSize)
        let minCY = max(0, (tankTile.y - visibilityRange) / chunkSize)
        let maxCY = min(kWorldHeight / chunkSize - 1, (tankTile.y + visibilityRange) / chunkSize)

        for cy in minCY...maxCY {
            for cx in minCX...maxCX {
                exploredChunks.insert(ChunkPos(cx: cx, cy: cy))
            }
        }
    }

    private func chunkFor(_ pos: TilePos) -> ChunkPos {
        return ChunkPos(cx: pos.x / chunkSize, cy: pos.y / chunkSize)
    }

    /// Get a passable tile within the chunk to navigate to.
    /// Tries the center first, then searches nearby within the chunk.
    private func passableTileInChunk(_ chunk: ChunkPos) -> TilePos? {
        let baseX = chunk.cx * chunkSize
        let baseY = chunk.cy * chunkSize
        let center = TilePos(x: baseX + chunkSize / 2, y: baseY + chunkSize / 2)

        // Try center first
        if world.movementCost(at: center) != nil {
            return center
        }

        // Search outward from center within the chunk for a passable tile
        for radius in 1..<(chunkSize / 2) {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    if abs(dx) != radius && abs(dy) != radius { continue }
                    let pos = TilePos(x: center.x + dx, y: center.y + dy)
                    guard pos.x >= baseX, pos.x < baseX + chunkSize,
                          pos.y >= baseY, pos.y < baseY + chunkSize else { continue }
                    if world.movementCost(at: pos) != nil {
                        return pos
                    }
                }
            }
        }

        return nil // Entire chunk is impassable (e.g., ocean)
    }

    private func transitionToExploring(tankTile: TilePos) {
        state = .exploring
        exploreTarget = nil
        exploreFailCount = 0
        currentPath = nil
    }

    /// Check whether a chunk is adjacent to (or contains) any known land tiles.
    /// Chunks that are entirely deep sea with no land neighbors are deprioritized
    /// since bolo maps have a central landmass surrounded by ocean.
    private func chunkNearLand(_ chunk: ChunkPos) -> Bool {
        // Check this chunk and its 8 neighbors for any non-sea, non-unknown tiles
        for dcy in -1...1 {
            for dcx in -1...1 {
                let cx = chunk.cx + dcx
                let cy = chunk.cy + dcy
                guard cx >= 0, cx < kWorldWidth / chunkSize,
                      cy >= 0, cy < kWorldHeight / chunkSize else { continue }

                let baseX = cx * chunkSize
                let baseY = cy * chunkSize
                // Sample a few positions in the chunk
                for sy in stride(from: 0, to: chunkSize, by: 4) {
                    for sx in stride(from: 0, to: chunkSize, by: 4) {
                        let t = world.tile(at: TilePos(x: baseX + sx, y: baseY + sy))
                        if t != .seaTile && t != .minedSeaTile && t != .unknownTile {
                            return true
                        }
                    }
                }
            }
        }
        return false
    }

    /// Pick the nearest unexplored chunk to navigate toward.
    /// Prefers chunks near known land; only explores deep sea as a last resort.
    private func pickExploreTarget(tankTile: TilePos) -> TilePos? {
        let chunksX = kWorldWidth / chunkSize
        let chunksY = kWorldHeight / chunkSize
        let tankChunk = chunkFor(tankTile)

        var bestLandTarget: TilePos?
        var bestLandDist: Float = .infinity
        var bestSeaTarget: TilePos?
        var bestSeaDist: Float = .infinity

        // Search in expanding rings from the tank's chunk
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

                    // Find a passable tile in this chunk; skip if entirely impassable
                    guard let target = passableTileInChunk(chunk) else {
                        exploredChunks.insert(chunk) // Mark impassable chunks as explored
                        continue
                    }
                    let dist = target.floatDistance(to: tankTile)

                    if chunkNearLand(chunk) {
                        if dist < bestLandDist {
                            bestLandDist = dist
                            bestLandTarget = target
                        }
                    } else {
                        if dist < bestSeaDist {
                            bestSeaDist = dist
                            bestSeaTarget = target
                        }
                    }
                }
            }
            // Prefer land targets; only use sea if no land target in any ring
            if bestLandTarget != nil { return bestLandTarget }
        }

        // Fall back to deep sea exploration only if no land chunks remain
        return bestSeaTarget
    }

    // MARK: - State Reset

    private func resetBrainState() {
        state = .scanning
        targetBase = nil
        currentPath = nil
        refuelBase = nil
        replanCounter = 0
        pathFailCount = 0
        stuckTickCount = 0
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
        refuelBase = world.nearestSafeFriendlyBase(to: tankTile)
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

        // All known bases are blacklisted or none exist — return nil
        // so the brain falls through to exploration mode
        return nil
    }

    // MARK: - Path Planning

    private func planPathToTarget(from: TilePos, to: TilePos) {
        replanCounter = 0
        currentPath = pathfinder.findPath(from: from, to: to)
        if let path = currentPath {
            pathFailCount = 0
            NSLog("[Brain] Path: (%d,%d)→(%d,%d), %d waypoints, cost %.1f",
                  from.x, from.y, to.x, to.y, path.waypoints.count, path.totalCost)
        } else {
            NSLog("[Brain] Path FAILED: (%d,%d)→(%d,%d)", from.x, from.y, to.x, to.y)
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
                // Shell is coming at us! Dodge perpendicular.
                // REPLACE all steering — don't just add flags on top of
                // path-following, which causes conflicting accelerate+decelerate.
                cmd.accelerate = false
                cmd.decelerate = false
                cmd.left = false
                cmd.right = false

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
