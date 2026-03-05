extends Node2D

# Space Mining Level — a cat miner in SPACE!
# Player is a CharacterBody2D that moves freely with gravity/jumping.
# Terrain is a grid; tiles are rendered by MineAbleTileMapLayer/NonMineAbleTileMapLayer (z=0).
# Overlays (cursor, sonar, boss, particles) are rendered by TerrainOverlay (z=1).
# Mining is cursor-based: click to mine space rocks and asteroids within range.
# Energy drains over time while in deep space (faster at distance).

const GRID_COLS: int = 96
const GRID_ROWS: int = 128
const CELL_SIZE: int = 64
const EXIT_COLS: int = 2

const VIEWPORT_W: int = 1280
const VIEWPORT_H: int = 720

enum TileType {
	EMPTY            = 0,
	DIRT             = 1,
	DIRT_DARK        = 2,
	ORE_COPPER       = 3,
	ORE_COPPER_DEEP  = 4,
	ORE_IRON         = 5,
	ORE_IRON_DEEP    = 6,
	ORE_GOLD         = 7,
	ORE_GOLD_DEEP    = 8,
	ORE_GEM          = 9,
	ORE_GEM_DEEP     = 10,
	STONE            = 11,
	STONE_DARK       = 12,
	EXPLOSIVE        = 13,
	EXPLOSIVE_ARMED  = 14,
	LAVA             = 15,
	LAVA_FLOW        = 16,
	ENERGY_NODE        = 17,
	ENERGY_NODE_FULL   = 18,
	REENERGY_STATION   = 19,
	SURFACE          = 20,
	SURFACE_GRASS    = 21,
	EXIT_STATION     = 22,
	BOSS_SEGMENT     = 23,   # Boss body segment — high HP, awards minerals on death
	BOSS_CORE        = 24,   # Boss core / head — highest HP, big reward
	UPGRADE_STATION  = 25,   # Upgrade station — permanent upgrades using banked minerals
	SMELTERY_STATION = 26,   # Smeltery — smelt ores into bars and sell them
	LADDER           = 27,   # Placeable ladder — player climbs up by pressing jump
	CAT_TAVERN       = 28,   # Underground Cat Tavern — hire mining/collecting cats
}

const TILE_NAMES: Dictionary = {
	TileType.SURFACE_GRASS:   "Space Dust",
	TileType.DIRT:            "Moon Rock",
	TileType.DIRT_DARK:       "Dense Moon Rock",
	TileType.STONE:           "Asteroid",
	TileType.STONE_DARK:      "Dark Asteroid",
	TileType.ORE_COPPER:      "Lunar Copper",
	TileType.ORE_COPPER_DEEP: "Deep Lunar Copper",
	TileType.ORE_IRON:        "Meteor Iron",
	TileType.ORE_IRON_DEEP:   "Deep Meteor Iron",
	TileType.ORE_GOLD:        "Star Gold",
	TileType.ORE_GOLD_DEEP:   "Deep Star Gold",
	TileType.ORE_GEM:         "Cosmic Gem",
	TileType.ORE_GEM_DEEP:    "Deep Cosmic Gem",
	TileType.ENERGY_NODE:       "Energy Cell",
	TileType.ENERGY_NODE_FULL:  "Energy Cell",
	TileType.EXPLOSIVE:       "Space Mine",
	TileType.EXPLOSIVE_ARMED: "Armed Space Mine",
	TileType.LAVA:            "Plasma",
	TileType.LAVA_FLOW:       "Plasma Stream",
	TileType.REENERGY_STATION:  "Recharging Station",
	TileType.SURFACE:         "Launchpad",
	TileType.EXIT_STATION:    "Airlock",
	TileType.BOSS_SEGMENT:    "Boss Segment",
	TileType.BOSS_CORE:       "Boss Core",
	TileType.UPGRADE_STATION: "Upgrade Bay",
	TileType.SMELTERY_STATION: "Space Forge",
	TileType.LADDER:          "Ladder",
	TileType.CAT_TAVERN:      "Cat Tavern",
}

# Hardcoded particle burst colours per tile type.
# These approximate each tile's visual appearance so debris matches the block.
const TILE_PARTICLE_COLORS: Dictionary = {
	TileType.SURFACE_GRASS:    Color(0.45, 0.72, 0.30),  # green surface dust
	TileType.DIRT:             Color(0.76, 0.60, 0.42),  # sandy tan moon rock
	TileType.DIRT_DARK:        Color(0.50, 0.35, 0.20),  # dark brown dense rock
	TileType.STONE:            Color(0.58, 0.58, 0.62),  # cool grey asteroid
	TileType.STONE_DARK:       Color(0.38, 0.38, 0.42),  # dark grey asteroid
	TileType.ORE_COPPER:       Color(0.78, 0.44, 0.20),  # copper orange
	TileType.ORE_COPPER_DEEP:  Color(0.65, 0.32, 0.12),  # deeper copper
	TileType.ORE_IRON:         Color(0.65, 0.68, 0.75),  # steel grey-blue
	TileType.ORE_IRON_DEEP:    Color(0.45, 0.48, 0.58),  # darker iron
	TileType.ORE_GOLD:         Color(1.00, 0.80, 0.10),  # bright gold
	TileType.ORE_GOLD_DEEP:    Color(0.85, 0.60, 0.05),  # deep gold
	TileType.ORE_GEM:          Color(0.20, 0.80, 0.90),  # cyan crystal
	TileType.ORE_GEM_DEEP:     Color(0.15, 0.55, 0.85),  # deep gem blue
	TileType.ENERGY_NODE:      Color(0.20, 0.60, 1.00),  # electric blue
	TileType.ENERGY_NODE_FULL: Color(0.30, 0.90, 1.00),  # bright cyan
	TileType.EXPLOSIVE:        Color(1.00, 0.55, 0.05),  # danger orange
	TileType.EXPLOSIVE_ARMED:  Color(1.00, 0.55, 0.05),  # danger orange
	TileType.LAVA:             Color(1.00, 0.35, 0.05),  # molten red-orange
	TileType.LAVA_FLOW:        Color(1.00, 0.35, 0.05),  # molten red-orange
	TileType.BOSS_SEGMENT:     Color(0.55, 0.10, 0.70),  # dark purple
	TileType.BOSS_CORE:        Color(0.90, 0.05, 0.90),  # bright magenta
}

const MINEABLE_TILES: Array = [
	TileType.SURFACE_GRASS,
	TileType.DIRT, TileType.DIRT_DARK,
	TileType.STONE, TileType.STONE_DARK,
	TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP,
	TileType.ORE_IRON, TileType.ORE_IRON_DEEP,
	TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP,
	TileType.ORE_GEM, TileType.ORE_GEM_DEEP,
	TileType.BOSS_SEGMENT, TileType.BOSS_CORE,
	TileType.LAVA, TileType.LAVA_FLOW,
]

# Atlas coordinates in blocks_tileset.tres (blocks_atlas.png, 64 px tiles, alphabetical layout).
# TileType.SURFACE, EXIT_STATION, BOSS_SEGMENT, BOSS_CORE, LADDER are drawn by _draw().
const TILE_ATLAS_COORDS: Dictionary = {
	TileType.DIRT:             Vector2i(1, 2),   # dirt.png
	TileType.DIRT_DARK:        Vector2i(9, 4),   # mud.png
	TileType.STONE:            Vector2i(7, 7),   # stone_generic.png
	TileType.STONE_DARK:       Vector2i(4, 3),   # gravel.png
	TileType.ORE_COPPER:       Vector2i(0, 8),   # stone_ore_copper.png
	TileType.ORE_COPPER_DEEP:  Vector2i(0, 8),
	TileType.ORE_IRON:         Vector2i(2, 8),   # stone_ore_iron.png
	TileType.ORE_IRON_DEEP:    Vector2i(2, 8),
	TileType.ORE_GOLD:         Vector2i(1, 8),   # stone_ore_gold.png
	TileType.ORE_GOLD_DEEP:    Vector2i(1, 8),
	TileType.ORE_GEM:          Vector2i(8, 7),   # stone_generic_ore_crystalline.png
	TileType.ORE_GEM_DEEP:     Vector2i(8, 7),
	TileType.EXPLOSIVE:        Vector2i(4, 2),   # eucalyptus_log_top.png
	TileType.EXPLOSIVE_ARMED:  Vector2i(4, 2),
	TileType.LAVA:             Vector2i(5, 6),   # sand_ugly_3.png
	TileType.LAVA_FLOW:        Vector2i(5, 6),
	TileType.ENERGY_NODE:      Vector2i(9, 3),   # limestone.png
	TileType.ENERGY_NODE_FULL: Vector2i(5, 4),   # marble.png
	TileType.REENERGY_STATION: Vector2i(8, 0),   # cobblestone_bricks.png
	TileType.SURFACE_GRASS:    Vector2i(1, 3),   # grass_side.png
	TileType.UPGRADE_STATION:  Vector2i(8, 0),
	TileType.SMELTERY_STATION: Vector2i(8, 0),
	TileType.CAT_TAVERN:       Vector2i(8, 0),
}

const TILE_HP: Dictionary = {
	TileType.SURFACE_GRASS:   5,
	TileType.DIRT:            5,
	TileType.DIRT_DARK:       5,
	TileType.STONE:           9,
	TileType.STONE_DARK:      11,
	TileType.ORE_COPPER:      12,
	TileType.ORE_COPPER_DEEP: 14,
	TileType.ORE_IRON:        15,
	TileType.ORE_IRON_DEEP:   18,
	TileType.ORE_GOLD:        21,
	TileType.ORE_GOLD_DEEP:   24,
	TileType.ORE_GEM:         30,
	TileType.ORE_GEM_DEEP:    33,
	TileType.BOSS_SEGMENT:    15,
	TileType.BOSS_CORE:       29,
	TileType.LAVA:            7,
	TileType.LAVA_FLOW:       7,
}

const TILE_MIN_HITS: Dictionary = {
	TileType.SURFACE_GRASS:   1,
	TileType.DIRT:            1,
	TileType.DIRT_DARK:       1,
	TileType.STONE:           2,
	TileType.STONE_DARK:      2,
	TileType.ORE_COPPER:      3,
	TileType.ORE_COPPER_DEEP: 3,
	TileType.ORE_IRON:        3,
	TileType.ORE_IRON_DEEP:   4,
	TileType.ORE_GOLD:        4,
	TileType.ORE_GOLD_DEEP:   5,
	TileType.ORE_GEM:         6,
	TileType.ORE_GEM_DEEP:    7,
	TileType.BOSS_SEGMENT:    3,
	TileType.BOSS_CORE:       5,
	TileType.LAVA:            2,
	TileType.LAVA_FLOW:       2,
}

const TILE_MINERALS: Dictionary = {
	TileType.SURFACE_GRASS:   1,
	TileType.DIRT:            1,
	TileType.DIRT_DARK:       1,
	TileType.STONE:           2,
	TileType.STONE_DARK:      2,
	TileType.ORE_COPPER:      3,
	TileType.ORE_COPPER_DEEP: 5,
	TileType.ORE_IRON:        5,
	TileType.ORE_IRON_DEEP:   8,
	TileType.ORE_GOLD:        10,
	TileType.ORE_GOLD_DEEP:   15,
	TileType.ORE_GEM:         5,   # primary value now comes as a gem item
	TileType.ORE_GEM_DEEP:    8,   # primary value now comes as a gem item
	TileType.BOSS_SEGMENT:    10,
	TileType.BOSS_CORE:       75,
}

const ORE_TILES: Array = [
	TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP,
	TileType.ORE_IRON, TileType.ORE_IRON_DEEP,
	TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP,
	TileType.ORE_GEM, TileType.ORE_GEM_DEEP,
]

const LUCKY_STRIKE_CHANCE := 0.08
const SURFACE_ROWS: int = 3

# ---------------------------------------------------------------------------
# Smelting / consecutive-chain system (§3.5)
# ---------------------------------------------------------------------------
# Ore group tags used to identify chain membership
const SMELT_ORE_GROUPS: Dictionary = {
	TileType.ORE_COPPER:      "copper",
	TileType.ORE_COPPER_DEEP: "copper",
	TileType.ORE_IRON:        "iron",
	TileType.ORE_IRON_DEEP:   "iron",
	TileType.ORE_GOLD:        "gold",
	TileType.ORE_GOLD_DEEP:   "gold",
	TileType.ORE_GEM:         "gem",
	TileType.ORE_GEM_DEEP:    "gem",
}
# Chain bonus at 3 consecutive: [bonus_pct, popup_label]
const SMELT_CHAIN_BONUSES: Dictionary = {
	"copper": [0.50, "Lunar Alloy"],
	"iron":   [0.50, "Meteor Steel"],
	"gold":   [0.75, "Star Ingot"],
	"gem":    [1.00, "Nova Crystal"],
}
# Two-ore cross-combos: "first+second" -> [bonus_pct, popup_label]
const SMELT_COMBOS: Dictionary = {
	"copper+iron": [1.00, "Astro Alloy"],
	"iron+copper": [1.00, "Astro Alloy"],
	"iron+gold":   [2.00, "Cosmic Steel"],
	"gold+iron":   [2.00, "Cosmic Steel"],
	"copper+gold": [1.50, "Stardust Blend"],
	"gold+copper": [1.50, "Stardust Blend"],
}

# Space Forge constants live in MiningShopSystem.gd

# ---------------------------------------------------------------------------
# Legendary Space Cat system (§3.6)
# ---------------------------------------------------------------------------
const FOSSIL_BASE_RATE: float  = 0.005
const FOSSIL_DROUGHT_SCALE: float = 0.005
const FOSSIL_CAP_RATE: float   = 0.30
const FOSSIL_TYPES: Dictionary = {
	TileType.DIRT:            {"name": "Astro Kitten",    "minerals": 25},
	TileType.DIRT_DARK:       {"name": "Stellar Kitten",  "minerals": 30},
	TileType.STONE:           {"name": "Nebula Cat",      "minerals": 50},
	TileType.STONE_DARK:      {"name": "Void Cat",        "minerals": 60},
	TileType.ORE_COPPER:      {"name": "Comet Cat",       "minerals": 40},
	TileType.ORE_COPPER_DEEP: {"name": "Meteor Cat",      "minerals": 50},
	TileType.ORE_IRON:        {"name": "Pulsar Cat",      "minerals": 65},
	TileType.ORE_GOLD:        {"name": "Supernova Cat",   "minerals": 100},
	TileType.ORE_GEM:         {"name": "Quantum Cat",     "minerals": 120},
}

# ---------------------------------------------------------------------------
# Sonar ping system (§3.2)
# ---------------------------------------------------------------------------
const SONAR_PING_DURATION: float = 3.0  # seconds until ping fades — also defined in SonarSystem

const BreakingAnimationScene: PackedScene = preload("res://assets/interaction/breaking_animation.tscn")
const PlayerProbeScene: PackedScene = preload("res://src/entities/player/PlayerProbe.tscn")

# Trader constants live in TraderSystem.gd

# Tiles that block player movement (have collision)
const SOLID_TILES: Array = [
	TileType.DIRT, TileType.DIRT_DARK,
	TileType.STONE, TileType.STONE_DARK,
	TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP,
	TileType.ORE_IRON, TileType.ORE_IRON_DEEP,
	TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP,
	TileType.ORE_GEM, TileType.ORE_GEM_DEEP,
	TileType.EXPLOSIVE, TileType.EXPLOSIVE_ARMED,
	TileType.LAVA, TileType.LAVA_FLOW,
	TileType.ENERGY_NODE, TileType.ENERGY_NODE_FULL,
	TileType.SURFACE_GRASS,
	TileType.BOSS_SEGMENT, TileType.BOSS_CORE,
	TileType.CAT_TAVERN,
]

# Tiles that fall when the block below them is removed (gravity behaviour)
const GRAVITY_TILES: Array = [TileType.STONE_DARK, TileType.DIRT_DARK, TileType.LAVA, TileType.LAVA_FLOW]

# Seconds between each row-step a gravity tile falls
const GRAVITY_FALL_DELAY: float = 0.2

# Depth zones
const DEPTH_ZONE_ROWS   = [0, 16, 41, 71, 101]
const DEPTH_ZONE_NAMES  = ["The Crust", "The Mantle", "The Outer Core", "The Inner Core", "The Primordial Forge"]
const DEPTH_ZONE_COLORS = [
	Color(0.72, 0.56, 0.36),  # The Crust - sandy brown
	Color(0.80, 0.40, 0.15),  # The Mantle - deep orange
	Color(0.90, 0.22, 0.08),  # The Outer Core - molten red
	Color(1.00, 0.70, 0.10),  # The Inner Core - golden yellow
	Color(0.70, 0.10, 0.85),  # The Primordial Forge - arcane violet
]

# Time-based energy drain: base rate (energy per second) + depth multiplier
const ENERGY_DRAIN_BASE: float = 0.5      # 0.5 energy/sec on surface (halved)
const ENERGY_DRAIN_DEPTH_MULT: float = 1.0 # Extra drain per depth ratio (halved)
var _energy_drain_accum: float = 0.0
var _energy_low_warned: bool = false

# ---------------------------------------------------------------------------
# Boss encounter system (§4) — logic lives in BossSystem.gd
# ---------------------------------------------------------------------------
const BOSS_DRAIN_MULT: float = 1.5   # energy drain multiplier while boss is alive

var grid: Array = []
var has_left_spawn: bool = false

# Camera
var camera: Camera2D
const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.0
const ZOOM_STEP := 0.1
var _camera_zoom := 1.0

# TileMapLayer for collision
var collision_tilemap: TileMapLayer
var _tileset: TileSet

# Shop + Trader systems (Node children — own all shop UI and trader NPC logic)
var shop_system: MiningShopSystem = null
var trader_system: TraderSystem = null

# Terrain generation — extracted to MiningTerrainGenerator.gd
var _terrain_generator: MiningTerrainGenerator = MiningTerrainGenerator.new()

# Boss visual rendering — extracted to BossRenderer.gd
var _boss_renderer: BossRenderer = BossRenderer.new()

# Depth tracking
var _last_depth: int = 0
var _current_zone_idx: int = -1

var _game_over: bool = false

# Per-tile damage/hit tracking for multi-hit mining
var _tile_damage: Dictionary = {}
var _tile_hits: Dictionary = {}
var _tile_last_hit: Dictionary = {}  # Maps Vector2i -> seconds since last hit; resets damage on timeout
var _flash_cells: Dictionary = {}
var _breaking_overlays: Dictionary = {}  # Maps Vector2i -> AnimatedSprite2D instance
var _healing_tiles: Dictionary = {}    # Maps Vector2i -> [start_frame: int, elapsed: float]

const MINE_RESET_TIMEOUT: float = 3.0   # Seconds of inactivity before partial tile damage resets
const HEAL_FRAME_DURATION: float = 0.12 # Seconds each frame is shown during reverse heal animation

# Gravity-tile fall queue: Vector2i(col, row) -> float seconds_until_next_step
var _gravity_pending: Dictionary = {}
# Falling stalactites: Vector2i foliage pos -> float seconds_until_next_step
var _falling_stalactites: Dictionary = {}
var _mine_streak: int = 0
var _zones_discovered: Array[bool] = [false, false, false, false, false]
var _last_banner_time_ms: int = -5000
var _exit_pulse_time: float = 0.0

# Cursor highlight
var _cursor_grid_pos: Vector2i = Vector2i(-1, -1)

# Ladder ghost preview — shown when slot 1 (ladder) is selected
var _ladder_ghost_pos: Vector2i = Vector2i(-1, -1)
var _ladder_ghost_valid: bool = false
# Tracks the last tile where a ladder placement was attempted (for continuous placement)
var _last_ladder_attempt_pos: Vector2i = Vector2i(-2, -2)

# Sonar ping subsystem (§3.2) — logic lives in SonarSystem.gd
var sonar_system: SonarSystem = SonarSystem.new()

# Consecutive smelting subsystem (§3.5) — logic lives in SmeltingSystem.gd
var smelt_system: SmeltingSystem = SmeltingSystem.new()

# Fossil forgiveness subsystem (§3.6) — logic lives in FossilSystem.gd
var fossil_system: FossilSystem = FossilSystem.new()

# Boss encounter subsystem (§4) — logic lives in BossSystem.gd
var boss_system: BossSystem = BossSystem.new()

# Mining/Collecting Cat subsystem — logic lives in CatSystem.gd (Node2D child)
var cat_system: CatSystem = null

# Run-length buffs — stored as single-element Arrays so TraderSystem can hold a writable reference
var _shroom_charges: Array = [0]          # [int]  — Mining Shroom remaining charges
var _lucky_compass_active: Array = [false] # [bool] — Lucky Compass active this run
var _ancient_map_active: Array = [false]   # [bool] — Ancient Map active this run

# Settlement whetstone bonus: temporary +N mandible power for this run only
var _settlement_mandible_bonus: int = 0

# Hazard damage cooldown to prevent instant death
var _hazard_cooldown: float = 0.0
const HAZARD_COOLDOWN_TIME: float = 1.0

# Shop protection — blocks within this radius of a shop tile cannot be mined
const SHOP_PROTECTION_RADIUS: int = 3
var _shop_protected_cells: Dictionary = {}  # Vector2i -> true

# Terrain decorations — foliage cells placed via FoliageTileMapLayer after terrain generation
var _web_sprites: Dictionary = {}  # Vector2i(col, row) -> true  (web cells for hazard detection)

# Atlas coordinates in foliage_tileset.tres (foliage_atlas.png, 64 px tiles, 10-wide grid).
const FOLIAGE_SURFACE_PLANT_ATLAS_COORDS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(6, 2), Vector2i(8, 2), Vector2i(9, 2),
	Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
	Vector2i(9, 6),
]
const FOLIAGE_CAVE_PLANT_ATLAS_COORDS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0),
	Vector2i(0, 1), Vector2i(1, 1),
	Vector2i(7, 2),
	Vector2i(0, 3), Vector2i(1, 3),
]
const FOLIAGE_STALACTITE_ATLAS_COORD: Vector2i = Vector2i(5, 2)
const FOLIAGE_WEB_ATLAS_COORD: Vector2i = Vector2i(7, 4)

@onready var player_node := $PlayerProbe as PlayerProbe
@onready var pause_menu = $PauseMenu
@onready var _mineable_layer    := $TileMapLayers/MineAbleTileMapLayer as TileMapLayer
@onready var _nonmineable_layer := $TileMapLayers/NonMineAbleTileMapLayer as TileMapLayer
@onready var _foliage_layer     := $TileMapLayers/FoliageTileMapLayer as TileMapLayer
@onready var _terrain_overlay   := $TerrainOverlay as MiningLevelOverlay

var _inventory_screen: InventoryScreen = null
var _hat_menu: HatMenu = null
var _customization_menu: CustomizationMenu = null

# Farm animal NPCs
var _farm_npcs: Array = []
const FARM_NPC_ROW: int = 2  # Placed on the middle surface row

var _pickaxe_texture: Texture2D

# Spaceship entry animation — player and workers are deposited by the ship at run start
var _spawning: bool = false
var _spaceship_sprite: Sprite2D = null

# ---------------------------------------------------------------------------
# Multiplayer co-op state
# ---------------------------------------------------------------------------
# The scene's $PlayerProbe is always the host player (authority = 1).
# guest_player_node is spawned at runtime and given the guest's peer authority.
# On the GUEST machine:  player_node = host visual,  guest_player_node = local player
# On the HOST machine:   player_node = local player, guest_player_node = guest visual
var guest_player_node: PlayerProbe = null
# How often (seconds) the host broadcasts shared resource state to the guest
const RESOURCE_SYNC_INTERVAL: float = 0.15
var _resource_sync_timer: float = 0.0
# Server-side rate limiting for guest mine requests — slightly looser than the
# client's MINE_INTERVAL (0.12 s) to absorb network jitter without being exploitable.
const GUEST_MINE_MIN_INTERVAL: float = 0.10
var _guest_mine_last_time: float = 0.0
# Column the guest spawns at (slightly right of host spawn)
const GUEST_SPAWN_COL: int = 5

# Level-wide particle system (mining sparks, tile-break bursts, lava ash, boss explosions)
var _level_particles: Array = []
const LEVEL_PARTICLE_MAX: int = 300

func _ready() -> void:
	_pickaxe_texture = load("res://assets/db32_rpg_items/pickaxe_steel.png") as Texture2D
	

	texture_filter = TEXTURE_FILTER_NEAREST

	_terrain_generator.generate(
		grid, GRID_COLS, GRID_ROWS, SURFACE_ROWS, EXIT_COLS,
		DEPTH_ZONE_ROWS,
		GameManager.allowed_ore_types,
		GameManager.allowed_hazard_types,
		GameManager.terrain_seed)
	_build_shop_protection_zones()
	_setup_collision_tilemap()
	_sync_collision_tilemap()
	_populate_visual_tilemaplayers()
	_setup_map_barriers()
	_spawn_decorations(_terrain_generator.generate_decorations())
	_terrain_overlay.setup(self)

	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = GRID_COLS * CELL_SIZE
	camera.limit_bottom = GRID_ROWS * CELL_SIZE

	# Place player at spawn (col 2, row 2 on surface)
	var spawn_col := 2
	var spawn_row := 2
	player_node.global_position = Vector2(
		spawn_col * CELL_SIZE + CELL_SIZE * 0.5,
		spawn_row * CELL_SIZE + CELL_SIZE * 0.5
	)
	player_node.mining_level = self

	EventBus.player_died.connect(_on_player_died)

	QuestManager.clear_quest()
	_setup_farm_animals()

	# Apply settlement carry-over consumables (purchased at a settlement before this run)
	if GameManager.settlement_shroom_charges > 0:
		_shroom_charges[0] += GameManager.settlement_shroom_charges
		GameManager.settlement_shroom_charges = 0
		EventBus.ore_mined_popup.emit(0, "Shroom charges ready!")
	if GameManager.settlement_mandible_bonus > 0:
		_settlement_mandible_bonus = GameManager.settlement_mandible_bonus
		GameManager.settlement_mandible_bonus = 0

	# Initialise CatSystem (Node2D child — handles its own _process and _draw)
	cat_system = CatSystem.new()
	add_child(cat_system)
	cat_system.setup(self, grid, GRID_COLS, GRID_ROWS, SURFACE_ROWS)

	# Initialise MiningShopSystem (all shop UIs + run_ore_counts / run_bar_counts)
	shop_system = MiningShopSystem.new()
	add_child(shop_system)
	shop_system.setup(player_node, cat_system)

	# Initialise TraderSystem (wandering trader NPC + shop UI)
	trader_system = TraderSystem.new()
	add_child(trader_system)
	trader_system.setup(player_node, _shroom_charges, _lucky_compass_active, _ancient_map_active)

	# Initialise BossSystem with grid reference and MiningLevel callbacks
	boss_system.setup(
		grid, GRID_COLS, GRID_ROWS, SURFACE_ROWS, CELL_SIZE,
		func(c, r, solid): _set_tile_collision(c, r, solid),
		func(text, color): _show_zone_banner(text, color),
		func(intensity, duration): _shake_camera(intensity, duration),
		func(pos): _tile_damage.erase(pos); _tile_hits.erase(pos); _tile_last_hit.erase(pos); _remove_breaking_overlay(pos),
		func(c, r): _set_visual_cell(c, r)
	)
	_boss_renderer.setup(boss_system, grid, CELL_SIZE)

	_setup_inventory_screen()
	_setup_hat_menu()
	_setup_customization_menu()

	if NetworkManager.is_multiplayer_session:
		add_child(preload("res://src/ui/ChatBox.tscn").instantiate())

	queue_redraw()

	# Co-op: spawn second player and assign authorities.
	# On the host machine, guest_peer_id may be -1 if the guest hasn't connected yet
	# (drop-in scenario). In that case, defer setup until the guest actually arrives.
	if NetworkManager.is_multiplayer_session:
		if not NetworkManager.is_host or NetworkManager.guest_peer_id > 0:
			_setup_multiplayer_players()
		else:
			# Host is in the mine but guest hasn't joined yet — wait for them.
			NetworkManager.guest_connected.connect(_on_guest_late_joined, CONNECT_ONE_SHOT)

	# Kick off the spaceship entry cinematic (hides player until ship deposits them)
	player_node.visible = false
	_spawning = true
	_play_spawn_animation.call_deferred()

# ---------------------------------------------------------------------------
# Multiplayer setup
# ---------------------------------------------------------------------------

func _setup_multiplayer_players() -> void:
	# Spawn the second player node (for whichever peer doesn't own the scene's $PlayerProbe)
	var second := PlayerProbeScene.instantiate() as PlayerProbe
	second.global_position = Vector2(
		GUEST_SPAWN_COL * CELL_SIZE + CELL_SIZE * 0.5,
		2 * CELL_SIZE + CELL_SIZE * 0.5
	)
	second.name = &"GuestPlayerProbe"
	second.mining_level = self
	add_child(second)
	guest_player_node = second

	if NetworkManager.is_host:
		# Host's player_node already defaults to authority 1.
		# Assign the second player to the guest peer so their machine drives it.
		second.set_multiplayer_authority(NetworkManager.guest_peer_id)
	else:
		# On the guest machine our peer id is assigned by the ENet server.
		var our_id := multiplayer.get_unique_id()
		second.set_multiplayer_authority(our_id)
		# The host's player_node should stay at authority 1 (it already is).

	# Add a colour tint so players can tell each other apart:
	# host = white (default), guest = orange-tinted
	if NetworkManager.is_host:
		second.sprite.modulate = Color(1.0, 0.65, 0.25)  # guest is orange
	else:
		player_node.sprite.modulate = Color(1.0, 0.65, 0.25)  # host looks orange to guest
		second.sprite.modulate = GameManager.cat_color          # guest is their own colour
		# Inform the host of our current ladder count so it can validate future placement requests.
		rpc_announce_guest_ladder_count.rpc_id(1, GameManager.ladder_count)

	# Show the host's kit bonuses to the guest as an entry banner
	if not NetworkManager.is_host:
		_show_kit_bonus_banner()

	# Connect the appropriate disconnect signal so we can show a warning mid-mine.
	# Hosts listen for the guest leaving; guests listen for the host dropping.
	if NetworkManager.is_host:
		NetworkManager.guest_disconnected.connect(_on_coop_peer_disconnected)
	else:
		NetworkManager.host_disconnected.connect(_on_coop_peer_disconnected)

## Returns the PlayerProbe that is locally authoritative (driven by this machine's input).
func _get_local_player() -> PlayerProbe:
	if not NetworkManager.is_multiplayer_session:
		return player_node
	if NetworkManager.is_host:
		return player_node
	return guest_player_node

func _show_kit_bonus_banner() -> void:
	# Display the host's upgrade kit to the guest at mine entry so they know what bonuses apply.
	var lines: Array[String] = []
	if GameManager.carapace_level > 0 or GameManager.carapace_gem_socketed:
		lines.append("Pelt Lv%d%s" % [GameManager.carapace_level, " + gem" if GameManager.carapace_gem_socketed else ""])
	if GameManager.legs_level > 0 or GameManager.legs_gem_socketed:
		lines.append("Paws Lv%d%s" % [GameManager.legs_level, " + gem" if GameManager.legs_gem_socketed else ""])
	if GameManager.mandibles_level > 0 or GameManager.mandibles_gem_socketed:
		lines.append("Claws Lv%d%s" % [GameManager.mandibles_level, " + gem" if GameManager.mandibles_gem_socketed else ""])
	if GameManager.mineral_sense_level > 0 or GameManager.sense_gem_socketed:
		lines.append("Whiskers Lv%d%s" % [GameManager.mineral_sense_level, " + gem" if GameManager.sense_gem_socketed else ""])
	if lines.is_empty():
		lines.append("No upgrades yet")
	var kit_text := "Host Kit: " + ", ".join(lines)
	EventBus.ore_mined_popup.emit(0, kit_text)

func _on_coop_peer_disconnected() -> void:
	_show_zone_banner("PARTNER DISCONNECTED", Color(1.0, 0.4, 0.2), -1)
	if guest_player_node:
		guest_player_node.queue_free()
		guest_player_node = null

## Called when a guest connects after the host's MiningLevel is already running.
## Sets up the second player node now that we have a valid guest peer ID.
func _on_guest_late_joined(_peer_id: int) -> void:
	_setup_multiplayer_players()

# ---------------------------------------------------------------------------
# Collision TileMapLayer setup
# ---------------------------------------------------------------------------

func _build_shop_protection_zones() -> void:
	const SHOP_TILES: Array = [
		TileType.EXIT_STATION,
		TileType.UPGRADE_STATION, TileType.SMELTERY_STATION,
	]
	_shop_protected_cells.clear()
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			if grid[col][row] in SHOP_TILES:
				for dc in range(-SHOP_PROTECTION_RADIUS, SHOP_PROTECTION_RADIUS + 1):
					for dr in range(-SHOP_PROTECTION_RADIUS, SHOP_PROTECTION_RADIUS + 1):
						var nc := col + dc
						var nr := row + dr
						if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
							_shop_protected_cells[Vector2i(nc, nr)] = true

# ---------------------------------------------------------------------------

func _setup_collision_tilemap() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(CELL_SIZE, CELL_SIZE)

	# Add a physics layer for solid block collision
	_tileset.add_physics_layer()
	_tileset.set_physics_layer_collision_layer(0, 1)
	_tileset.set_physics_layer_collision_mask(0, 0)

	# Create a single tile source with one tile (ID 0) that has a full-cell collision shape
	var source := TileSetAtlasSource.new()
	var placeholder_img := Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	placeholder_img.fill(Color(0, 0, 0, 0))
	var placeholder_tex := ImageTexture.create_from_image(placeholder_img)
	source.texture = placeholder_tex
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	_tileset.add_source(source, 0)
	source.create_tile(Vector2i(0, 0))

	# Add collision polygon to this tile
	source.set_tile_animation_columns(Vector2i(0, 0), 0)
	var tile_data: TileData = source.get_tile_data(Vector2i(0, 0), 0)
	var half := CELL_SIZE / 2.0
	var collision_polygon := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)
	])
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, collision_polygon)

	collision_tilemap = TileMapLayer.new()
	collision_tilemap.tile_set = _tileset
	collision_tilemap.collision_enabled = true
	collision_tilemap.visible = false  # We render tiles ourselves via _draw()
	add_child(collision_tilemap)

func _setup_map_barriers() -> void:
	# Invisible StaticBody2D walls on the left, right, and bottom edges of the
	# map so the player cannot fall or walk off.
	var map_height := GRID_ROWS * CELL_SIZE
	var map_width := GRID_COLS * CELL_SIZE
	var barrier_thickness := CELL_SIZE

	for side in ["left", "right"]:
		var barrier := StaticBody2D.new()
		barrier.collision_layer = 1
		barrier.collision_mask = 0

		var shape_node := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(barrier_thickness, map_height)
		shape_node.shape = rect

		if side == "left":
			shape_node.position = Vector2(-barrier_thickness * 0.5, map_height * 0.5)
		else:
			shape_node.position = Vector2(map_width + barrier_thickness * 0.5, map_height * 0.5)

		barrier.add_child(shape_node)
		add_child(barrier)

	# Bottom barrier
	var bottom_barrier := StaticBody2D.new()
	bottom_barrier.collision_layer = 1
	bottom_barrier.collision_mask = 0

	var bottom_shape := CollisionShape2D.new()
	var bottom_rect := RectangleShape2D.new()
	bottom_rect.size = Vector2(map_width, barrier_thickness)
	bottom_shape.shape = bottom_rect
	bottom_shape.position = Vector2(map_width * 0.5, map_height + barrier_thickness * 0.5)

	bottom_barrier.add_child(bottom_shape)
	add_child(bottom_barrier)

func _sync_collision_tilemap() -> void:
	collision_tilemap.clear()
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var tile: int = grid[col][row]
			if tile in SOLID_TILES:
				collision_tilemap.set_cell(Vector2i(col, row), 0, Vector2i(0, 0))

func _set_tile_collision(col: int, row: int, solid: bool) -> void:
	if solid:
		collision_tilemap.set_cell(Vector2i(col, row), 0, Vector2i(0, 0))
	else:
		collision_tilemap.erase_cell(Vector2i(col, row))

# ---------------------------------------------------------------------------
# Visual TileMapLayer population and per-cell sync
# ---------------------------------------------------------------------------

## Tiles placed into NonMineAbleTileMapLayer — permanent structures.
const _NONMINEABLE_VISUAL_TILES: Array = [
	TileType.REENERGY_STATION,
	TileType.UPGRADE_STATION,
	TileType.SMELTERY_STATION,
	TileType.EXIT_STATION,
	TileType.CAT_TAVERN,
]

## Tiles not rendered via TileMapLayer (handled by BossRenderer or _draw() primitives).
const _SKIP_VISUAL_TILES: Array = [
	TileType.EMPTY,
	TileType.SURFACE,
	TileType.BOSS_SEGMENT,
	TileType.BOSS_CORE,
	TileType.LADDER,
]

## Populate both visual TileMapLayers from the current grid state.
## Called once after terrain generation in _ready().
func _populate_visual_tilemaplayers() -> void:
	_mineable_layer.clear()
	_nonmineable_layer.clear()
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			_set_visual_cell(col, row)

## Update the visual TileMapLayer cell at (col, row) to match grid[col][row].
## Call this whenever grid[col][row] is written.
func _set_visual_cell(col: int, row: int) -> void:
	var gpos := Vector2i(col, row)
	_mineable_layer.erase_cell(gpos)
	_nonmineable_layer.erase_cell(gpos)
	var tile: int = grid[col][row]
	if tile in _SKIP_VISUAL_TILES:
		return
	var atlas_coord: Variant = TILE_ATLAS_COORDS.get(tile)
	if atlas_coord == null:
		return
	if tile in _NONMINEABLE_VISUAL_TILES:
		_nonmineable_layer.set_cell(gpos, 0, atlas_coord)
	else:
		_mineable_layer.set_cell(gpos, 0, atlas_coord)

# ---------------------------------------------------------------------------
# Camera follow (tracks player CharacterBody2D)
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	if not camera:
		return
	var cam_target := _get_local_player()
	if cam_target:
		camera.position = cam_target.global_position

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Draws only the background gradient and sky.
	# Tile sprites are rendered by MineAbleTileMapLayer / NonMineAbleTileMapLayer (z=0).
	# Overlays (cursor, sonar, boss, particles, etc.) are rendered by TerrainOverlay (z=1).
	var cam_x: float
	var cam_y: float
	if camera:
		cam_x = clamp(camera.position.x, VIEWPORT_W * 0.5, GRID_COLS * CELL_SIZE - VIEWPORT_W * 0.5)
		cam_y = clamp(camera.position.y, VIEWPORT_H * 0.5, GRID_ROWS * CELL_SIZE - VIEWPORT_H * 0.5)
	else:
		cam_x = VIEWPORT_W * 0.5
		cam_y = VIEWPORT_H * 0.5

	var half_w: float = float(VIEWPORT_W) * 0.5 + float(CELL_SIZE)
	var half_h: float = float(VIEWPORT_H) * 0.5 + float(CELL_SIZE)

	var min_col: int = maxi(0,             int((cam_x - half_w) / float(CELL_SIZE)))
	var max_col: int = mini(GRID_COLS - 1, int((cam_x + half_w) / float(CELL_SIZE)))
	var min_row: int = maxi(0,             int((cam_y - half_h) / float(CELL_SIZE)))
	var max_row: int = mini(GRID_ROWS - 1, int((cam_y + half_h) / float(CELL_SIZE)))

	# Background colours derived from the planet sprite's average pixel colour.
	# sky_color is sampled by MapNode.get_average_pixel_color() on mine entry.
	var sky_color: Color  = GameManager.sky_color
	var surface_bg: Color = sky_color.darkened(0.75)  # planet-hued dark for shallow underground
	var deep_bg: Color    = sky_color.darkened(0.96)  # near-black void with faint planet hue
	if min_row < SURFACE_ROWS:
		var sky_top := min_row * CELL_SIZE
		var sky_bottom := mini(SURFACE_ROWS, max_row + 1) * CELL_SIZE
		var bg_left: int = min_col * CELL_SIZE
		var bg_width: int = (max_col - min_col + 1) * CELL_SIZE
		draw_rect(Rect2(bg_left, sky_top, bg_width, sky_bottom - sky_top), sky_color)
	if max_row >= SURFACE_ROWS:
		var dirt_top := maxi(min_row, SURFACE_ROWS) * CELL_SIZE
		var dirt_bottom := (max_row + 1) * CELL_SIZE
		var bg_left: int = min_col * CELL_SIZE
		var bg_width: int = (max_col - min_col + 1) * CELL_SIZE
		# Gradient: planet-tinted dark near surface → near-black void at depth.
		# Drawn as 32 horizontal strips in world space so the gradient persists across the whole map.
		const GRAD_STRIPS: int = 32
		var total_underground_h := float((GRID_ROWS - SURFACE_ROWS) * CELL_SIZE)
		var strip_h := total_underground_h / float(GRAD_STRIPS)
		for gi in range(GRAD_STRIPS):
			var sw_top := float(SURFACE_ROWS * CELL_SIZE) + gi * strip_h
			var sw_bot := sw_top + strip_h + 1.0
			if sw_bot < float(dirt_top) or sw_top > float(dirt_bottom):
				continue
			var t := float(gi) / float(GRAD_STRIPS - 1)
			var gc := surface_bg.lerp(deep_bg, t * t)  # quadratic easing — slow at start, fast darkening deep
			draw_rect(Rect2(float(bg_left), maxf(sw_top, float(dirt_top)),
				float(bg_width), minf(sw_bot, float(dirt_bottom)) - maxf(sw_top, float(dirt_top))), gc)

	# First mineable row — paint its background with the SURFACE_GRASS colour so that
	# excavated cells show a matching backdrop, giving the row a sense of depth.
	if min_row <= SURFACE_ROWS and max_row >= SURFACE_ROWS:
		var row_y: float = float(SURFACE_ROWS * CELL_SIZE)
		draw_rect(Rect2(float(min_col * CELL_SIZE), row_y,
			float((max_col - min_col + 1) * CELL_SIZE), float(CELL_SIZE)),
			Color(0.10, 0.20, 0.35))

# Level particle system — mining sparks, ore bursts, lava embers, boss fx
# ---------------------------------------------------------------------------

func _spawn_mining_particles(world_pos: Vector2, color: Color, count: int, speed_min: float = 40.0, speed_max: float = 150.0) -> void:
	var available := LEVEL_PARTICLE_MAX - _level_particles.size()
	for _i in range(mini(count, available)):
		var angle := randf() * TAU
		var speed := randf_range(speed_min, speed_max)
		_level_particles.append({
			"pos": world_pos + Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0)),
			"vel": Vector2(cos(angle) * speed, sin(angle) * speed - speed * 0.3),
			"life": randf_range(0.18, 0.55),
			"max_life": 0.55,
			"size": randf_range(3.0, 9.0),
			"color": color,
		})

func _spawn_lava_ember(world_pos: Vector2) -> void:
	if _level_particles.size() >= LEVEL_PARTICLE_MAX:
		return
	_level_particles.append({
		"pos": world_pos + Vector2(randf_range(-10.0, 10.0), 0.0),
		"vel": Vector2(randf_range(-18.0, 18.0), randf_range(-55.0, -20.0)),
		"life": randf_range(0.5, 1.2),
		"max_life": 1.2,
		"size": randf_range(2.5, 5.5),
		"color": Color(1.0, randf_range(0.25, 0.65), 0.0),
	})

func _update_level_particles(delta: float) -> void:
	var i := _level_particles.size() - 1
	while i >= 0:
		var p: Dictionary = _level_particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			_level_particles.remove_at(i)
		else:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.82  # air drag
		i -= 1

func _emit_lava_embers(delta: float, min_col: int, max_col: int, min_row: int, max_row: int) -> void:
	# Occasionally emit rising embers from visible lava tiles for atmospheric effect.
	const LAVA_EMBER_RATE: float = 0.04   # avg seconds between embers per lava tile
	if randf() > delta / LAVA_EMBER_RATE:
		return
	# Pick a random visible lava tile
	var lava_tiles: Array = []
	for c in range(min_col, min(max_col + 1, GRID_COLS)):
		for r in range(min_row, min(max_row + 1, GRID_ROWS)):
			if grid[c][r] == TileType.LAVA or grid[c][r] == TileType.LAVA_FLOW:
				lava_tiles.append(Vector2i(c, r))
	if lava_tiles.is_empty():
		return
	var lt: Vector2i = lava_tiles[randi() % lava_tiles.size()]
	_spawn_lava_ember(Vector2(lt.x * CELL_SIZE + CELL_SIZE * 0.5, lt.y * CELL_SIZE))

# ---------------------------------------------------------------------------
# UI-blocking helper — used by PlayerProbe to pause input while any shop is open
# ---------------------------------------------------------------------------

func any_ui_open() -> bool:
	var hat_open := _hat_menu != null and _hat_menu.visible
	var custom_open := _customization_menu != null and _customization_menu.visible
	return hat_open or custom_open or (shop_system != null and (shop_system.any_shop_open() or trader_system.shop_visible))

# ---------------------------------------------------------------------------
# Process — energy drain, cursor highlight, flashes
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_exit_pulse_time += delta
	queue_redraw()
	if _terrain_overlay:
		_terrain_overlay.queue_redraw()

	# Fade impact flashes
	if _flash_cells.size() > 0:
		var to_remove: Array = []
		for pos_key in _flash_cells:
			_flash_cells[pos_key] -= delta * 5.0
			if _flash_cells[pos_key] <= 0.0:
				to_remove.append(pos_key)
		for k in to_remove:
			_flash_cells.erase(k)

	# Reset partial tile damage after MINE_RESET_TIMEOUT seconds without a hit
	if _tile_last_hit.size() > 0:
		var to_reset: Array = []
		for pos_key in _tile_last_hit:
			_tile_last_hit[pos_key] += delta
			if _tile_last_hit[pos_key] >= MINE_RESET_TIMEOUT:
				to_reset.append(pos_key)
		for pos_key in to_reset:
			_tile_damage.erase(pos_key)
			_tile_hits.erase(pos_key)
			_tile_last_hit.erase(pos_key)
			_begin_heal_animation(pos_key)

	# Advance reverse heal animations for tiles whose damage timed out
	if _healing_tiles.size() > 0:
		var to_remove_healing: Array = []
		for pos_key in _healing_tiles:
			var data: Array = _healing_tiles[pos_key]
			data[1] += delta
			var current_frame: int = data[0] - int(data[1] / HEAL_FRAME_DURATION)
			if current_frame < 0:
				to_remove_healing.append(pos_key)
			elif _breaking_overlays.has(pos_key):
				_breaking_overlays[pos_key].frame = current_frame
		for pos_key in to_remove_healing:
			_healing_tiles.erase(pos_key)
			_remove_breaking_overlay(pos_key)

	# Update level particles
	_update_level_particles(delta)
  
	# Gravity tile falling (gravel etc. drop when unsupported)
	_process_gravity(delta)
	# Stalactites fall when their ceiling tile is mined
	_process_stalactites(delta)

	# Continuous ladder placement — keep placing while left mouse is held and cursor moves
	if GameManager.selected_hotbar_slot == 1 \
			and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
			and _ladder_ghost_pos != _last_ladder_attempt_pos:
		_try_place_ladder_at(_ladder_ghost_pos)
		_last_ladder_attempt_pos = _ladder_ghost_pos

	# Update sonar ping wave (§3.2) — delegated to SonarSystem
	sonar_system.update(delta, 2.0 if _ancient_map_active[0] else 1.0)

	# Boss system update (trader_system has its own _process as a Node child)
	var _boss_pcol := floori(player_node.global_position.x / CELL_SIZE) if player_node else -1
	var _boss_prow := floori(player_node.global_position.y / CELL_SIZE) if player_node else -1
	boss_system.update(delta, _boss_pcol, _boss_prow)

	# Update on_ladder flag for all locally-authoritative players
	for p_check in [player_node, guest_player_node]:
		if p_check == null:
			continue
		if NetworkManager.is_multiplayer_session and not p_check.is_multiplayer_authority():
			continue
		var pgp: Vector2i = p_check.get_grid_pos()
		p_check.on_ladder = (
			pgp.x >= 0 and pgp.x < GRID_COLS and pgp.y >= 0 and pgp.y < GRID_ROWS
			and grid[pgp.x][pgp.y] == TileType.LADDER
		)

	# Host broadcasts shared resource state to guest periodically
	if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
		_resource_sync_timer += delta
		if _resource_sync_timer >= RESOURCE_SYNC_INTERVAL:
			_resource_sync_timer = 0.0
			rpc_sync_resources.rpc_id(NetworkManager.guest_peer_id,
				GameManager.run_mineral_currency, GameManager.current_energy)

	if _game_over or shop_system.any_shop_open() or trader_system.shop_visible:
		return

	# Update cursor highlight
	_update_cursor_highlight()

	# Update camera to follow player
	_update_camera()

	# Emit lava embers for visible lava tiles (atmospheric effect)
	if camera and not _game_over:
		var vc_x: float = clamp(camera.position.x, VIEWPORT_W * 0.5, GRID_COLS * CELL_SIZE - VIEWPORT_W * 0.5)
		var vc_y: float = clamp(camera.position.y, VIEWPORT_H * 0.5, GRID_ROWS * CELL_SIZE - VIEWPORT_H * 0.5)
		var em_col_min := maxi(0, int((vc_x - VIEWPORT_W * 0.5) / CELL_SIZE))
		var em_col_max := mini(GRID_COLS - 1, int((vc_x + VIEWPORT_W * 0.5) / CELL_SIZE))
		var em_row_min := maxi(0, int((vc_y - VIEWPORT_H * 0.5) / CELL_SIZE))
		var em_row_max := mini(GRID_ROWS - 1, int((vc_y + VIEWPORT_H * 0.5) / CELL_SIZE))
		_emit_lava_embers(delta, em_col_min, em_col_max, em_row_min, em_row_max)

	# Update depth tracking
	_update_depth()

	# Check interact prompt (reenergy station, farm NPCs)
	_update_interact_prompt()

	# Check if player reached exit zone
	_check_exit_zone()

	# Hazard cooldown
	if _hazard_cooldown > 0.0:
		_hazard_cooldown -= delta

	# Time-based energy drain — host is authoritative over the shared energy pool.
	# On guest machine the pool is kept current via rpc_sync_resources.
	if not NetworkManager.is_multiplayer_session or NetworkManager.is_host:
		var local_p := _get_local_player()
		if local_p:
			var depth_row := local_p.get_depth_row()
			if depth_row > 0 and not local_p.is_sleeping():
				var depth_ratio := float(depth_row) / float(GRID_ROWS - SURFACE_ROWS)
				var boss_mult := boss_system.get_energy_drain_mult()
				var drain_rate := (ENERGY_DRAIN_BASE + depth_ratio * ENERGY_DRAIN_DEPTH_MULT) * boss_mult
				_energy_drain_accum += drain_rate * delta
				if _energy_drain_accum >= 1.0:
					var drain_amount := int(_energy_drain_accum)
					_energy_drain_accum -= float(drain_amount)
					if not GameManager.consume_energy(drain_amount):
						_on_out_of_energy()
					else:
						var energy_pct := float(GameManager.current_energy) / float(GameManager.get_max_energy())
						if energy_pct <= 0.25 and not _energy_low_warned:
							_energy_low_warned = true
							SoundManager.play_energy_low_sound()
						elif energy_pct > 0.25:
							_energy_low_warned = false
			elif local_p.is_sleeping():
				_energy_drain_accum = 0.0

func _update_cursor_highlight() -> void:
	var local_player := _get_local_player()
	if not local_player:
		_cursor_grid_pos = Vector2i(-1, -1)
		_ladder_ghost_pos = Vector2i(-1, -1)
		_ladder_ghost_valid = false
		return
	var mouse_world := get_global_mouse_position()
	var gp := Vector2i(floori(mouse_world.x / CELL_SIZE), floori(mouse_world.y / CELL_SIZE))
	if gp.x >= 0 and gp.x < GRID_COLS and gp.y >= 0 and gp.y < GRID_ROWS:
		var player_tile := local_player.get_grid_pos()
		var dist := Vector2(gp - player_tile).length()
		if dist <= local_player.mine_range:
			_cursor_grid_pos = gp
		else:
			_cursor_grid_pos = Vector2i(-1, -1)
	else:
		_cursor_grid_pos = Vector2i(-1, -1)

	# Ladder ghost preview — only active when ladder slot (slot 1) is selected
	if GameManager.selected_hotbar_slot == 1:
		_ladder_ghost_pos = _cursor_grid_pos  # reuses the already range-checked position
		_ladder_ghost_valid = (
			_ladder_ghost_pos.x >= 0 and _ladder_ghost_pos.y >= 0
			and GameManager.ladder_count > 0
			and grid[_ladder_ghost_pos.x][_ladder_ghost_pos.y] == TileType.EMPTY
		)
	else:
		_ladder_ghost_pos = Vector2i(-1, -1)
		_ladder_ghost_valid = false

func _check_exit_zone() -> void:
	if _game_over:
		return
	# Only the host triggers run completion — guest waits for rpc_trigger_run_end
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		return
	var local_p := _get_local_player()
	if not local_p:
		return
	var player_col := floori(local_p.global_position.x / CELL_SIZE)
	var player_row := floori(local_p.global_position.y / CELL_SIZE)
	if player_col < GRID_COLS - EXIT_COLS:
		has_left_spawn = true
	if has_left_spawn and player_col >= GRID_COLS - EXIT_COLS and player_row < SURFACE_ROWS:
		_game_over = true
		if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
			rpc_trigger_run_end.rpc_id(NetworkManager.guest_peer_id)
		GameManager.complete_run()
	# Reaching the bottom of the map also counts as a completed run
	elif player_row >= GRID_ROWS - 1:
		_game_over = true
		if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
			rpc_trigger_run_end.rpc_id(NetworkManager.guest_peer_id)
		GameManager.complete_run()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _game_over:
		return
	if shop_system.any_shop_open() or trader_system.shop_visible:
		if event.is_action_pressed("ui_cancel") and shop_system.any_shop_open():
			shop_system.close_active_shop()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("toggle_inventory"):
		if _inventory_screen:
			if _inventory_screen.visible:
				_inventory_screen.close()
			else:
				_inventory_screen.open(GameManager.run_ore_chunk_counts, _shroom_charges[0],
					_lucky_compass_active[0], _ancient_map_active[0])
		return
	if event.is_action_pressed("toggle_companions_menu"):
		if _hat_menu:
			if _hat_menu.visible:
				_hat_menu.close()
			else:
				_hat_menu.open()
		return
	if event.is_action_pressed("toggle_customization_menu"):
		if _customization_menu:
			if _customization_menu.visible:
				_customization_menu.close()
			else:
				_customization_menu.open()
		return
	if event.is_action_pressed("ui_cancel"):
		pause_menu.show_menu()
		return
	if event.is_action_pressed("interact"):
		_try_interact()
		return
	if event.is_action_pressed("sonar_ping"):
		if player_node:
			sonar_system.try_ping(player_node.get_grid_pos())
	# Scroll wheel — zoom in / out
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera_zoom = clampf(_camera_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			camera.zoom = Vector2(_camera_zoom, _camera_zoom)
			get_viewport().set_input_as_handled()
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera_zoom = clampf(_camera_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			camera.zoom = Vector2(_camera_zoom, _camera_zoom)
			get_viewport().set_input_as_handled()
			return
	# Left-click — place a ladder at the cursor when the ladder slot is active
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		if GameManager.selected_hotbar_slot == 1:
			_try_place_ladder_at(_ladder_ghost_pos)
			_last_ladder_attempt_pos = _ladder_ghost_pos
			return
	# Right-click — remove a placed ladder and return it to inventory when the ladder slot is active
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_RIGHT:
		if GameManager.selected_hotbar_slot == 1:
			_try_remove_ladder_at(_ladder_ghost_pos)
			return
	# F key — also places a ladder at the cursor position (legacy binding)
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F:
		_try_place_ladder_at(_ladder_ghost_pos)

# ---------------------------------------------------------------------------
# Pickaxe throw effect — spawns a pickaxe sprite that flies to the target
# ---------------------------------------------------------------------------

func _spawn_pickaxe_effect(from: Vector2, to: Vector2) -> void:
	if not _pickaxe_texture:
		return
	var sprite := Sprite2D.new()
	sprite.texture = _pickaxe_texture
	sprite.position = from
	sprite.scale = Vector2(2.5, 2.5)
	sprite.rotation = from.angle_to_point(to) + PI * 0.25
	sprite.texture_filter = TEXTURE_FILTER_NEAREST
	add_child(sprite)
	var dist := from.distance_to(to)
	var duration := clampf(dist / 800.0, 0.06, 0.18)
	var tween := create_tween()
	tween.tween_property(sprite, "position", to, duration)
	tween.tween_callback(sprite.queue_free)

# ---------------------------------------------------------------------------
# Breaking overlay helpers
# ---------------------------------------------------------------------------

func _update_breaking_overlay(pos_key: Vector2i, damage_ratio: float) -> void:
	_healing_tiles.erase(pos_key)  # Cancel any in-progress heal animation on re-hit
	var frame_index := clampi(int(damage_ratio * 3.0), 0, 2)
	var overlay: AnimatedSprite2D
	if _breaking_overlays.has(pos_key):
		overlay = _breaking_overlays[pos_key]
	else:
		overlay = BreakingAnimationScene.instantiate()
		overlay.position = Vector2(
			pos_key.x * CELL_SIZE + CELL_SIZE * 0.5,
			pos_key.y * CELL_SIZE + CELL_SIZE * 0.5
		)
		overlay.scale = Vector2(CELL_SIZE / 10.0, CELL_SIZE / 10.0)
		add_child(overlay)
		_breaking_overlays[pos_key] = overlay
	overlay.frame = frame_index

func _remove_breaking_overlay(pos_key: Vector2i) -> void:
	_healing_tiles.erase(pos_key)
	if _breaking_overlays.has(pos_key):
		var overlay: AnimatedSprite2D = _breaking_overlays[pos_key]
		overlay.queue_free()
		_breaking_overlays.erase(pos_key)

func _begin_heal_animation(pos_key: Vector2i) -> void:
	if not _breaking_overlays.has(pos_key):
		return
	var start_frame: int = _breaking_overlays[pos_key].frame
	_healing_tiles[pos_key] = [start_frame, 0.0]

# ---------------------------------------------------------------------------
# Mining API — called by PlayerProbe
# ---------------------------------------------------------------------------

func try_mine_at(grid_pos: Vector2i, miner_node: PlayerProbe = null) -> void:
	var col := grid_pos.x
	var row := grid_pos.y
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return

	# Free-floating boss segments — check before grid tile lookup so clicks
	# register even over empty tiles where a segment is floating
	if boss_system.boss_active and not boss_system.boss_segments.is_empty():
		var click_world := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
		var hit := boss_system.try_hit_boss_segment(click_world, smelt_system.last_ore_group)
		if not hit.is_empty():
			if hit.has("blocked"):
				EventBus.ore_mined_popup.emit(0, hit.message)
				SoundManager.play_impact_sound()
				return
			var miner: PlayerProbe = miner_node if miner_node else player_node
			if miner:
				_spawn_pickaxe_effect(miner.global_position, hit.pos)
			if hit.destroyed:
				_spawn_mining_particles(hit.pos, Color(0.85, 0.15, 0.05), 20, 60.0, 200.0)
				SoundManager.play_drill_sound()
				EventBus.ore_mined_popup.emit(hit.minerals, "Boss Core!" if hit.is_core else "Boss Segment!")
				GameManager.add_currency(hit.minerals)
			else:
				_spawn_mining_particles(hit.pos, Color(0.85, 0.15, 0.05), 4, 30.0, 90.0)
				SoundManager.play_impact_sound()
				_shake_camera(1.5, 0.07)
			return

	var tile: int = grid[col][row]
	if tile == TileType.EMPTY or tile == TileType.SURFACE:
		return

	# Shop protection — blocks within SHOP_PROTECTION_RADIUS of a shop are non-mineable
	if _shop_protected_cells.has(Vector2i(col, row)):
		return

	# Pickaxe throw effect — flies from the mining player to the clicked tile.
	# miner_node overrides player_node so the guest's effect originates from the
	# guest avatar; the effect is also broadcast to the other peer so both see it.
	var miner: PlayerProbe = miner_node if miner_node else player_node
	if miner:
		var target_world := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
		_spawn_pickaxe_effect(miner.global_position, target_world)
		if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
			rpc_pickaxe_effect.rpc_id(NetworkManager.guest_peer_id, miner.global_position.x, miner.global_position.y, target_world.x, target_world.y)

	# Energy nodes — collect immediately
	if tile == TileType.ENERGY_NODE or tile == TileType.ENERGY_NODE_FULL:
		_mine_cell(col, row)
		GameManager.restore_energy(10)
		EventBus.ore_mined_popup.emit(10, "Energy")
		SoundManager.play_drill_sound()
		if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
			rpc_tile_broken.rpc_id(NetworkManager.guest_peer_id, Vector2i(col, row), 0.7, 0.9, 1.0)
		return

	# Explosives — detonate
	if tile == TileType.EXPLOSIVE or tile == TileType.EXPLOSIVE_ARMED:
		_mine_cell(col, row)
		_explode_area(col, row)
		if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
			rpc_explode_area.rpc_id(NetworkManager.guest_peer_id, Vector2i(col, row))
		return

	# Reenergy station / Exit station / Upgrade station / Smeltery / Tavern / Ladder — not mineable
	if tile in [TileType.REENERGY_STATION, TileType.EXIT_STATION, TileType.UPGRADE_STATION,
			TileType.SMELTERY_STATION, TileType.CAT_TAVERN, TileType.LADDER]:
		return

	# Stone Golem phase resistance — delegated to BossSystem
	if not boss_system.can_mine_boss_tile(tile, smelt_system.last_ore_group):
		EventBus.ore_mined_popup.emit(0,
			"Resists! Mine " + BossSystem.GOLEM_PHASE_ORES[boss_system.golem_phase].capitalize() + " ore first!")
		SoundManager.play_impact_sound()
		return

	# Normal mineable tile — multi-hit system
	var pos_key := Vector2i(col, row)
	var depth_row := row - SURFACE_ROWS
	var hardness_mult := 1.0 + (float(depth_row) / float(GRID_ROWS)) * 1.5
	var tile_hp: int = roundi(TILE_HP.get(tile, 6) * hardness_mult)
	var prev_damage: int = _tile_damage.get(pos_key, 0)
	var hits_so_far: int = _tile_hits.get(pos_key, 0)
	var new_damage: int = prev_damage + GameManager.get_mandibles_power() + _settlement_mandible_bonus
	var min_hits: int = TILE_MIN_HITS.get(tile, 2)

	if hits_so_far + 1 < min_hits and new_damage >= tile_hp:
		new_damage = tile_hp - 1
	_flash_cells[pos_key] = 1.0

	if new_damage >= tile_hp:
		_tile_damage.erase(pos_key)
		_tile_hits.erase(pos_key)
		_tile_last_hit.erase(pos_key)
		_remove_breaking_overlay(pos_key)
		_mine_cell(col, row)
		# Sync tile break to guest
		if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
			var rpc_burst := TILE_PARTICLE_COLORS.get(tile, Color(0.7, 0.6, 0.4)) as Color
			rpc_tile_broken.rpc_id(NetworkManager.guest_peer_id, pos_key, rpc_burst.r, rpc_burst.g, rpc_burst.b)
		# Boss tile tracking — delegated to BossSystem
		if tile == TileType.BOSS_SEGMENT or tile == TileType.BOSS_CORE:
			boss_system.on_tile_mined(col, row, tile)
		# Gem tile: award a gem item immediately on mining (primary value)
		if tile == TileType.ORE_GEM or tile == TileType.ORE_GEM_DEEP:
			var gems_gained := (2 if tile == TileType.ORE_GEM_DEEP else 1) + GameManager.get_gem_mine_bonus()
			GameManager.gem_count += gems_gained
			GameManager.save_game()
			EventBus.ore_mined_popup.emit(gems_gained, "Gem collected!")
		if tile in MINEABLE_TILES:
			var minerals: int = TILE_MINERALS.get(tile, 1)
			_mine_streak += 1
			var lucky_chance := LUCKY_STRIKE_CHANCE * (2.0 if _lucky_compass_active[0] else 1.0)
			var lucky := tile in ORE_TILES and randf() < lucky_chance
			if lucky:
				minerals *= 2
				SoundManager.play_lucky_strike_sound()
			# Mining Shroom buff: doubled yield on ore tiles
			if _shroom_charges[0] > 0 and tile in ORE_TILES:
				minerals *= 2
				_shroom_charges[0] -= 1
			# Fossil forgiveness check (§3.6) — before awarding base minerals
			fossil_system.check(tile, FOSSIL_TYPES.get(tile, {}))
			# Consecutive smelting bonus (§3.5) — awards extra currency internally
			smelt_system.process(SMELT_ORE_GROUPS.get(tile, ""), minerals)
			if tile in ORE_TILES:
				# Ore tiles break into physical chunks the player (or forager) must collect.
				var world_pos := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
				_spawn_ore_chunks(tile, minerals, world_pos)
				GameManager.track_ore_mined(tile, minerals)
				EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
				var popup_label: String = "LUCKY!" if lucky else TILE_NAMES.get(tile, "Mineral")
				EventBus.ore_mined_popup.emit(minerals, popup_label)
			# Non-ore tiles (dirt, stone, grass) give no minerals.
			_check_streak_milestone()
		# Particle burst on tile destruction
		var tile_world_pos := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
		var burst_color: Color = TILE_PARTICLE_COLORS.get(tile, Color(0.7, 0.6, 0.4))
		var burst_count := 14 if tile in ORE_TILES else 8
		if tile == TileType.BOSS_SEGMENT or tile == TileType.BOSS_CORE:
			burst_count = 20
		_spawn_mining_particles(tile_world_pos, burst_color, burst_count, 60.0, 200.0)
		SoundManager.play_drill_sound()
	else:
		_tile_damage[pos_key] = new_damage
		_tile_hits[pos_key] = hits_so_far + 1
		_tile_last_hit[pos_key] = 0.0
		var damage_ratio := float(new_damage) / float(tile_hp)
		_update_breaking_overlay(pos_key, damage_ratio)
		# Small impact sparks on partial hits
		var hit_world_pos := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
		_spawn_mining_particles(hit_world_pos, TILE_PARTICLE_COLORS.get(tile, Color(0.8, 0.7, 0.5)), 4, 30.0, 90.0)
		SoundManager.play_impact_sound()
		_shake_camera(1.5, 0.07)
		# Sync partial damage to guest so their breaking overlay matches
		if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
			rpc_tile_hit.rpc_id(NetworkManager.guest_peer_id, pos_key, damage_ratio)

# Called by PlayerProbe when it overlaps a hazard tile.
# source_player is the PlayerProbe that triggered the check.
func check_player_hazard(col: int, row: int, source_player: PlayerProbe = null) -> void:
	if _hazard_cooldown > 0.0 or _game_over:
		return
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return
	var tile: int = grid[col][row]
	var target_player := source_player if source_player else player_node
	if tile == TileType.LAVA or tile == TileType.LAVA_FLOW:
		target_player.take_damage(0.5)
		SoundManager.play_damage_sound()
		_shake_camera(5.0, 0.25)
		_hazard_cooldown = HAZARD_COOLDOWN_TIME
	elif tile == TileType.EXPLOSIVE or tile == TileType.EXPLOSIVE_ARMED:
		if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
			# Guest: send request to host — do not modify tile state locally.
			# Host will run the explosion and broadcast rpc_explode_area back.
			rpc_request_explode.rpc_id(1, Vector2i(col, row))
		else:
			_mine_cell(col, row)
			_explode_area(col, row)
			if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
				rpc_explode_area.rpc_id(NetworkManager.guest_peer_id, Vector2i(col, row))
		_hazard_cooldown = HAZARD_COOLDOWN_TIME

	# Spider web — slow this specific player on contact, then destroy the web
	var web_key := Vector2i(col, row)
	if _web_sprites.has(web_key):
		_web_sprites.erase(web_key)
		_foliage_layer.erase_cell(web_key)
		target_player.apply_web_slow()

# ---------------------------------------------------------------------------
# Terrain decorations — plants, coral, spider webs
# ---------------------------------------------------------------------------

func _spawn_decorations(data: Dictionary) -> void:
	_foliage_layer.clear()
	_web_sprites.clear()

	# Surface plants — placed in the sky row directly above the grass
	for pos: Vector2i in data.get("foliage_above_grass", []):
		var atlas_coord: Vector2i = FOLIAGE_SURFACE_PLANT_ATLAS_COORDS[randi() % FOLIAGE_SURFACE_PLANT_ATLAS_COORDS.size()]
		_foliage_layer.set_cell(pos, 0, atlas_coord)

	# Cave plants — grow upward from a solid floor tile
	for pos: Vector2i in data.get("coral_floor", []):
		var atlas_coord: Vector2i = FOLIAGE_CAVE_PLANT_ATLAS_COORDS[randi() % FOLIAGE_CAVE_PLANT_ATLAS_COORDS.size()]
		_foliage_layer.set_cell(pos, 0, atlas_coord)

	# Stalactites — hang from a solid ceiling tile
	for pos: Vector2i in data.get("coral_ceiling", []):
		_foliage_layer.set_cell(pos, 0, FOLIAGE_STALACTITE_ATLAS_COORD)

	# Spider webs — registered in _web_sprites for hazard detection
	for pos: Vector2i in data.get("webs", []):
		_foliage_layer.set_cell(pos, 0, FOLIAGE_WEB_ATLAS_COORD)
		_web_sprites[pos] = true

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _check_streak_milestone() -> void:
	if _mine_streak > 0 and _mine_streak % 5 == 0:
		var bonus := mini(_mine_streak, 15)
		GameManager.add_currency(bonus)
		EventBus.minerals_earned.emit(bonus)
		EventBus.ore_mined_popup.emit(bonus, "Streak!")

# ---------------------------------------------------------------------------
# Gravity block system — GRAVITY_TILES fall when unsupported
# ---------------------------------------------------------------------------

# Schedule a gravity check for any gravity tile sitting directly above (col, row).
func _trigger_gravity_above(col: int, row: int) -> void:
	var above_row := row - 1
	if above_row < 0 or col < 0 or col >= GRID_COLS:
		return
	if grid[col][above_row] in GRAVITY_TILES:
		var pos := Vector2i(col, above_row)
		# Only add if not already scheduled (avoid duplicates)
		if not _gravity_pending.has(pos):
			_gravity_pending[pos] = GRAVITY_FALL_DELAY

# Advance all pending gravity tiles by delta seconds, dropping them one row
# per step when ready.  Called every frame from _process().
func _process_gravity(delta: float) -> void:
	if _gravity_pending.is_empty():
		return

	# Snapshot keys so we can modify the dict while iterating.
	var keys: Array = _gravity_pending.keys()
	for pos in keys:
		# Tick the countdown
		_gravity_pending[pos] -= delta
		if _gravity_pending[pos] > 0.0:
			continue

		_gravity_pending.erase(pos)

		var col: int = pos.x
		var row: int = pos.y

		# Tile may have already been mined away while waiting — skip if so.
		if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
			continue
		if not grid[col][row] in GRAVITY_TILES:
			continue

		var below_row := row + 1
		if below_row >= GRID_ROWS:
			continue

		# Only fall if the cell directly below is empty.
		if grid[col][below_row] != TileType.EMPTY:
			continue

		var tile: int = grid[col][row]

		# Move the tile down one row.
		grid[col][below_row] = tile
		grid[col][row] = TileType.EMPTY
		_set_tile_collision(col, row, false)
		_set_tile_collision(col, below_row, true)
		_set_visual_cell(col, row)
		_set_visual_cell(col, below_row)

		# Clear any partial-damage state that belonged to the old position.
		_tile_damage.erase(pos)
		_tile_hits.erase(pos)
		_tile_last_hit.erase(pos)
		_remove_breaking_overlay(pos)

		# Also clear damage on the destination (a tile falling onto an already-
		# damaged cell should start fresh).
		var new_pos := Vector2i(col, below_row)
		_tile_damage.erase(new_pos)
		_tile_hits.erase(new_pos)
		_tile_last_hit.erase(new_pos)
		_remove_breaking_overlay(new_pos)

		queue_redraw()

		# Schedule the next fall step from the new position.
		_gravity_pending[new_pos] = GRAVITY_FALL_DELAY

		# If something was sitting above the old position, it may now be
		# unsupported — trigger a gravity check for it too.
		_trigger_gravity_above(col, row)

# Advance all pending falling stalactites by delta, dropping them one foliage row per step.
func _process_stalactites(delta: float) -> void:
	if _falling_stalactites.is_empty():
		return

	var keys: Array = _falling_stalactites.keys()
	for pos in keys:
		_falling_stalactites[pos] -= delta
		if _falling_stalactites[pos] > 0.0:
			continue

		_falling_stalactites.erase(pos)

		var col: int = pos.x
		var row: int = pos.y

		# Verify it is still a stalactite at this foliage position.
		if _foliage_layer.get_cell_atlas_coords(pos) != FOLIAGE_STALACTITE_ATLAS_COORD:
			continue

		# Remove from current foliage position.
		_foliage_layer.erase_cell(pos)

		var below_row := row + 1
		if below_row >= GRID_ROWS:
			continue  # Fell off the bottom of the map — it's gone.

		# If the cell below is empty in the main grid, keep falling.
		if grid[col][below_row] == TileType.EMPTY:
			var new_pos := Vector2i(col, below_row)
			_foliage_layer.set_cell(new_pos, 0, FOLIAGE_STALACTITE_ATLAS_COORD)
			_falling_stalactites[new_pos] = GRAVITY_FALL_DELAY
		# else: stalactite hit solid ground — it shatters and disappears.

func _mine_cell(col: int, row: int) -> void:
	grid[col][row] = TileType.EMPTY
	_set_tile_collision(col, row, false)
	_set_visual_cell(col, row)
	# A newly-empty cell may leave a gravity tile unsupported above it.
	_trigger_gravity_above(col, row)
	# Remove any cave plant that was resting on this tile (plant sits one row above).
	_remove_cave_plant_above(col, row)
	# Trigger any stalactite hanging below this tile to fall (stalactite hangs one row below).
	_trigger_stalactite_below(col, row)

# Cave plants grow upward from a solid floor; erase one if its support tile is removed.
func _remove_cave_plant_above(col: int, row: int) -> void:
	var above := Vector2i(col, row - 1)
	if above.y < 0:
		return
	var atlas: Vector2i = _foliage_layer.get_cell_atlas_coords(above)
	if atlas in FOLIAGE_CAVE_PLANT_ATLAS_COORDS:
		_foliage_layer.erase_cell(above)

# Stalactites hang below a solid ceiling; begin falling when their ceiling tile is mined.
func _trigger_stalactite_below(col: int, row: int) -> void:
	var below := Vector2i(col, row + 1)
	if below.y >= GRID_ROWS:
		return
	var atlas: Vector2i = _foliage_layer.get_cell_atlas_coords(below)
	if atlas == FOLIAGE_STALACTITE_ATLAS_COORD and not _falling_stalactites.has(below):
		_falling_stalactites[below] = GRAVITY_FALL_DELAY

# Spawns physical ore chunks that scatter from the mined tile position.
# In multiplayer, minerals are awarded immediately (no physical chunks to sync across peers).
func _spawn_ore_chunks(tile: int, minerals: int, world_pos: Vector2) -> void:
	if minerals <= 0:
		return
	if NetworkManager.is_multiplayer_session:
		# Host awards directly; the synced resource broadcast keeps guest HUD current.
		GameManager.add_currency(minerals)
		GameManager.track_ore_chunk_collected_by_type(tile)
		return
	# Random chunk count — more minerals create more pieces (capped to keep it tidy).
	var chunk_count: int = randi_range(3, mini(6, minerals))
	# Distribute minerals across chunks, spreading any remainder across the first ones.
	var base_value: int = minerals / chunk_count
	var leftover: int = minerals - base_value * chunk_count
	for i in range(chunk_count):
		var chunk := OreChunk.new()
		chunk.ore_type = tile
		chunk.value = base_value + (1 if i < leftover else 0)
		# Scatter outward with a slight upward bias so chunks visibly pop out.
		var angle: float = randf() * TAU
		var speed: float = randf_range(60.0, 170.0)
		chunk.velocity = Vector2(cos(angle) * speed, sin(angle) * speed - 90.0)
		chunk.global_position = world_pos
		add_child(chunk)

func _explode_area(center_col: int, center_row: int) -> void:
	var r := 1
	for dc in range(-r, r + 1):
		for dr in range(-r, r + 1):
			var nc := center_col + dc
			var nr := center_row + dr
			if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
				var tile: int = grid[nc][nr]
				if tile in ORE_TILES:
					var minerals: int = TILE_MINERALS.get(tile, 1)
					var world_pos := Vector2(nc * CELL_SIZE + CELL_SIZE * 0.5, nr * CELL_SIZE + CELL_SIZE * 0.5)
					_spawn_ore_chunks(tile, minerals, world_pos)
					GameManager.track_ore_mined(tile, minerals)
				grid[nc][nr] = TileType.EMPTY
				_set_tile_collision(nc, nr, false)
				_set_visual_cell(nc, nr)
				_remove_breaking_overlay(Vector2i(nc, nr))
				# Explosion may leave gravity tiles unsupported above cleared cells.
				_trigger_gravity_above(nc, nr)
				_remove_cave_plant_above(nc, nr)
				_trigger_stalactite_below(nc, nr)
				# Particle burst at each cell so the explosion fills the full 3x3 area
				var cell_world := Vector2(nc * CELL_SIZE + CELL_SIZE * 0.5, nr * CELL_SIZE + CELL_SIZE * 0.5)
				_spawn_mining_particles(cell_world, Color(1.0, 0.55, 0.05), 4, 80.0, 280.0)
				_spawn_mining_particles(cell_world, Color(1.0, 0.90, 0.20, 0.8), 2, 50.0, 180.0)
	SoundManager.play_explosion_sound()
	_shake_camera(12.0, 0.55)
	if player_node:
		var player_col := int(player_node.global_position.x / CELL_SIZE)
		var player_row := int(player_node.global_position.y / CELL_SIZE)
		if abs(player_col - center_col) <= r and abs(player_row - center_row) <= r:
			_damage_player(1)
	# In multiplayer check if the guest is also caught in the blast radius
	if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0 and guest_player_node:
		var gcol := int(guest_player_node.global_position.x / CELL_SIZE)
		var grow := int(guest_player_node.global_position.y / CELL_SIZE)
		if abs(gcol - center_col) <= r and abs(grow - center_row) <= r:
			rpc_damage_guest.rpc_id(NetworkManager.guest_peer_id, 1)

func _damage_player(amount: float) -> void:
	if player_node and player_node.has_method("take_damage"):
		player_node.take_damage(amount)
		SoundManager.play_damage_sound()
		_shake_camera(5.0, 0.25)

func _on_player_died() -> void:
	if _game_over:
		return
	if NetworkManager.is_multiplayer_session:
		# Co-op death = ghost mode, not game over.  The run continues until energy runs out.
		var local_p := _get_local_player()
		if local_p:
			local_p.visible = false
		_show_zone_banner("YOU DIED — SPECTATING", Color(1.0, 0.25, 0.25), -1)
		# Notify the remote peer so they hide this player's sprite too
		if NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
			rpc_ghost_mode.rpc_id(NetworkManager.guest_peer_id, true)
		elif not NetworkManager.is_host:
			rpc_ghost_mode.rpc_id(1, false)
		return
	_game_over = true
	SoundManager.play_death_sound()
	_show_game_over_overlay("LOST IN SPACE", "Run stardust has been lost...")
	await get_tree().create_timer(2.5).timeout
	GameManager.lose_run()

func _on_out_of_energy() -> void:
	if _game_over:
		return
	# Only host triggers game over; guest waits for rpc_trigger_game_over
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		return
	_game_over = true
	_show_game_over_overlay("OUT OF ENERGY", "Run stardust has been lost...")
	if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
		rpc_trigger_game_over.rpc_id(NetworkManager.guest_peer_id)
	await get_tree().create_timer(2.5).timeout
	GameManager.lose_run()

func _show_game_over_overlay(title: String, subtitle: String) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VIEWPORT_W, VIEWPORT_H)
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	var title_label := Label.new()
	title_label.text = title
	title_label.position = Vector2(0, VIEWPORT_H / 2 - 48)
	title_label.size = Vector2(VIEWPORT_W, 52)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.modulate = Color(1.0, 0.15, 0.05)
	layer.add_child(title_label)
	var sub_label := Label.new()
	sub_label.text = subtitle
	sub_label.position = Vector2(0, VIEWPORT_H / 2 + 12)
	sub_label.size = Vector2(VIEWPORT_W, 28)
	sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_label.modulate = Color(0.85, 0.85, 0.85)
	layer.add_child(sub_label)
	var tween := create_tween()
	tween.tween_property(dim, "color:a", 0.80, 0.6)

func _shake_camera(intensity: float = 5.0, duration: float = 0.3) -> void:
	if not camera:
		return
	var tween := create_tween()
	var steps := 8
	var step_dur := duration / steps
	for i in range(steps):
		var t := float(i) / float(steps)
		var cur_intensity := intensity * (1.0 - t)
		var offset := Vector2(
			randf_range(-cur_intensity, cur_intensity),
			randf_range(-cur_intensity, cur_intensity)
		)
		tween.tween_property(camera, "offset", offset, step_dur)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

# ---------------------------------------------------------------------------
# Spaceship entry animation
# ---------------------------------------------------------------------------

func _play_spawn_animation() -> void:
	var spaceship_tex := load("res://assets/spaceship.png") as Texture2D
	var spawn_px := Vector2(2 * CELL_SIZE + CELL_SIZE * 0.5, 2 * CELL_SIZE + CELL_SIZE * 0.5)

	if spaceship_tex:
		_spaceship_sprite = Sprite2D.new()
		_spaceship_sprite.texture = spaceship_tex
		_spaceship_sprite.texture_filter = TEXTURE_FILTER_NEAREST
		_spaceship_sprite.scale = Vector2(2.0, 2.0)
		_spaceship_sprite.z_index = 10
		# Start high above the spawn point, just off-screen
		_spaceship_sprite.position = spawn_px + Vector2(0.0, -900.0)
		add_child(_spaceship_sprite)

		# Swoop down to hover above the spawn tile
		var hover_pos := spawn_px + Vector2(0.0, -float(CELL_SIZE) * 2.0)
		var in_tween := create_tween()
		in_tween.tween_property(_spaceship_sprite, "position", hover_pos, 1.1) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await in_tween.finished

	# Brief hover — ship "deposits" the player and any hired cats
	await get_tree().create_timer(0.55).timeout

	# Reveal player at spawn position
	if player_node:
		player_node.global_position = spawn_px
		player_node.visible = true

	# Tiny camera shake as players hits the surface
	_shake_camera(4.0, 0.25)

	if spaceship_tex and _spaceship_sprite:
		# Fly back up and disappear
		var out_tween := create_tween()
		out_tween.tween_property(_spaceship_sprite, "position", spawn_px + Vector2(60.0, -1000.0), 0.9) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await out_tween.finished
		_spaceship_sprite.queue_free()
		_spaceship_sprite = null

	_spawning = false

# ---------------------------------------------------------------------------
# Sonar ping (§3.2) — delegated to SonarSystem
# ---------------------------------------------------------------------------
# sonar_system.try_ping(player_grid_pos) is called from _unhandled_input().
# sonar_system.update(delta, mult) is called from _process().
# See src/systems/SonarSystem.gd.

# ---------------------------------------------------------------------------
# Consecutive smelting (§3.5) — delegated to SmeltingSystem
# ---------------------------------------------------------------------------
# smelt_system.process(SMELT_ORE_GROUPS.get(tile, ""), minerals) is called
# directly at the mine site in try_mine_at().  See src/systems/SmeltingSystem.gd.

# ---------------------------------------------------------------------------
# Fossil forgiveness (§3.6) — delegated to FossilSystem
# ---------------------------------------------------------------------------
# fossil_system.check(tile, FOSSIL_TYPES.get(tile, {})) is called directly at
# the mine site in try_mine_at().  See src/systems/FossilSystem.gd.

# ---------------------------------------------------------------------------
# Depth tracking
# ---------------------------------------------------------------------------

func _update_depth() -> void:
	var local_p := _get_local_player()
	if not local_p:
		return
	var depth: int = local_p.get_depth_row()
	if depth != _last_depth:
		_last_depth = depth
		EventBus.depth_changed.emit(depth)
		_check_zone_transition(depth)
		trader_system.check_milestone(depth)
		boss_system.check_milestone(depth, player_node.get_grid_pos().x)
		var _boss_hints := boss_system.get_pending_hints()
		if not _boss_hints.is_empty():
			_queue_boss_hints(_boss_hints)
		# Track deepest row for Colony Chamber unlock condition
		if depth > GameManager.deepest_row_reached:
			GameManager.deepest_row_reached = depth
		# Reset mine streak when surfacing
		if depth <= 0:
			_mine_streak = 0

func _check_zone_transition(depth_row: int) -> void:
	var new_zone_idx := 0
	for i in range(DEPTH_ZONE_ROWS.size() - 1, -1, -1):
		if depth_row >= DEPTH_ZONE_ROWS[i]:
			new_zone_idx = i
			break
	if new_zone_idx != _current_zone_idx:
		_current_zone_idx = new_zone_idx
		if depth_row > 0:
			_show_zone_banner(DEPTH_ZONE_NAMES[new_zone_idx], DEPTH_ZONE_COLORS[new_zone_idx], depth_row)
			SoundManager.play_depth_milestone_sound()
			if new_zone_idx > 0 and not _zones_discovered[new_zone_idx]:
				_zones_discovered[new_zone_idx] = true
				const DISCOVERY_ENERGY := 20
				GameManager.restore_energy(DISCOVERY_ENERGY)
				EventBus.ore_mined_popup.emit(DISCOVERY_ENERGY, "Discovery!")

func _show_zone_banner(zone_name: String, color: Color, depth_row: int = -1) -> void:
	const COOLDOWN_MS: int = 5000
	var now_ms := Time.get_ticks_msec()
	if now_ms - _last_banner_time_ms < COOLDOWN_MS:
		return
	_last_banner_time_ms = now_ms
	const VW: int = 1280
	const VH: int = 720
	var banner_h: int = 68 if depth_row >= 0 else 52
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var banner := ColorRect.new()
	banner.size = Vector2(VW, banner_h)
	banner.position = Vector2(0, VH * 2 / 3 - banner_h / 2)
	banner.color = Color(0.0, 0.0, 0.0, 0.78)
	layer.add_child(banner)
	var label := Label.new()
	label.text = zone_name.to_upper()
	var name_h: int = 42 if depth_row >= 0 else banner_h
	label.size = Vector2(VW, name_h)
	label.position = Vector2(0, VH * 2 / 3 - banner_h / 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.modulate = color
	layer.add_child(label)
	if depth_row >= 0:
		var depth_label := Label.new()
		depth_label.text = "Depth: %d m" % (depth_row * 10)
		depth_label.size = Vector2(VW, 26)
		depth_label.position = Vector2(0, VH * 2 / 3 - banner_h / 2 + 42)
		depth_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		depth_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		depth_label.add_theme_font_size_override("font_size", 14)
		depth_label.modulate = Color(color.r, color.g, color.b, 0.75)
		layer.add_child(depth_label)
	var tween := create_tween()
	tween.tween_interval(1.6)
	tween.tween_property(layer, "modulate:a", 0.0, 0.7)
	tween.tween_callback(layer.queue_free)

# ---------------------------------------------------------------------------
# Interact prompt
# ---------------------------------------------------------------------------

func _get_interact_key_name() -> String:
	var events := InputMap.action_get_events("interact")
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
	return "E"

func _update_interact_prompt() -> void:
	var local_p := _get_local_player()
	if not local_p:
		return
	# Reuse player_node reference for prompt display helpers (always host's node for prompt UI)
	var key := _get_interact_key_name()
	var adj := [Vector2i(0,0), Vector2i(-1,0), Vector2i(1,0), Vector2i(0,-1), Vector2i(0,1)]
	# Station prompts
	const STATION_PROMPTS: Dictionary = {
		TileType.REENERGY_STATION: "Press %s to open shop",
		TileType.UPGRADE_STATION:  "Press %s to upgrade",
		TileType.SMELTERY_STATION: "Press %s to open smeltery",
		TileType.CAT_TAVERN:       "Press %s to enter Cat Tavern",
	}
	for offset in adj:
		var check: Vector2i = local_p.get_grid_pos() + offset
		if check.x < 0 or check.x >= GRID_COLS or check.y < 0 or check.y >= GRID_ROWS:
			continue
		var t: int = grid[check.x][check.y]
		if t in STATION_PROMPTS:
			local_p.show_prompt(STATION_PROMPTS[t] % key)
			var world_pos := Vector2(check.x * CELL_SIZE + CELL_SIZE * 0.5, check.y * CELL_SIZE)
			local_p.set_prompt_position(get_viewport().get_canvas_transform() * world_pos)
			return
	# Trader prompt
	var nearby_trader := trader_system.get_nearby_trader()
	if nearby_trader.size() > 0:
		local_p.show_prompt("Press %s to trade" % key)
		local_p.set_prompt_position(
			get_viewport().get_canvas_transform() * (nearby_trader["world_pos"] as Vector2)
			+ Vector2(0, -CELL_SIZE))
		return
	# Farm NPC prompt
	var nearby_npc: FarmAnimalNPC = _get_nearby_farm_npc()
	if nearby_npc:
		local_p.show_prompt("Press %s to pet the %s" % [key, nearby_npc.animal_name])
		local_p.set_prompt_position(
			get_viewport().get_canvas_transform() * (local_p.global_position + Vector2(0, -CELL_SIZE)))
	else:
		local_p.hide_prompt()

func _get_nearby_farm_npc() -> FarmAnimalNPC:
	var local_p := _get_local_player()
	if not local_p:
		return null
	var player_gp := local_p.get_grid_pos()
	if player_gp.y >= SURFACE_ROWS:
		return null
	var player_pos := local_p.global_position
	for npc in _farm_npcs:
		if npc.global_position.distance_to(player_pos) <= CELL_SIZE * 2:
			return npc
	return null

func _try_interact() -> void:
	var local_p := _get_local_player()
	if not local_p:
		return
	# In multiplayer only the host can use stations (resource spending is host-authoritative)
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		EventBus.ore_mined_popup.emit(0, "Only the host can interact with stations.")
		return
	var nearby_trader := trader_system.get_nearby_trader()
	if nearby_trader.size() > 0:
		trader_system.show_shop(nearby_trader)
		return
	const STATION_SHOPS: Dictionary = {
		TileType.REENERGY_STATION: "show_energy_shop",
		TileType.UPGRADE_STATION:  "show_upgrade_station",
		TileType.SMELTERY_STATION: "show_smeltery",
		TileType.CAT_TAVERN:       "show_cat_tavern",
	}
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = local_p.get_grid_pos() + offset
		if check.x < 0 or check.x >= GRID_COLS or check.y < 0 or check.y >= GRID_ROWS:
			continue
		var t: int = grid[check.x][check.y]
		if t in STATION_SHOPS:
			shop_system.call(STATION_SHOPS[t])
			return
	var nearby_npc: FarmAnimalNPC = _get_nearby_farm_npc()
	if nearby_npc:
		nearby_npc.wiggle()
		EventBus.ore_mined_popup.emit(0, nearby_npc.get_pet_message())

# ---------------------------------------------------------------------------
# Farm animals
# ---------------------------------------------------------------------------

func _setup_farm_animals() -> void:
	var npc_scene := load("res://src/entities/npcs/FarmAnimalNPC.tscn") as PackedScene
	if not npc_scene:
		return
	var all_animal_types := [
		{"name": "Chicken", "texture_path": "res://assets/creatures/chicken_spritesheet.png"},
		{"name": "Sheep",   "texture_path": "res://assets/creatures/sheep_spritesheet.png"},
		{"name": "Pig",     "texture_path": "res://assets/creatures/pig_spritesheet.png"},
	]
	# In multiplayer the host picks the animal type in GameManager.load_mining_level()
	# and syncs it to the guest via RPC before the scene loads.  Both peers then use
	# GameManager.planet_animal_type so they see the same animals on the planet surface.
	# In single-player the type is chosen randomly here as before.
	var chosen: Dictionary
	if NetworkManager.is_multiplayer_session and GameManager.planet_animal_type != "":
		chosen = all_animal_types[0]  # fallback
		for t in all_animal_types:
			if t["name"] == GameManager.planet_animal_type:
				chosen = t
				break
	else:
		chosen = all_animal_types[randi() % all_animal_types.size()]
	var tex := load(chosen["texture_path"]) as Texture2D
	# Randomise count between 2 and 5 NPCs
	var count := randi_range(2, 5)
	var bounce_left := 1.0 * CELL_SIZE
	var bounce_right := 20.0 * CELL_SIZE
	# Build a pool of valid surface columns and shuffle them for unique spread
	var col_pool: Array[int] = []
	for c in range(2, 94):
		col_pool.append(c)
	col_pool.shuffle()
	for i in count:
		var npc := npc_scene.instantiate() as FarmAnimalNPC
		npc.animal_name = chosen["name"]
		if tex:
			var spr := npc.get_node("Sprite2D") as Sprite2D
			spr.texture = tex
			spr.hframes = 2
			spr.frame = 0
		npc.scale = Vector2(4.0, 4.0)
		npc.position = Vector2(
			col_pool[i] * CELL_SIZE + CELL_SIZE,
			FARM_NPC_ROW * CELL_SIZE + CELL_SIZE - 16
		)
		npc.bounce_left = bounce_left
		npc.bounce_right = bounce_right
		var speed := randf_range(40.0, 80.0)
		npc.velocity = Vector2(speed * (1.0 if randf() > 0.5 else -1.0), 0.0)
		add_child(npc)
		_farm_npcs.append(npc)

# ---------------------------------------------------------------------------
# Inventory Screen
# ---------------------------------------------------------------------------

func _setup_inventory_screen() -> void:
	var inv_scene := load("res://src/ui/InventoryScreen.tscn") as PackedScene
	if inv_scene:
		_inventory_screen = inv_scene.instantiate() as InventoryScreen
		_inventory_screen.mining_level = self
		add_child(_inventory_screen)

func _setup_hat_menu() -> void:
	_hat_menu = HatMenu.new()
	_hat_menu.player = player_node
	add_child(_hat_menu)

func _setup_customization_menu() -> void:
	_customization_menu = CustomizationMenu.new()
	_customization_menu.player = player_node
	add_child(_customization_menu)

# Shops (Surface Hub, Energy Dock, Upgrade Bay, Space Forge, Cat Tavern)
# are now managed by MiningShopSystem — see src/levels/MiningShopSystem.gd


# ---------------------------------------------------------------------------
# Boss encounter system (§4) — delegated to BossSystem
# ---------------------------------------------------------------------------
# boss_system.check_milestone(depth, player_col) is called from _update_depth().
# boss_system.update(delta, player_col, player_row) is called from _process().
# boss_system.can_mine_boss_tile(tile, last_ore) and
# boss_system.on_tile_mined(col, row, tile) are called from try_mine_at().
# Hint queuing (uses await) lives here; BossSystem exposes get_pending_hints().
# See src/systems/BossSystem.gd.

## Shows a sequence of hint popups with a delay between each.
func _queue_boss_hints(hints: Array) -> void:
	for hint in hints:
		await get_tree().create_timer(2.0).timeout
		EventBus.boss_hint_popup.emit(hint)


# ---------------------------------------------------------------------------
# Cat system helpers
# ---------------------------------------------------------------------------

## Called by CatSystem's mining cats — lightweight mine that skips UI/streak logic.
func cat_mine_at(grid_pos: Vector2i) -> void:
	var col := grid_pos.x
	var row := grid_pos.y
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return
	if _shop_protected_cells.has(Vector2i(col, row)):
		return
	var tile: int = grid[col][row]
	if tile not in ORE_TILES:
		return
	var minerals: int = TILE_MINERALS.get(tile, 1)
	_mine_cell(col, row)
	var world_pos := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
	_spawn_ore_chunks(tile, minerals, world_pos)
	GameManager.track_ore_mined(tile, minerals)
	queue_redraw()

# ---------------------------------------------------------------------------
# Ladder placement
# ---------------------------------------------------------------------------

func _try_place_ladder_at(gp: Vector2i) -> void:
	if GameManager.selected_hotbar_slot != 1:
		EventBus.ore_mined_popup.emit(0, "Select the ladder (slot 2) to place ladders.")
		return
	# Guest in multiplayer: send request to host for authoritative placement
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		_guest_request_place_ladder(gp)
		return
	# Host / single-player path
	if not player_node:
		return
	if GameManager.ladder_count <= 0:
		EventBus.ore_mined_popup.emit(0, "No ladders! Buy packs at the Recharging Station.")
		return
	if gp.x < 0 or gp.x >= GRID_COLS or gp.y < 0 or gp.y >= GRID_ROWS:
		EventBus.ore_mined_popup.emit(0, "Aim the cursor at an empty tile to place a ladder.")
		return
	var player_tile := player_node.get_grid_pos()
	var dist := Vector2(gp - player_tile).length()
	if dist > player_node.mine_range:
		EventBus.ore_mined_popup.emit(0, "Too far — move closer to place a ladder there.")
		return
	if grid[gp.x][gp.y] != TileType.EMPTY:
		EventBus.ore_mined_popup.emit(0, "Can only place ladders in open space.")
		return
	grid[gp.x][gp.y] = TileType.LADDER
	_set_visual_cell(gp.x, gp.y)
	GameManager.ladder_count -= 1
	GameManager.save_game()
	EventBus.ladder_count_changed.emit(GameManager.ladder_count)
	EventBus.ore_mined_popup.emit(0, "Ladder placed!  (%d remaining)" % GameManager.ladder_count)
	queue_redraw()
	if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
		rpc_ladder_placed.rpc_id(NetworkManager.guest_peer_id, gp)

## Guest-side helper: validates inputs locally for fast feedback then forwards the
## placement request to the host, which is authoritative over the shared grid.
func _guest_request_place_ladder(gp: Vector2i) -> void:
	var local_player := _get_local_player()
	if not local_player:
		return
	if GameManager.ladder_count <= 0:
		EventBus.ore_mined_popup.emit(0, "No ladders! Buy packs at the Recharging Station.")
		return
	if gp.x < 0 or gp.x >= GRID_COLS or gp.y < 0 or gp.y >= GRID_ROWS:
		EventBus.ore_mined_popup.emit(0, "Aim the cursor at an empty tile to place a ladder.")
		return
	var player_tile := local_player.get_grid_pos()
	if Vector2(gp - player_tile).length() > local_player.mine_range:
		EventBus.ore_mined_popup.emit(0, "Too far — move closer to place a ladder there.")
		return
	if grid[gp.x][gp.y] != TileType.EMPTY:
		EventBus.ore_mined_popup.emit(0, "Can only place ladders in open space.")
		return
	rpc_request_place_ladder.rpc_id(1, gp)

# ---------------------------------------------------------------------------
# Ladder removal — right-click a placed ladder while holding the ladder slot
# ---------------------------------------------------------------------------

func _try_remove_ladder_at(gp: Vector2i) -> void:
	if GameManager.selected_hotbar_slot != 1:
		return
	# Guest in multiplayer: send request to host for authoritative removal
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		_guest_request_remove_ladder(gp)
		return
	# Host / single-player path
	if not player_node:
		return
	if gp.x < 0 or gp.x >= GRID_COLS or gp.y < 0 or gp.y >= GRID_ROWS:
		return
	if grid[gp.x][gp.y] != TileType.LADDER:
		EventBus.ore_mined_popup.emit(0, "Right-click a placed ladder to retrieve it.")
		return
	var player_tile := player_node.get_grid_pos()
	var dist := Vector2(gp - player_tile).length()
	if dist > player_node.mine_range:
		EventBus.ore_mined_popup.emit(0, "Too far — move closer to retrieve that ladder.")
		return
	grid[gp.x][gp.y] = TileType.EMPTY
	_set_visual_cell(gp.x, gp.y)
	GameManager.ladder_count += 1
	GameManager.save_game()
	EventBus.ladder_count_changed.emit(GameManager.ladder_count)
	EventBus.ore_mined_popup.emit(0, "Ladder retrieved!  (%d in stock)" % GameManager.ladder_count)
	queue_redraw()
	if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
		rpc_ladder_removed.rpc_id(NetworkManager.guest_peer_id, gp)

## Guest-side helper: validates inputs locally for fast feedback then forwards the
## removal request to the host, which is authoritative over the shared grid.
func _guest_request_remove_ladder(gp: Vector2i) -> void:
	var local_player := _get_local_player()
	if not local_player:
		return
	if gp.x < 0 or gp.x >= GRID_COLS or gp.y < 0 or gp.y >= GRID_ROWS:
		return
	if grid[gp.x][gp.y] != TileType.LADDER:
		EventBus.ore_mined_popup.emit(0, "Right-click a placed ladder to retrieve it.")
		return
	var player_tile := local_player.get_grid_pos()
	if Vector2(gp - player_tile).length() > local_player.mine_range:
		EventBus.ore_mined_popup.emit(0, "Too far — move closer to retrieve that ladder.")
		return
	rpc_request_remove_ladder.rpc_id(1, gp)

# ---------------------------------------------------------------------------
# Multiplayer RPCs
# ---------------------------------------------------------------------------

## Guest → Host: request a tile mine at grid_pos.
## Host validates range using the synced guest position and enforces a minimum
## interval to prevent the guest from bypassing the client-side MINE_INTERVAL.
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_mine(grid_pos: Vector2i) -> void:
	if not NetworkManager.is_host:
		return
	# Rate limit: reject requests that arrive faster than GUEST_MINE_MIN_INTERVAL
	var now := Time.get_ticks_msec() / 1000.0
	if now - _guest_mine_last_time < GUEST_MINE_MIN_INTERVAL:
		return
	_guest_mine_last_time = now
	# Validate that the guest's current (synced) position is within range
	if guest_player_node:
		var player_tile := Vector2i(
			floori(guest_player_node.global_position.x / CELL_SIZE),
			floori(guest_player_node.global_position.y / CELL_SIZE)
		)
		var dist := Vector2(grid_pos - player_tile).length()
		if dist > guest_player_node.mine_range:
			return
	# Pass guest_player_node so the pickaxe effect originates from the guest avatar
	try_mine_at(grid_pos, guest_player_node)

## Host → Guest: a tile was fully destroyed — update grid and play break visuals.
@rpc("authority", "call_remote", "reliable")
func rpc_tile_broken(grid_pos: Vector2i, burst_r: float, burst_g: float, burst_b: float) -> void:
	var col := grid_pos.x
	var row := grid_pos.y
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return
	_remove_breaking_overlay(grid_pos)
	_mine_cell(col, row)
	var burst_color := Color(burst_r, burst_g, burst_b)
	var world_pos := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
	_spawn_mining_particles(world_pos, burst_color, 8, 60.0, 200.0)
	SoundManager.play_drill_sound()
	queue_redraw()

## Host → Guest: partial hit on a tile — sync the breaking overlay.
@rpc("authority", "call_remote", "reliable")
func rpc_tile_hit(grid_pos: Vector2i, damage_ratio: float) -> void:
	if grid_pos.x < 0 or grid_pos.x >= GRID_COLS or grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
		return
	_update_breaking_overlay(grid_pos, damage_ratio)
	_flash_cells[grid_pos] = 1.0
	SoundManager.play_impact_sound()

## Host → Guest: spawn the pickaxe throw visual on the guest's screen.
## Sent for both host-initiated and guest-initiated mines so both players see
## the effect originating from the correct avatar. Uses unreliable delivery
## since a missed cosmetic packet is acceptable.
@rpc("authority", "call_remote", "unreliable")
func rpc_pickaxe_effect(from_x: float, from_y: float, to_x: float, to_y: float) -> void:
	_spawn_pickaxe_effect(Vector2(from_x, from_y), Vector2(to_x, to_y))

## Host → Guest: sync shared run resources so the guest HUD stays accurate.
## unreliable_ordered ensures later packets supersede earlier ones; stale data
## is discarded rather than overwriting a more recent update.
@rpc("authority", "call_remote", "unreliable_ordered")
func rpc_sync_resources(minerals: int, energy: int) -> void:
	GameManager.run_mineral_currency = minerals
	GameManager.current_energy = energy
	EventBus.minerals_changed.emit(minerals)
	EventBus.energy_changed.emit(energy, GameManager.get_max_energy())

## Host → Guest: the run has ended successfully (exit station reached).
@rpc("authority", "call_remote", "reliable")
func rpc_trigger_run_end() -> void:
	if not _game_over:
		_game_over = true
		GameManager.complete_run()

## Host → Guest: the run failed (energy ran out / host died).
@rpc("authority", "call_remote", "reliable")
func rpc_trigger_game_over() -> void:
	if not _game_over:
		_game_over = true
		_show_game_over_overlay("OUT OF ENERGY", "Run stardust has been lost...")
		await get_tree().create_timer(2.5).timeout
		GameManager.lose_run()

## Host → Guest: deal damage to the guest player (hazard or explosion).
@rpc("authority", "call_remote", "reliable")
func rpc_damage_guest(amount: float) -> void:
	# On the guest machine, guest_player_node is the local player
	var local_p := _get_local_player()
	if local_p:
		local_p.take_damage(amount)
		SoundManager.play_damage_sound()
		_shake_camera(5.0, 0.25)

## Guest → Host: consume energy from the shared pool on behalf of the guest.
## Used for sprint energy drain so the cost is deducted from the authoritative
## pool rather than the guest's local (overwritten) copy.
@rpc("any_peer", "call_remote", "reliable")
func rpc_consume_energy_from_guest(amount: int) -> void:
	if not NetworkManager.is_host:
		return
	GameManager.consume_energy(amount)

## Host → Guest: a ladder was placed — update grid so guest can climb it.
@rpc("authority", "call_remote", "reliable")
func rpc_ladder_placed(grid_pos: Vector2i) -> void:
	if grid_pos.x < 0 or grid_pos.x >= GRID_COLS or grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
		return
	grid[grid_pos.x][grid_pos.y] = TileType.LADDER
	_set_visual_cell(grid_pos.x, grid_pos.y)
	queue_redraw()

## Host → Guest: a ladder was retrieved — clear it from the guest's grid.
@rpc("authority", "call_remote", "reliable")
func rpc_ladder_removed(grid_pos: Vector2i) -> void:
	if grid_pos.x < 0 or grid_pos.x >= GRID_COLS or grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
		return
	grid[grid_pos.x][grid_pos.y] = TileType.EMPTY
	_set_tile_collision(grid_pos.x, grid_pos.y, false)
	_set_visual_cell(grid_pos.x, grid_pos.y)
	queue_redraw()

## Guest → Host: request placing a ladder at grid_pos.
## Host validates range from the synced guest position, inventory, and tile state.
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_place_ladder(grid_pos: Vector2i) -> void:
	if not NetworkManager.is_host:
		return
	if not guest_player_node:
		return
	if grid_pos.x < 0 or grid_pos.x >= GRID_COLS or grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
		return
	var guest_tile := Vector2i(
		floori(guest_player_node.global_position.x / CELL_SIZE),
		floori(guest_player_node.global_position.y / CELL_SIZE)
	)
	if Vector2(grid_pos - guest_tile).length() > guest_player_node.mine_range:
		return
	if GameManager.guest_ladder_count <= 0:
		return
	if grid[grid_pos.x][grid_pos.y] != TileType.EMPTY:
		return
	grid[grid_pos.x][grid_pos.y] = TileType.LADDER
	_set_visual_cell(grid_pos.x, grid_pos.y)
	GameManager.guest_ladder_count -= 1
	queue_redraw()
	rpc_ladder_placed.rpc_id(NetworkManager.guest_peer_id, grid_pos)
	rpc_sync_guest_ladder_count.rpc_id(NetworkManager.guest_peer_id, GameManager.guest_ladder_count)

## Guest → Host: request retrieving a ladder at grid_pos.
## Host validates range, tile, then returns the ladder to the guest's inventory.
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_remove_ladder(grid_pos: Vector2i) -> void:
	if not NetworkManager.is_host:
		return
	if not guest_player_node:
		return
	if grid_pos.x < 0 or grid_pos.x >= GRID_COLS or grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
		return
	if grid[grid_pos.x][grid_pos.y] != TileType.LADDER:
		return
	var guest_tile := Vector2i(
		floori(guest_player_node.global_position.x / CELL_SIZE),
		floori(guest_player_node.global_position.y / CELL_SIZE)
	)
	if Vector2(grid_pos - guest_tile).length() > guest_player_node.mine_range:
		return
	grid[grid_pos.x][grid_pos.y] = TileType.EMPTY
	_set_tile_collision(grid_pos.x, grid_pos.y, false)
	_set_visual_cell(grid_pos.x, grid_pos.y)
	GameManager.guest_ladder_count += 1
	queue_redraw()
	rpc_ladder_removed.rpc_id(NetworkManager.guest_peer_id, grid_pos)
	rpc_sync_guest_ladder_count.rpc_id(NetworkManager.guest_peer_id, GameManager.guest_ladder_count)

## Host → Guest: the guest's confirmed ladder count after a placement or retrieval.
## Updates the guest's local ladder_count and saves so it persists between sessions.
@rpc("authority", "call_remote", "reliable")
func rpc_sync_guest_ladder_count(count: int) -> void:
	GameManager.ladder_count = count
	GameManager.save_game()
	EventBus.ladder_count_changed.emit(count)

## Guest → Host: announce the guest's current ladder count on join so the host can
## seed guest_ladder_count for future placement validation.
@rpc("any_peer", "call_remote", "reliable")
func rpc_announce_guest_ladder_count(count: int) -> void:
	if not NetworkManager.is_host:
		return
	if multiplayer.get_remote_sender_id() != NetworkManager.guest_peer_id:
		return
	GameManager.guest_ladder_count = count

## Host → Guest: an explosive detonated — clear the blast area and apply local damage.
## Called after the host runs _explode_area so the guest's grid matches.
@rpc("authority", "call_remote", "reliable")
func rpc_explode_area(center: Vector2i) -> void:
	var r := 1
	for dc: int in range(-r, r + 1):
		for dr: int in range(-r, r + 1):
			var nc := center.x + dc
			var nr := center.y + dr
			if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
				if grid[nc][nr] != TileType.EMPTY:
					_mine_cell(nc, nr)
					var cell_world := Vector2(nc * CELL_SIZE + CELL_SIZE * 0.5, nr * CELL_SIZE + CELL_SIZE * 0.5)
					_spawn_mining_particles(cell_world, Color(1.0, 0.55, 0.05), 4, 80.0, 280.0)
					_spawn_mining_particles(cell_world, Color(1.0, 0.90, 0.20, 0.8), 2, 50.0, 180.0)
	SoundManager.play_explosion_sound()
	_shake_camera(12.0, 0.55)
	# Damage the local (guest) player if caught in the blast radius
	var local_p := _get_local_player()
	if local_p:
		var pcol := int(local_p.global_position.x / CELL_SIZE)
		var prow := int(local_p.global_position.y / CELL_SIZE)
		if abs(pcol - center.x) <= r and abs(prow - center.y) <= r:
			local_p.take_damage(1)
			SoundManager.play_damage_sound()
			_shake_camera(5.0, 0.25)

## Guest → Host: request an explosion triggered by the guest's player contact with an explosive.
## Host validates the tile, runs the detonation, then broadcasts rpc_explode_area.
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_explode(grid_pos: Vector2i) -> void:
	if not NetworkManager.is_host:
		return
	var col := grid_pos.x
	var row := grid_pos.y
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return
	var tile: int = grid[col][row]
	if tile != TileType.EXPLOSIVE and tile != TileType.EXPLOSIVE_ARMED:
		return  # Already cleared by the time the request arrived
	_mine_cell(col, row)
	_explode_area(col, row)
	if NetworkManager.guest_peer_id > 0:
		rpc_explode_area.rpc_id(NetworkManager.guest_peer_id, grid_pos)

## Bidirectional: notify the remote peer that a player entered ghost mode after dying.
## is_host_player: true when the host's player died, false when the guest's player died.
@rpc("any_peer", "call_remote", "reliable")
func rpc_ghost_mode(is_host_player: bool) -> void:
	var sender := multiplayer.get_remote_sender_id()
	# Validate: only the owning peer should announce their own player's death
	if is_host_player and sender != 1:
		return
	if not is_host_player and sender == 1:
		return
	if is_host_player:
		if player_node:
			player_node.visible = false
	else:
		if guest_player_node:
			guest_player_node.visible = false
	_show_zone_banner("PARTNER DIED — SPECTATING", Color(1.0, 0.25, 0.25), -1)
