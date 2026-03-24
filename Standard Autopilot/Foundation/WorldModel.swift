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
    /// Accounts for boat status: with a boat, water is fast; without, it's
    /// very slow (river) or deadly (sea).
    func movementCost(at pos: TilePos) -> Float? {
        let t = tile(at: pos)

        // Boat-aware water handling
        if hasBoat {
            switch t {
            case .riverTile, .seaTile, .minedSeaTile:
                // With a boat we move at road speed on water, but we risk
                // losing the boat if shot — add a risk premium.
                return 2.0
            default:
                break
            }
        } else {
            switch t {
            case .seaTile, .minedSeaTile:
                return nil // Deadly without a boat
            case .riverTile:
                return 5.33 // Passable but extremely slow without a boat
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

    /// Find the nearest friendly base to a position.
    func nearestFriendlyBase(to pos: TilePos) -> BaseInfo? {
        return friendlyBases.min(by: { $0.pos.floatDistance(to: pos) < $1.pos.floatDistance(to: pos) })
    }

    /// Find the nearest non-friendly base (hostile or neutral).
    func nearestTargetBase(to pos: TilePos) -> BaseInfo? {
        let targets = hostileBases + neutralBases
        return targets.min(by: { $0.pos.floatDistance(to: pos) < $1.pos.floatDistance(to: pos) })
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
