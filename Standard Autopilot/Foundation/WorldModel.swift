//
//  WorldModel.swift
//  XBolo
//
//  Interprets the raw game state into structured, useful information.
//

import Foundation
import BoloKit

// MARK: - Tile Position

struct TilePos: Equatable, Hashable {
    let x: Int
    let y: Int

    var vec2f: Vec2f {
        return Vec2f(x: Float(x) + 0.5, y: Float(y) + 0.5)
    }

    func distance(to other: TilePos) -> Int {
        return abs(x - other.x) + abs(y - other.y)
    }

    func floatDistance(to other: TilePos) -> Float {
        let dx = Float(x - other.x)
        let dy = Float(y - other.y)
        return sqrtf(dx * dx + dy * dy)
    }
}

func tilePosFromVec2f(_ v: Vec2f) -> TilePos {
    return TilePos(x: Int(v.x), y: Int(v.y))
}

// MARK: - Base Info

struct BaseInfo {
    enum Ownership {
        case friendly
        case hostile
        case neutral
    }

    let pos: TilePos
    let ownership: Ownership
}

// MARK: - Pill Info

struct PillInfo {
    enum Ownership {
        case friendly
        case hostile
    }

    let pos: TilePos
    let ownership: Ownership
    let armorLevel: Int // 0-15, derived from tile type offset
}

// MARK: - Terrain Classification

enum TerrainClass {
    case passable(cost: Float)   // Can drive through, with movement cost
    case impassable              // Walls, deep water
    case unknown                 // Fog of war
}

// MARK: - World Model

class WorldModel {
    private(set) var bases: [BaseInfo] = []
    private(set) var pills: [PillInfo] = []
    private(set) var friendlyBases: [BaseInfo] = []
    private(set) var hostileBases: [BaseInfo] = []
    private(set) var neutralBases: [BaseInfo] = []
    private(set) var hasBoat: Bool = false

    private var tiles: UnsafeMutablePointer<GSTileType>?
    private var width: Int = 0
    private var height: Int = 0

    /// Update the world model from the current game state.
    func update(from gameState: GSRobotGameState) {
        tiles = gameState.visibletiles
        width = Int(gameState.worldwidth)
        height = Int(gameState.worldheight)
        hasBoat = gameState.tankhasboat != 0

        bases.removeAll()
        pills.removeAll()
        friendlyBases.removeAll()
        hostileBases.removeAll()
        neutralBases.removeAll()

        guard let tiles = tiles else { return }

        // Scan visible tiles for bases and pillboxes
        // We only scan a reasonable area around the tank to avoid scanning 65536 tiles every tick.
        // But for base/pill finding we need the full map since we remember previously seen tiles.
        // The game state already provides the full seentiles array.
        for y in 0..<height {
            for x in 0..<width {
                let tile = tiles[y * width + x]
                switch tile {
                case .friendlyBaseTile:
                    let info = BaseInfo(pos: TilePos(x: x, y: y), ownership: .friendly)
                    bases.append(info)
                    friendlyBases.append(info)
                case .hostileBaseTile:
                    let info = BaseInfo(pos: TilePos(x: x, y: y), ownership: .hostile)
                    bases.append(info)
                    hostileBases.append(info)
                case .neutralBaseTile:
                    let info = BaseInfo(pos: TilePos(x: x, y: y), ownership: .neutral)
                    bases.append(info)
                    neutralBases.append(info)
                default:
                    if let pillInfo = parsePillTile(tile, x: x, y: y) {
                        pills.append(pillInfo)
                    }
                }
            }
        }
    }

    /// Get the tile at a given position. Returns kUnknownTile if out of bounds.
    func tile(at pos: TilePos) -> GSTileType {
        guard let tiles = tiles,
              pos.x >= 0, pos.x < width,
              pos.y >= 0, pos.y < height else {
            return .unknownTile
        }
        return tiles[pos.y * width + pos.x]
    }

    /// Classify terrain for pathfinding purposes.
    func terrainClass(at pos: TilePos) -> TerrainClass {
        let t = tile(at: pos)
        return Self.classifyTile(t)
    }

    /// Get the movement cost for pathfinding. Returns nil if impassable.
    /// Accounts for boat status: with a boat, water is cheap but stepping
    /// onto land is penalized (loses the boat). Without a boat, water is
    /// expensive/deadly but boat tiles are attractive (pick up a boat).
    func movementCost(at pos: TilePos) -> Float? {
        let t = tile(at: pos)

        if hasBoat {
            switch t {
            case .riverTile, .seaTile, .minedSeaTile:
                // With a boat we move at road speed on water
                return 1.5
            case .boatTile:
                // Already have a boat, boat tile is just water
                return 1.5
            default:
                // Stepping onto land loses the boat! Add a penalty to
                // discourage leaving water unless the destination requires it.
                // This doesn't prevent land paths — just makes the pathfinder
                // prefer staying on water when both options exist.
                break
            }
        } else {
            switch t {
            case .seaTile, .minedSeaTile:
                return nil // Deadly without a boat
            case .riverTile:
                // River without a boat: very slow AND drains 1 shell + 1 mine
                // every 15 ticks (0.3s). Treat as near-impassable so the
                // pathfinder strongly avoids it.
                return 20.0
            case .boatTile:
                // Boat pickup! Make this attractive — slightly cheaper than road
                // to encourage picking up boats when the path goes near water.
                return 0.8
            default:
                break
            }
        }

        switch terrainClass(at: pos) {
        case .passable(let cost): return cost
        case .impassable: return nil
        case .unknown: return 3.0  // Moderate cost — encourage exploration
        }
    }

    /// Extra cost for tiles adjacent to slower or impassable terrain.
    /// The tank has TANKRADIUS=0.375, so its body clips into adjacent tiles.
    /// This keeps the pathfinder away from terrain edges.
    func borderCost(at pos: TilePos) -> Float {
        let myCost = movementCost(at: pos) ?? 0
        if myCost == 0 { return 0 } // Impassable tile, no border cost

        var penalty: Float = 0
        for dy in -1...1 {
            for dx in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let neighbor = TilePos(x: pos.x + dx, y: pos.y + dy)
                if let neighborCost = movementCost(at: neighbor) {
                    // Adjacent tile is slower — add a fraction of the cost difference
                    if neighborCost > myCost {
                        penalty = max(penalty, (neighborCost - myCost) * 0.3)
                    }
                } else {
                    // Adjacent tile is impassable (wall, sea) — strong penalty
                    penalty = max(penalty, myCost * 0.5)
                }
            }
        }
        return penalty
    }

    /// Find the nearest friendly base to a position.
    func nearestFriendlyBase(to pos: TilePos) -> BaseInfo? {
        return friendlyBases.min(by: { $0.pos.floatDistance(to: pos) < $1.pos.floatDistance(to: pos) })
    }

    /// Check if a hostile pillbox has line-of-sight to a position (no walls in between).
    private func pillboxCanSee(pill: PillInfo, target: TilePos) -> Bool {
        let dx = target.x - pill.pos.x
        let dy = target.y - pill.pos.y
        let steps = max(abs(dx), abs(dy))
        if steps == 0 { return true }

        for i in 1..<steps {
            let x = pill.pos.x + dx * i / steps
            let y = pill.pos.y + dy * i / steps
            let t = tile(at: TilePos(x: x, y: y))
            if t == .wallTile || t == .damagedWallTile {
                return false  // Wall blocks line of sight
            }
        }
        return true
    }

    /// Find the nearest friendly base that isn't under fire from hostile pillboxes.
    /// Checks line-of-sight so a pillbox behind a wall doesn't count as a threat.
    /// Falls back to nearest if all are threatened.
    func nearestSafeFriendlyBase(to pos: TilePos) -> BaseInfo? {
        let pillRange: Float = 7.0
        let safeBases = friendlyBases.filter { base in
            !pills.contains { pill in
                pill.ownership == .hostile
                && pill.pos.floatDistance(to: base.pos) <= pillRange
                && pillboxCanSee(pill: pill, target: base.pos)
            }
        }
        if let nearest = safeBases.min(by: { $0.pos.floatDistance(to: pos) < $1.pos.floatDistance(to: pos) }) {
            return nearest
        }
        // All bases are threatened — pick nearest anyway
        return nearestFriendlyBase(to: pos)
    }

    /// Find the nearest non-friendly base (hostile or neutral).
    func nearestTargetBase(to pos: TilePos) -> BaseInfo? {
        let targets = hostileBases + neutralBases
        return targets.min(by: { $0.pos.floatDistance(to: pos) < $1.pos.floatDistance(to: pos) })
    }

    /// Additional cost penalty for tiles that are under threat from hostile
    /// pillboxes. Forest tiles are exempt beyond ~2 tiles (the tank is hidden).
    /// Returns 0 for safe tiles.
    ///
    /// The penalty is kept moderate (max 3.0) so the pathfinder prefers safer
    /// routes but doesn't create extreme detours that thread through tight
    /// gaps where the tank physically can't fit (TANKRADIUS = 0.375).
    func dangerCost(at pos: TilePos) -> Float {
        let isForest = isForestTile(at: pos)
        let forestVisRange: Float = 2.0
        let pillDangerRange: Float = 5.0  // Effective pillbox threat range
        let maxPenalty: Float = 3.0

        var totalPenalty: Float = 0
        for pill in pills where pill.ownership == .hostile {
            let dist = pill.pos.floatDistance(to: pos)
            if dist > pillDangerRange { continue }

            // Forest hides the tank beyond ~2 tiles
            if isForest && dist > forestVisRange { continue }

            // Closer = more dangerous. Penalty scales linearly from max at dist=0
            // to 0 at pillDangerRange.
            let penalty = maxPenalty * (1.0 - dist / pillDangerRange)
            totalPenalty += penalty
        }
        return totalPenalty
    }

    /// Whether the tank is well-hidden in forest at the given position.
    /// In the game engine, pillboxes can't see a tank in forest beyond
    /// ~2 tile distance (forestvis <= 0.25). The tank is considered hidden
    /// if it's on a forest tile.
    func isForestTile(at pos: TilePos) -> Bool {
        let t = tile(at: pos)
        return t == .forestTile || t == .minedForestTile
    }

    /// Whether a hostile pillbox is within the given range of a position.
    func nearestHostilePillDistance(to pos: TilePos) -> Float? {
        let hostilePills = pills.filter { $0.ownership == .hostile }
        guard let nearest = hostilePills.min(by: { $0.pos.floatDistance(to: pos) < $1.pos.floatDistance(to: pos) }) else {
            return nil
        }
        return nearest.pos.floatDistance(to: pos)
    }

    // MARK: - Private

    private func parsePillTile(_ tile: GSTileType, x: Int, y: Int) -> PillInfo? {
        let raw = tile.rawValue
        let friendlyStart = GSTileType.friendlyPill00Tile.rawValue
        let friendlyEnd = GSTileType.friendlyPill15Tile.rawValue
        let hostileStart = GSTileType.hostilePill00Tile.rawValue
        let hostileEnd = GSTileType.hostilePill15Tile.rawValue

        if raw >= friendlyStart && raw <= friendlyEnd {
            let armor = Int(raw - friendlyStart)
            return PillInfo(pos: TilePos(x: x, y: y), ownership: .friendly, armorLevel: armor)
        } else if raw >= hostileStart && raw <= hostileEnd {
            let armor = Int(raw - hostileStart)
            return PillInfo(pos: TilePos(x: x, y: y), ownership: .hostile, armorLevel: armor)
        }
        return nil
    }

    /// Classify tile terrain. Costs are proportional to inverse speed from the
    /// game engine's maxspeed() function (road = 3.125 as baseline cost 1.0).
    /// Water tiles are handled separately in movementCost(at:) based on boat status.
    static func classifyTile(_ tile: GSTileType) -> TerrainClass {
        switch tile {
        // Fast terrain — road speed 3.125
        case .roadTile, .minedRoadTile:
            return .passable(cost: 1.0)
        case .boatTile:
            return .passable(cost: 1.0)
        case .friendlyBaseTile, .hostileBaseTile, .neutralBaseTile:
            return .passable(cost: 1.0)

        // Medium terrain — grass speed 2.344 → cost 1.33
        case .grassTile, .minedGrassTile:
            return .passable(cost: 1.33)

        // Slow terrain — forest speed 1.172 → cost 2.67
        case .forestTile, .minedForestTile:
            return .passable(cost: 2.67)

        // Very slow terrain — rubble speed 0.586 → cost 5.33
        case .craterTile, .minedCraterTile:
            return .passable(cost: 5.33)
        case .swampTile, .minedSwampTile:
            return .passable(cost: 5.33)
        case .rubbleTile, .minedRubbleTile:
            return .passable(cost: 5.33)

        // Water — handled dynamically in movementCost(at:) based on boat status.
        // Classify as passable here; movementCost overrides for water tiles.
        case .riverTile:
            return .passable(cost: 5.33)
        case .seaTile, .minedSeaTile:
            return .impassable

        // Impassable walls
        case .wallTile, .damagedWallTile:
            return .impassable

        // Pillboxes — friendly are passable (road speed), hostile are impassable
        default:
            let raw = tile.rawValue
            if raw >= GSTileType.friendlyPill00Tile.rawValue && raw <= GSTileType.friendlyPill15Tile.rawValue {
                return .passable(cost: 1.0)
            } else if raw >= GSTileType.hostilePill00Tile.rawValue && raw <= GSTileType.hostilePill15Tile.rawValue {
                return .impassable
            } else if tile == .unknownTile {
                return .unknown
            }
            return .passable(cost: 2.0)
        }
    }
}
