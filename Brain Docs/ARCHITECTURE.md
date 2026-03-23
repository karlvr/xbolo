# XBolo Brain Architecture

## Overview

This document describes the AI brain system for XBolo tank game. Brains are
implemented as `.xbolorobot` bundles that conform to the `GSRobotProtocol`.

## Robot Plugin Interface

Each brain is a Swift class that:
1. Inherits from `NSObject` and conforms to `GSRobotProtocol`
2. Implements `stepXBoloRobot(with:) -> GSRobotCommandState` called every game tick (50 Hz)
3. Receives a `GSRobotGameState` snapshot and returns commands

### GSRobotGameState (Input)

| Property | Type | Description |
|----------|------|-------------|
| `worldwidth`, `worldheight` | `Int` | Always 256x256 |
| `visibletiles` | `UnsafeMutablePointer<GSTileType>` | 256x256 row-major tile array |
| `tankposition` | `Vec2f` | Tank's floating-point position (x, y) in tile coords |
| `gunsightposition` | `Vec2f` | Where the gun is currently aimed |
| `tankdirection` | `Int` | 0-15 (16 compass directions) |
| `tankarmor` | `Int` | 0-40 |
| `tankshells` | `Int` | 0-40 |
| `tankmines` | `Int` | 0-40 |
| `tanktrees` | `Int` | 0-40 |
| `tankhasboat` | `Int` | 0 or 1 |
| `tankpillcount` | `Int` | Number of pills carried on board |
| `builderstate` | `Int` | 0=dead, 1=in tank, 2=out of tank |
| `builderdirection` | `Float` | Radians (only valid if builderstate == 2) |
| `tanks` | `UnsafeMutablePointer<Tank>` | Visible enemy/ally tanks |
| `tankscount` | `Int` | Number of visible tanks |
| `shells` | `UnsafeMutablePointer<Shell>` | Visible shells in flight |
| `shellscount` | `Int` | Number of visible shells |
| `builders` | `UnsafeMutablePointer<Builder>` | Visible builders |
| `builderscount` | `Int` | Number of visible builders |
| `messages` | `[String]?` | Chat messages received |

### GSRobotCommandState (Output)

| Property | Type | Description |
|----------|------|-------------|
| `accelerate` | `Bool` | Move forward |
| `decelerate` | `Bool` | Brake |
| `left` | `Bool` | Turn left |
| `right` | `Bool` | Turn right |
| `gunup` | `Bool` | Increase gun range |
| `gundown` | `Bool` | Decrease gun range |
| `fire` | `Bool` | Shoot |
| `mine` | `Bool` | Place a mine |
| `buildercommand` | `GSBuilderOperation` | BUILDERNILL, BUILDERTREE, BUILDERROAD, BUILDERWALL, BUILDERPILL, BUILDERMINE |
| `builderx`, `buildery` | `Int` | Builder target tile |
| `playersToAllyWith` | `[String]` | Player names to request alliance with |

### Key Tile Types

- **Terrain**: kWallTile, kRiverTile, kSwampTile, kCraterTile, kRoadTile, kForestTile, kRubbleTile, kGrassTile
- **Mined terrain**: kMinedSwampTile through kMinedGrassTile
- **Bases**: kFriendlyBaseTile, kHostileBaseTile, kNeutralBaseTile
- **Pillboxes**: kFriendlyPill00-15Tile, kHostilePill00-15Tile (armour encoded in tile number)
- **Unknown**: kUnknownTile (fog of war)

## Game Constants

| Constant | Value | Description |
|----------|-------|-------------|
| TICKSPERSEC | 50 | Game ticks per second |
| MAXSHELLS | 40 | Max shells carried |
| MAXARMOUR | 40 | Max armor |
| MAXMINES | 40 | Max mines carried |
| MAXTREES | 40 | Max trees carried |
| SHELLVEL | 7.0 | Shell speed (tiles/sec) |
| BOATMAXSPEED / ROADMAXSPEED | 3.125 | Fastest ground speed (tiles/sec) |
| GRASSMAXSPEED | 2.34375 | Speed on grass |
| FORESTMAXSPEED | 1.171875 | Speed in forest |
| RUBBLEMAXSPEED | 0.5859375 | Speed on rubble |

## Direction System

The `tankdirection` field uses 0-15 representing 16 compass directions:
- 0 = North (up, -Y)
- 4 = East (+X)
- 8 = South (+Y)
- 12 = West (-X)

Internally, angles are in radians where 0 = East, PI/2 = North (mathematical convention).
The conversion in GSRobot.m is: `tankdirection = gunAngle * 8 / PI - 0.5`

## Coordinate System

- World is 256x256 tiles
- Position (0,0) is top-left
- X increases rightward, Y increases downward
- Tank positions are floating-point within tile grid
- Tile at position (x, y) is accessed as `visibletiles[y * 256 + x]`

## Visibility

- Tiles outside view range show as `kUnknownTile`
- Fog of war means you can only see terrain/units near your tank
- Previously seen tiles are remembered (fog shows last-known state)

## Refueling

- Drive onto a friendly base to refuel armor, shells, mines
- Refuel rates: armor every 46 ticks, shells every 7 ticks, mines every 7 ticks
- Must stay on the base tile to continue refueling

## Builder

- Builder starts inside tank (state 1)
- Send builder out with a command + target tile
- Builder walks to target, performs task, walks back
- Builder is vulnerable while outside
- Builder must return before next command
