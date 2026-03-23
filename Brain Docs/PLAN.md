# Brain Development Plan

## Phase 1: Foundation Framework (Current)

Shared Swift utilities that any brain can use, built into the Standard Autopilot
target (or a shared source group).

### Components

1. **WorldModel** - Interprets the raw tile array into useful data
   - Find all bases (friendly/hostile/neutral) and their positions
   - Find all pillboxes and their positions/armor
   - Classify terrain for pathfinding (passable, slow, impassable)
   - Track known map state across ticks

2. **Navigation** - A* pathfinding across the tile map
   - Terrain cost model (road=1, grass=1.3, forest=2.7, swamp=high, wall/water=impassable)
   - Path smoothing for natural movement
   - Steering: convert "go to tile X,Y" into accelerate/brake/turn commands

3. **Aiming** - Gun control utilities
   - Calculate angle to target
   - Adjust gun range (gunsight distance)
   - Lead calculation for moving targets
   - Fire decision (is target in range and aligned?)

4. **Steering** - Convert high-level goals into low-level commands
   - Turn toward a heading
   - Drive to a waypoint
   - Follow a path (sequence of waypoints)
   - Dodge incoming shells

## Phase 2: Base Collector Brain

First concrete brain built on the foundation.

### Behavior State Machine

```
EXPLORE -> found base -> NAVIGATE_TO_BASE
NAVIGATE_TO_BASE -> arrived at friendly/neutral base -> CAPTURE_BASE
NAVIGATE_TO_BASE -> arrived at hostile base -> ATTACK_BASE
CAPTURE_BASE -> base captured -> pick next base -> NAVIGATE_TO_BASE
ATTACK_BASE -> shells low -> RETREAT_TO_REFUEL
ATTACK_BASE -> base destroyed -> CAPTURE_BASE
RETREAT_TO_REFUEL -> arrived at friendly base -> REFUELING
REFUELING -> fully stocked -> pick target -> NAVIGATE_TO_BASE
```

### Priority System

1. If armor < threshold: retreat to nearest friendly base
2. If shells < threshold and near hostile base: retreat to refuel
3. If hostile base nearby: attack it
4. If neutral base nearby: go capture it
5. Otherwise: navigate to nearest uncaptured base

## Phase 3: Future Brains (Not Yet)

- **Hunter Brain** - Seeks and destroys enemy tanks
- **Defender Brain** - Captures and fortifies territory with pillboxes
- **Builder Brain** - Focuses on road/wall infrastructure

## File Organization

```
Standard Autopilot/
  StandardAutopilot.swift          # Original (untouched)
  Foundation/
    WorldModel.swift               # Map analysis
    Navigation.swift               # A* pathfinding
    Steering.swift                 # Movement control
    Aiming.swift                   # Gun targeting
    GameConstants.swift            # Shared constants
  Brains/
    BaseCollectorBrain.swift       # Phase 2 brain
```

Note: Since robots are loaded as bundles, each brain that ships as its own
`.xbolorobot` needs its own target. For development we'll build inside the
Standard Autopilot target and swap the principal class.
