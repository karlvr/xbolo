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

    private var tiles: UnsafeMutablePointer<GSTileType>?
    private var width: Int = 0
    private var height: Int = 0

    /// Update the world model from the current game state.
    func update(from gameState: GSRobotGameState) {
        tiles = gameState.visibletiles
        width = Int(gameState.worldwidth)
        height = Int(gameState.worldheight)

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
    func movementCost(at pos: TilePos) -> Float? {
        switch terrainClass(at: pos) {
        case .passable(let cost): return cost
        case .impassable: return nil
        case .unknown: return 5.0  // High cost but not impassable - explore cautiously
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

    static func classifyTile(_ tile: GSTileType) -> TerrainClass {
        switch tile {
        // Fast terrain
        case .roadTile, .minedRoadTile:
            return .passable(cost: 1.0)
        case .boatTile:
            return .passable(cost: 1.0)
        // Bases are passable (and desirable!)
        case .friendlyBaseTile, .hostileBaseTile, .neutralBaseTile:
            return .passable(cost: 1.0)

        // Medium terrain
        case .grassTile, .minedGrassTile:
            return .passable(cost: 1.33)
        case .craterTile, .minedCraterTile:
            return .passable(cost: 1.33)

        // Slow terrain
        case .swampTile, .minedSwampTile:
            return .passable(cost: 2.0)
        case .rubbleTile, .minedRubbleTile:
            return .passable(cost: 2.5)

        // Very slow terrain
        case .forestTile, .minedForestTile:
            return .passable(cost: 2.67)

        // Impassable
        case .wallTile, .damagedWallTile:
            return .impassable
        case .riverTile:
            return .impassable
        case .seaTile, .minedSeaTile:
            return .impassable

        // Pillboxes - hostile ones are dangerous, friendly ones passable
        default:
            let raw = tile.rawValue
            if raw >= GSTileType.friendlyPill00Tile.rawValue && raw <= GSTileType.friendlyPill15Tile.rawValue {
                return .passable(cost: 1.5)
            } else if raw >= GSTileType.hostilePill00Tile.rawValue && raw <= GSTileType.hostilePill15Tile.rawValue {
                return .impassable // Don't path through hostile pillboxes
            } else if tile == .unknownTile {
                return .unknown
            }
            return .passable(cost: 2.0) // Default fallback
        }
    }
}
