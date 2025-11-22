---
description: Create a new zone/biome with procedural generation templates
---

# Add New Zone/Biome

Create a complete zone for Pickaxe Pioneer with unique visuals, enemies, and procedural generation.

## Zone Details
- **Zone Number:** [1-6]
- **Name:** [e.g., "The Toxic Wastes"]
- **Difficulty Tier:** [Early/Mid/Late game]
- **Theme:** [Visual and narrative theme]
- **Color Palette:** [Primary colors for zone]
- **Hazards:** [Environmental hazards specific to this zone]
- **Enemy Types:** [Which enemies spawn here]
- **Boss:** [Boss name if applicable]

## Implementation Checklist

### 1. Scene Setup
- [ ] Create `src/levels/zones/Zone[Number]_[Name].tscn`
- [ ] Create `src/levels/zones/Zone[Number]_[Name].gd` script
- [ ] Set up camera bounds for zone size
- [ ] Add background layers (parallax)

### 2. Visual Design
- [ ] Create 4-6 parallax background layers
- [ ] Design tileset/terrain visuals (SVG assets)
- [ ] Create color scheme config
- [ ] Add zone-specific decorative elements
- [ ] Add atmospheric particles (dust, fog, etc.)
- [ ] Implement zone-specific lighting

### 3. Procedural Generation
- [ ] Create room templates for this zone
  - [ ] Combat arenas (open areas)
  - [ ] Mining corridors (narrow paths)
  - [ ] Cache rooms (hidden treasure areas)
  - [ ] Boss chamber (if applicable)
- [ ] Configure generator parameters
  - [ ] Min/max room count
  - [ ] Room size ranges
  - [ ] Connection density
- [ ] Add zone-specific obstacles and cover

### 4. Enemy Spawning
- [ ] Configure enemy spawn tables
  - [ ] Enemy types and weights
  - [ ] Min/max spawn counts
  - [ ] Elite spawn chance
- [ ] Set up patrol points and spawn areas
- [ ] Configure difficulty scaling (time-based)
- [ ] Add boss spawn trigger (if applicable)

### 5. Resource Distribution
- [ ] Set scrap pile density and types
- [ ] Configure rare component node placement
- [ ] Add legendary cache spawn points (15% chance)
- [ ] Place data log spawns (2-3 per zone)
- [ ] Set up extraction zone location

### 6. Hazards & Mechanics
- [ ] Implement zone-specific hazards:
  - [ ] Damage zones (toxic pools, radiation)
  - [ ] Periodic damage (gas vents)
  - [ ] Environmental destructibles
  - [ ] Moving obstacles
- [ ] Add hazard visual indicators
- [ ] Configure damage values and timing

### 7. Audio
- [ ] Set zone music track
- [ ] Add ambient sound loops (wind, machinery, etc.)
- [ ] Configure combat music layers
- [ ] Add zone-specific sound effects

### 8. Overworld Integration
- [ ] Add zone to overworld map
- [ ] Configure unlock conditions
- [ ] Set up node connections
- [ ] Add zone description/tooltip
- [ ] Create zone preview image

### 9. Data Logs (Lore)
- [ ] Write 8-10 data log entries for this zone
- [ ] Place log spawns in interesting locations
- [ ] Ensure logs advance the main story
- [ ] Add hints about secrets/caches

### 10. Testing & Balance
- [ ] Playtest full run from start to extraction
- [ ] Verify difficulty curve
- [ ] Test procedural generation (multiple seeds)
- [ ] Balance resource distribution
- [ ] Ensure all spawns work correctly

## Code Template

```gdscript
# src/levels/zones/Zone[Number]_[Name].gd
extends Node2D
class_name Zone[Number][Name]

const ZONE_ID = [number]
const ZONE_NAME = "[Name]"
const DIFFICULTY_TIER = [1-3]

@onready var level_generator = $LevelGenerator
@onready var enemy_spawner = $EnemySpawner
@onready var loot_spawner = $LootSpawner
@onready var parallax_bg = $ParallaxBackground

# Zone configuration
const ENEMY_SPAWN_TABLE = {
    "[EnemyType1]": 50,  # Weight
    "[EnemyType2]": 30,
    "[EnemyType3]": 20,
}

const HAZARD_CONFIG = {
    "toxic_pool_count": 5,
    "gas_vent_count": 3,
    "damage_per_tick": 5,
}

func _ready():
    _generate_level()
    _spawn_enemies()
    _spawn_resources()
    _spawn_hazards()
    _setup_audio()

func _generate_level():
    var seed_value = GameManager.current_run_seed
    level_generator.generate(seed_value, ZONE_ID)

func _spawn_enemies():
    enemy_spawner.configure_spawn_table(ENEMY_SPAWN_TABLE)
    enemy_spawner.spawn_initial_wave()

func _spawn_resources():
    loot_spawner.spawn_scrap_piles([count])
    loot_spawner.spawn_rare_nodes([count])
    loot_spawner.spawn_legendary_cache() # 15% chance
    loot_spawner.spawn_data_logs([count])

func _spawn_hazards():
    for i in HAZARD_CONFIG.toxic_pool_count:
        _spawn_toxic_pool()
    for i in HAZARD_CONFIG.gas_vent_count:
        _spawn_gas_vent()

func _setup_audio():
    MusicManager.transition_to("zone_[number]_exploration")
    # Add ambient sounds

# Zone-specific hazard implementations
func _spawn_toxic_pool():
    # Create damage area
    pass

func _spawn_gas_vent():
    # Create periodic damage zone
    pass
```

## Procedural Generation Config

```json
{
  "zone_id": [number],
  "name": "[ZoneName]",
  "size": {
    "width": 5000,
    "height": 3000
  },
  "rooms": {
    "min_count": 8,
    "max_count": 15,
    "templates": [
      "combat_arena_small",
      "combat_arena_large",
      "mining_corridor",
      "cache_room",
      "boss_chamber"
    ]
  },
  "connections": {
    "density": 0.7,
    "min_corridor_width": 150
  },
  "theme": {
    "background_color": "#[hex]",
    "terrain_color": "#[hex]",
    "accent_color": "#[hex]"
  }
}
```

Please create this zone with all required assets and integration points.
