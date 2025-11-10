# Père Casseur (Scab Claus) Development Guide

## Project Overview
Mobile idle-arcade game built with **Godot 4.5** (GDScript). Portrait mode (720×1280), 24-minute gameplay session where a capitalist Santa delivers 8.2 billion gifts while the world deteriorates. French/English localization support.

## Architecture

### Core Components
- **GameManager** (autoload singleton): Central state manager tracking delivery rates, collectible multipliers, tier progression, and gift counter
- **Game scene**: Main gameplay orchestration - spawns collectibles/enemies, manages HUD, handles pause/menu
- **Player**: CharacterBody2D controlling Santa's movement, gift throwing, and collision detection
- **PowerUpAnimator**: Spawns animated power-up icons that fly across screen when tiers unlock

### Key Design Patterns

**Signal-driven architecture**: GameManager emits signals that UI and gameplay systems subscribe to:
```gdscript
# GameManager signals
signal tier_unlocked(tier_number: int, tier_name: String)
signal tier_progress_updated(tier_number: int, progress: float)
signal stats_updated(info: String)
```

**Exponential progression**: Base delivery rate grows exponentially over time: `base_delivery_rate = exp(GROWTH_FACTOR * time_elapsed)`. Combined with collectible multipliers for compounding growth.

**Resource pooling pattern**: Collectibles (fuel, oil, bribes) inherit from Area2D with common `release(amount)` animation and cleanup pattern.

## Critical Game Constants
Located in `scenes/game_manager.gd`:
- `TOTAL_GIFTS: float = 8_200_000_000.0` - World population to deliver to
- `IDLE_DURATION: float = 1440.0` - Target 24-minute session length
- `GROWTH_FACTOR: float = 0.013` - Calibrates exponential delivery scaling
- `NUM_TIERS: int = 11` - Power-up unlock tiers (0-10)
- `TIER_NAMES: Array[String]` - Maps tier numbers to satirical power-up names

## Scene Structure
- `res://scenes/game.tscn` - Main gameplay scene
- `res://scenes/menu.tscn` - Pause menu with settings (music/SFX volume, language)
- `res://scenes/player.tscn` - Santa character with collision, smoke particles, timers
- `res://entities/` - Collectibles, gifts, mobs, power-ups organized by type
- Power-ups use dual-scene pattern: `power1-texture.tscn` (icon only, used in flying animations) and `power1.tscn` (icon with status bar for HUD)

## Naming Conventions
- **Classes**: PascalCase with explicit typing (`class_name Player extends CharacterBody2D`)
- **Files**: snake_case matching class names (`player.gd`, `game_manager.gd`)
- **Scene paths**: Use `res://` prefix, organized by entity type
- **Node references**: Use `@onready` for scene tree nodes, `%` for unique names
- **Constants**: SCREAMING_SNAKE_CASE at top of files

## Localization
- Translation keys in `lang/text.fr.csv` compiled to `.translation` binary
- Wrap all user-facing strings in `tr()` using English text as the key: `tr("Fuel")`, `tr("Oil")`, `tr("Bribe")`
- HUD messages constructed with dynamic values: `tr("TIER") + " 0: " + tr("Solopreneur")`

## Physics & Collision Layers
Defined in `project.godot`:
- Layer 1: Default (player, boundaries)
- Layer 2: Gift (thrown presents)
- Layer 3: Elf (enemies that reduce multiplier)

## Performance Patterns
- Preload scenes as constants: `const FUEL_SCENE: PackedScene = preload("res://entities/collect/fuel.tscn")`
- `queue_free()` on `screen_exited` for all spawned entities
- Use `VisibleOnScreenNotifier2D` to cleanup off-screen objects
- GPUParticles2D for Santa's smoke trail

## Testing & Debugging
- Adjust `gifts_counter` in `GameManager._ready()` to skip tiers, ie. `gifts_counter = 25`
- Timer intervals in `game.gd` control spawn rates (collectibles: 0.5-1s, enemies: 3-5s)
- GDScript strict mode enabled: warnings for untyped declarations and unsafe access

## Common Workflows

**Adding new collectible type**:
1. Create scene in `entities/collect/` with Area2D, Sprite2D, AudioStreamPlayer, VisibleOnScreenNotifier2D
2. Implement `release(amount: int)` method with fade-out tween
3. Add `collect_<type>()` method in GameManager with multiplier logic
4. Add to spawn pool in `game.gd` spawn_collectible()

**Adding new power-up tier**:
1. Add tier name to `GameManager.TIER_NAMES` array
2. Create `powerX.png` icon (120×120px) in `entities/power/`
3. Create matching `powerX-texture.tscn` and `powerX.tscn` with particle trail
4. Add `-texture.tscn` scene reference to `PowerUpAnimator.POWER_SCENES` array

**Adjusting game balance**:
- **Growth rate**: Modify `GROWTH_FACTOR` in `GameManager` (higher = faster exponential scaling)
- **Collectible spawn frequency**: Adjust `spawn_collectible_interval_min/max` in `game.gd` (lower = more frequent)
- **Enemy spawn frequency**: Adjust `spawn_enemy_interval_min/max` in `game.gd`
- **Collectible multipliers**: Edit values in `GameManager.collect_fuel()` (+10%), `collect_oil()` (+25%), `collect_bribe()` (+50%)
- **Enemy penalty**: Modify `-0.05` multiplier reduction in `GameManager.mob_hit()`
- **Test balance**: Set `gifts_counter = X` in `GameManager._ready()` to jump to late-game tiers quickly

## Critical Files
- `docs/BRIEF.md` - Complete game design document with mechanics, progression, tone
- `docs/ART.md` - Asset specifications and checklist
- `project.godot` - Engine config, autoload registration, display settings
- `scenes/game_manager.gd` - Core progression math and state management
