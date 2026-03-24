//
//  Navigation.swift
//  XBolo
//
//  A* pathfinding across the XBolo tile map.
//

import Foundation
import BoloKit

// MARK: - Path Result

struct PathResult {
    let waypoints: [TilePos]
    let totalCost: Float

    var isEmpty: Bool { waypoints.isEmpty }

    /// Get the next waypoint to navigate toward (skips current tile).
    func nextWaypoint(from currentTile: TilePos) -> TilePos? {
        // Find first waypoint that isn't our current tile
        for wp in waypoints {
            if wp != currentTile {
                return wp
            }
        }
        return nil
    }
}

// MARK: - A* Pathfinder

class Pathfinder {
    private let world: WorldModel

    init(world: WorldModel) {
        self.world = world
    }

    /// Find a path from start to goal using A*.
    /// Returns nil if no path exists.
    func findPath(from start: TilePos, to goal: TilePos, maxIterations: Int = 2000) -> PathResult? {
        // Quick check: if goal is impassable, try adjacent tiles
        if world.movementCost(at: goal) == nil {
            // Try to path to an adjacent passable tile
            if let alternate = nearestPassableNeighbor(of: goal) {
                return findPathInternal(from: start, to: alternate, maxIterations: maxIterations)
            }
            return nil
        }
        return findPathInternal(from: start, to: goal, maxIterations: maxIterations)
    }

    private func findPathInternal(from start: TilePos, to goal: TilePos, maxIterations: Int) -> PathResult? {
        if start == goal {
            return PathResult(waypoints: [start], totalCost: 0)
        }

        var openSet = BinaryHeap<AStarNode>()
        var gScore: [TilePos: Float] = [:]
        var cameFrom: [TilePos: TilePos] = [:]
        var closedSet = Set<TilePos>()

        let startNode = AStarNode(pos: start, f: heuristic(start, goal), g: 0)
        openSet.insert(startNode)
        gScore[start] = 0

        var iterations = 0

        while let current = openSet.extractMin() {
            iterations += 1
            if iterations > maxIterations { return nil }

            if current.pos == goal {
                return reconstructPath(cameFrom: cameFrom, current: goal, gScore: gScore)
            }

            if closedSet.contains(current.pos) { continue }
            closedSet.insert(current.pos)

            for neighbor in neighbors(of: current.pos) {
                if closedSet.contains(neighbor) { continue }

                guard let cost = world.movementCost(at: neighbor) else { continue }

                // Diagonal movement costs sqrt(2) * tile cost.
                // Danger and border are multipliers: slow terrain near a pillbox
                // costs proportionally more (you're exposed longer). This avoids
                // distorting paths onto worse terrain just to avoid pillboxes.
                let isDiagonal = neighbor.x != current.pos.x && neighbor.y != current.pos.y
                let baseCost = isDiagonal ? cost * 1.414 : cost
                let dangerMult = 1.0 + world.dangerCost(at: neighbor)
                let borderAdd = world.borderCost(at: neighbor)

                // Penalty for stepping from water to land when on a boat.
                // Losing the boat makes all subsequent water tiles impassable/expensive,
                // so this one-time cost discourages leaving water prematurely.
                var transitionCost: Float = 0
                if world.hasBoat && world.isWaterTile(at: current.pos) && !world.isWaterTile(at: neighbor) {
                    transitionCost = 15.0
                }

                let moveCost = baseCost * dangerMult + borderAdd + transitionCost
                let tentativeG = current.g + moveCost

                if tentativeG < (gScore[neighbor] ?? Float.infinity) {
                    gScore[neighbor] = tentativeG
                    cameFrom[neighbor] = current.pos
                    let f = tentativeG + heuristic(neighbor, goal)
                    openSet.insert(AStarNode(pos: neighbor, f: f, g: tentativeG))
                }
            }
        }

        return nil // No path found
    }

    private func heuristic(_ a: TilePos, _ b: TilePos) -> Float {
        // Octile distance heuristic (allows diagonal movement)
        let dx = Float(abs(a.x - b.x))
        let dy = Float(abs(a.y - b.y))
        return max(dx, dy) + 0.414 * min(dx, dy)
    }

    private func neighbors(of pos: TilePos) -> [TilePos] {
        var result: [TilePos] = []
        for dy in -1...1 {
            for dx in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let nx = pos.x + dx
                let ny = pos.y + dy
                guard nx >= 0, nx < kWorldWidth, ny >= 0, ny < kWorldHeight else { continue }

                // For diagonal movement, both adjacent cardinal tiles must be passable
                // to prevent cutting corners through walls
                if dx != 0 && dy != 0 {
                    let cardX = TilePos(x: pos.x + dx, y: pos.y)
                    let cardY = TilePos(x: pos.x, y: pos.y + dy)
                    if world.movementCost(at: cardX) == nil || world.movementCost(at: cardY) == nil {
                        continue
                    }
                }

                result.append(TilePos(x: nx, y: ny))
            }
        }
        return result
    }

    private func nearestPassableNeighbor(of pos: TilePos) -> TilePos? {
        let cardinals = [
            TilePos(x: pos.x, y: pos.y - 1),
            TilePos(x: pos.x + 1, y: pos.y),
            TilePos(x: pos.x, y: pos.y + 1),
            TilePos(x: pos.x - 1, y: pos.y),
        ]
        return cardinals.first(where: {
            $0.x >= 0 && $0.x < kWorldWidth && $0.y >= 0 && $0.y < kWorldHeight
            && world.movementCost(at: $0) != nil
        })
    }

    private func reconstructPath(cameFrom: [TilePos: TilePos], current: TilePos, gScore: [TilePos: Float]) -> PathResult {
        var path: [TilePos] = [current]
        var node = current
        while let prev = cameFrom[node] {
            path.append(prev)
            node = prev
        }
        path.reverse()
        return PathResult(waypoints: path, totalCost: gScore[current] ?? 0)
    }
}

// MARK: - A* Node

private struct AStarNode: Comparable {
    let pos: TilePos
    let f: Float
    let g: Float

    static func < (lhs: AStarNode, rhs: AStarNode) -> Bool {
        return lhs.f < rhs.f
    }

    static func == (lhs: AStarNode, rhs: AStarNode) -> Bool {
        return lhs.pos == rhs.pos && lhs.f == rhs.f
    }
}

// MARK: - Binary Heap (Min-Heap)

struct BinaryHeap<T: Comparable> {
    private var storage: [T] = []

    var isEmpty: Bool { storage.isEmpty }

    mutating func insert(_ element: T) {
        storage.append(element)
        siftUp(storage.count - 1)
    }

    mutating func extractMin() -> T? {
        guard !storage.isEmpty else { return nil }
        if storage.count == 1 { return storage.removeLast() }
        let min = storage[0]
        storage[0] = storage.removeLast()
        siftDown(0)
        return min
    }

    private mutating func siftUp(_ index: Int) {
        var i = index
        while i > 0 {
            let parent = (i - 1) / 2
            if storage[i] < storage[parent] {
                storage.swapAt(i, parent)
                i = parent
            } else {
                break
            }
        }
    }

    private mutating func siftDown(_ index: Int) {
        var i = index
        let count = storage.count
        while true {
            let left = 2 * i + 1
            let right = 2 * i + 2
            var smallest = i
            if left < count && storage[left] < storage[smallest] { smallest = left }
            if right < count && storage[right] < storage[smallest] { smallest = right }
            if smallest == i { break }
            storage.swapAt(i, smallest)
            i = smallest
        }
    }
}
