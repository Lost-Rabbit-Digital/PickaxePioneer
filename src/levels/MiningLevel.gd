extends Node2D

# Terraria-style Mining Level
# Player is a CharacterBody2D that moves freely with gravity/jumping.
# Terrain is a grid rendered via _draw() with collision provided by a TileMapLayer.
# Mining is cursor-based: click to mine blocks within range.
# Fuel drains over time while underground (faster at depth).

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
	FUEL_NODE        = 17,
	FUEL_NODE_FULL   = 18,
	REFUEL_STATION   = 19,
	SURFACE          = 20,
	SURFACE_GRASS    = 21,
	EXIT_STATION     = 22,
	BOSS_SEGMENT     = 23,   # Centipede body segment — high HP, awards minerals on death
	BOSS_CORE        = 24,   # Boss core / head — highest HP, big reward
}

const TILE_NAMES: Dictionary = {
	TileType.SURFACE_GRASS:   "Topsoil",
	TileType.DIRT:            "Dirt",
	TileType.DIRT_DARK:       "Dark Mud",
	TileType.STONE:           "Stone",
	TileType.STONE_DARK:      "Dark Stone",
	TileType.ORE_COPPER:      "Copper",
	TileType.ORE_COPPER_DEEP: "Deep Copper",
	TileType.ORE_IRON:        "Iron",
	TileType.ORE_IRON_DEEP:   "Deep Iron",
	TileType.ORE_GOLD:        "Gold",
	TileType.ORE_GOLD_DEEP:   "Deep Gold",
	TileType.ORE_GEM:         "Gem",
	TileType.ORE_GEM_DEEP:    "Deep Gem",
	TileType.FUEL_NODE:       "Fuel",
	TileType.FUEL_NODE_FULL:  "Fuel",
	TileType.EXPLOSIVE:       "Explosive",
	TileType.EXPLOSIVE_ARMED: "Armed Explosive",
	TileType.LAVA:            "Lava",
	TileType.LAVA_FLOW:       "Lava Flow",
	TileType.REFUEL_STATION:  "Refuel Station",
	TileType.SURFACE:         "Surface",
	TileType.EXIT_STATION:    "Exit Station",
	TileType.BOSS_SEGMENT:    "Boss Segment",
	TileType.BOSS_CORE:       "Boss Core",
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
]

const TILE_COLORS: Dictionary = {
	TileType.DIRT:           Color(0.45, 0.28, 0.12),
	TileType.DIRT_DARK:      Color(0.35, 0.20, 0.08),
	TileType.ORE_COPPER:     Color(0.80, 0.50, 0.20),
	TileType.ORE_COPPER_DEEP: Color(0.70, 0.40, 0.10),
	TileType.ORE_IRON:       Color(0.65, 0.65, 0.72),
	TileType.ORE_IRON_DEEP:  Color(0.55, 0.55, 0.65),
	TileType.ORE_GOLD:       Color(1.00, 0.85, 0.10),
	TileType.ORE_GOLD_DEEP:  Color(0.90, 0.75, 0.05),
	TileType.ORE_GEM:        Color(0.15, 0.85, 0.75),
	TileType.ORE_GEM_DEEP:   Color(0.10, 0.75, 0.65),
	TileType.STONE:          Color(0.50, 0.50, 0.50),
	TileType.STONE_DARK:     Color(0.40, 0.40, 0.40),
	TileType.EXPLOSIVE:      Color(0.90, 0.10, 0.10),
	TileType.EXPLOSIVE_ARMED: Color(1.00, 0.00, 0.00),
	TileType.LAVA:           Color(1.00, 0.45, 0.00),
	TileType.LAVA_FLOW:      Color(1.00, 0.30, 0.00),
	TileType.FUEL_NODE:      Color(0.20, 0.80, 0.20),
	TileType.FUEL_NODE_FULL: Color(0.10, 1.00, 0.10),
	TileType.REFUEL_STATION: Color(0.50, 0.50, 0.50),
	TileType.SURFACE:        Color(0.35, 0.35, 0.35),
	TileType.SURFACE_GRASS:  Color(0.25, 0.50, 0.25),
	TileType.EXIT_STATION:   Color(0.15, 0.55, 0.15),
	TileType.BOSS_SEGMENT:   Color(0.55, 0.12, 0.08),
	TileType.BOSS_CORE:      Color(0.80, 0.05, 0.05),
}

const TILE_TEXTURE_PATHS: Dictionary = {
	TileType.DIRT:            "res://assets/blocks/dirt.png",
	TileType.DIRT_DARK:       "res://assets/blocks/mud.png",
	TileType.STONE:           "res://assets/blocks/stone_generic.png",
	TileType.STONE_DARK:      "res://assets/blocks/gravel.png",
	TileType.ORE_COPPER:      "res://assets/blocks/stone_generic_ore_nuggets.png",
	TileType.ORE_COPPER_DEEP: "res://assets/blocks/stone_generic_ore_crystalline.png",
	TileType.ORE_IRON:        "res://assets/blocks/gabbro.png",
	TileType.ORE_IRON_DEEP:   "res://assets/blocks/schist.png",
	TileType.ORE_GOLD:        "res://assets/blocks/sandstone.png",
	TileType.ORE_GOLD_DEEP:   "res://assets/blocks/granite.png",
	TileType.ORE_GEM:         "res://assets/blocks/amethyst.png",
	TileType.ORE_GEM_DEEP:    "res://assets/blocks/obsidian.png",
	TileType.EXPLOSIVE:       "res://assets/blocks/eucalyptus_log_top.png",
	TileType.EXPLOSIVE_ARMED: "res://assets/blocks/eucalyptus_log_top.png",
	TileType.LAVA:            "res://assets/blocks/sand_ugly_3.png",
	TileType.LAVA_FLOW:       "res://assets/blocks/sand_ugly_3.png",
	TileType.FUEL_NODE:       "res://assets/blocks/limestone.png",
	TileType.FUEL_NODE_FULL:  "res://assets/blocks/marble.png",
	TileType.REFUEL_STATION:  "res://assets/blocks/cobblestone_bricks.png",
	TileType.SURFACE:         "res://assets/blocks/grass_top.png",
	TileType.SURFACE_GRASS:   "res://assets/blocks/grass_side.png",
}

const TILE_HP: Dictionary = {
	TileType.SURFACE_GRASS:   4,
	TileType.DIRT:            4,
	TileType.DIRT_DARK:       4,
	TileType.STONE:           8,
	TileType.STONE_DARK:      10,
	TileType.ORE_COPPER:      11,
	TileType.ORE_COPPER_DEEP: 13,
	TileType.ORE_IRON:        14,
	TileType.ORE_IRON_DEEP:   17,
	TileType.ORE_GOLD:        20,
	TileType.ORE_GOLD_DEEP:   23,
	TileType.ORE_GEM:         29,
	TileType.ORE_GEM_DEEP:    32,
	TileType.BOSS_SEGMENT:    14,
	TileType.BOSS_CORE:       28,
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
	TileType.ORE_GEM:         20,
	TileType.ORE_GEM_DEEP:    30,
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
	"copper": [0.50, "Bronze Ingot"],
	"iron":   [0.50, "Steel Ingot"],
	"gold":   [0.75, "Pure Gold"],
	"gem":    [1.00, "Faceted Gem"],
}
# Two-ore cross-combos: "first+second" -> [bonus_pct, popup_label]
const SMELT_COMBOS: Dictionary = {
	"copper+iron": [1.00, "Alloy Ore"],
	"iron+copper": [1.00, "Alloy Ore"],
	"iron+gold":   [2.00, "Gilded Steel"],
	"gold+iron":   [2.00, "Gilded Steel"],
	"copper+gold": [1.50, "Fool's Gold"],
	"gold+copper": [1.50, "Fool's Gold"],
}

# ---------------------------------------------------------------------------
# Fossil forgiveness system (§3.6)
# ---------------------------------------------------------------------------
const FOSSIL_BASE_RATE: float  = 0.005
const FOSSIL_DROUGHT_SCALE: float = 0.005
const FOSSIL_CAP_RATE: float   = 0.30
const FOSSIL_TYPES: Dictionary = {
	TileType.DIRT:            {"name": "Ancient Root",    "minerals": 25},
	TileType.DIRT_DARK:       {"name": "Root Fossil",     "minerals": 30},
	TileType.STONE:           {"name": "Trilobite",       "minerals": 50},
	TileType.STONE_DARK:      {"name": "Ammonite",        "minerals": 60},
	TileType.ORE_COPPER:      {"name": "Mineralite",      "minerals": 40},
	TileType.ORE_COPPER_DEEP: {"name": "Deep Mineralite", "minerals": 50},
	TileType.ORE_IRON:        {"name": "Iron Fossil",     "minerals": 65},
	TileType.ORE_GOLD:        {"name": "Gilded Fossil",   "minerals": 100},
	TileType.ORE_GEM:         {"name": "Crystal Fossil",  "minerals": 120},
}

# ---------------------------------------------------------------------------
# Sonar ping system (§3.2)
# ---------------------------------------------------------------------------
const SONAR_PING_DURATION: float = 3.0  # seconds until ping fades

# ---------------------------------------------------------------------------
# Wandering Trader system
# ---------------------------------------------------------------------------
# Depth rows that trigger a trader spawn — one per milestone
const TRADER_DEPTH_MILESTONES: Array[int] = [32, 64, 96, 128]
# World-space radius within which the trader can be interacted with
const TRADER_INTERACT_RADIUS: float = 128.0  # px (~2 tiles)

# Tier-scaled item definitions: [label, description, run_mineral_cost, tier_required]
const TRADER_ITEMS: Array = [
	{"key": "fuel",    "label": "Fuel Cache",      "desc": "+50 Fuel",                      "cost": 12, "tier": 1},
	{"key": "repair",  "label": "Carapace Patch",  "desc": "Restore 1 HP",                  "cost": 18, "tier": 1},
	{"key": "shroom",  "label": "Mining Shroom",   "desc": "Next 12 ores yield +100%",       "cost": 30, "tier": 2},
	{"key": "compass", "label": "Lucky Compass",   "desc": "2× Lucky Strike chance (run)",   "cost": 45, "tier": 3},
	{"key": "map",     "label": "Ancient Map",     "desc": "2× Sonar radius (run)",          "cost": 65, "tier": 4},
]

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
	TileType.FUEL_NODE, TileType.FUEL_NODE_FULL,
	TileType.SURFACE_GRASS,
	TileType.BOSS_SEGMENT, TileType.BOSS_CORE,
]

# Depth zones
const DEPTH_ZONE_ROWS   = [0, 16, 41, 71, 101]
const DEPTH_ZONE_NAMES  = ["Topsoil", "Limestone Belt", "Iron Mantle", "Gold Seam", "Crystal Caverns"]
const DEPTH_ZONE_COLORS = [
	Color(0.55, 0.40, 0.20),
	Color(0.65, 0.60, 0.50),
	Color(0.45, 0.50, 0.55),
	Color(0.80, 0.70, 0.15),
	Color(0.30, 0.65, 0.85),
]

# Time-based fuel drain: base rate (fuel per second) + depth multiplier
const FUEL_DRAIN_BASE: float = 1.0      # 1 fuel/sec on surface
const FUEL_DRAIN_DEPTH_MULT: float = 2.0 # Extra drain per depth ratio
var _fuel_drain_accum: float = 0.0

# ---------------------------------------------------------------------------
# Boss encounter system (§4)
# Bosses spawn at milestone depth rows. Each uses only existing mining tools.
# ---------------------------------------------------------------------------
const BOSS_MILESTONES: Array[int]  = [32, 64, 96, 112]
const BOSS_DRAIN_MULT: float       = 2.5   # fuel drain multiplier while boss is alive
const BOSS_SEGMENT_COUNT: int      = 12    # body segments per centipede encounter
const BOSS_REWARD_BONUS: int       = 100   # flat mineral bonus on defeat (on top of tile drops)

# Boss type identifiers
const BOSS_TYPE_NONE: int       = 0
const BOSS_TYPE_CENTIPEDE: int  = 1
const BOSS_TYPE_SPIDER: int     = 2
const BOSS_TYPE_MOLE: int       = 3
const BOSS_TYPE_GOLEM: int      = 4

var _boss_milestones_seen: Array[bool] = [false, false, false, false]
var _boss_active: bool = false
var _boss_spawn_row: int = -1
var _boss_tile_positions: Array[Vector2i] = []   # remaining live boss tiles
var _boss_pulse_time: float = 0.0
var _boss_type: int = BOSS_TYPE_NONE

# ---------------------------------------------------------------------------
# Blind Mole tremor system (boss 3, row 96)
# ---------------------------------------------------------------------------
const MOLE_TREMOR_INTERVAL: float  = 7.0   # seconds between tremors
const MOLE_TREMOR_WARNING: float   = 1.8   # warning duration before tremor hits
const MOLE_TREMOR_RADIUS: int      = 10    # grid tiles radius of collapse AoE
const MOLE_TREMOR_FILL_CHANCE: float = 0.55  # probability empty tile collapses per tremor

var _mole_tremor_timer: float = 0.0
var _mole_tremor_warning_active: bool = false
var _mole_tremor_warning_timer: float = 0.0
var _mole_center: Vector2i = Vector2i(-1, -1)

# ---------------------------------------------------------------------------
# Stone Golem phase system (boss 4, row 112)
# ---------------------------------------------------------------------------
# Three ore phases — player must last-mine the required ore type to deal damage
const GOLEM_PHASE_ORES: Array[String] = ["copper", "iron", "gold"]
const GOLEM_SEGMENTS_PER_PHASE: int   = 5  # segments to destroy before phase advances

var _golem_phase: int = 0           # 0=copper phase, 1=iron phase, 2=gold phase
var _golem_segments_this_phase: int = 0   # segments mined in current phase

var grid: Array = []
var has_left_spawn: bool = false

var tile_textures: Dictionary = {}
var player_texture: Texture2D

# Camera
var camera: Camera2D

# TileMapLayer for collision
var collision_tilemap: TileMapLayer
var _tileset: TileSet

# Surface Hub
var _hub_layer: CanvasLayer
var _hub_minerals_label: Label
var _hub_visible: bool = false
var _upgrade_layer: CanvasLayer

# Fuel Station Shop
var _fuel_shop_layer: CanvasLayer
var _fuel_shop_visible: bool = false
var _fuel_shop_minerals_label: Label
var _fuel_shop_btn_refuel_full: Button
var _fuel_shop_btn_refuel_half: Button
var _fuel_shop_btn_repair: Button

# Depth tracking
var _last_depth: int = 0
var _current_zone_idx: int = -1

var _ore_noise: FastNoiseLite
var _game_over: bool = false

# Per-tile damage/hit tracking for multi-hit mining
var _tile_damage: Dictionary = {}
var _tile_hits: Dictionary = {}
var _flash_cells: Dictionary = {}
var _mine_streak: int = 0
var _zones_discovered: Array[bool] = [false, false, false, false, false]
var _exit_pulse_time: float = 0.0

# Cursor highlight
var _cursor_grid_pos: Vector2i = Vector2i(-1, -1)

# Pheromone trails — mined tile positions with fade alpha (§3.3)
var _pheromone_trails: Dictionary = {}
const PHEROMONE_FADE_RATE: float = 0.025  # alpha units/sec (~40 s full fade

# Sonar ping state (§3.2)
var _sonar_ping_active: bool = false
var _sonar_ping_elapsed: float = 0.0
var _sonar_ping_center: Vector2i = Vector2i(-1, -1)
var _sonar_wave_radius: float = 0.0

# Consecutive smelting subsystem (§3.5) — logic lives in SmeltingSystem.gd
var smelt_system: SmeltingSystem = SmeltingSystem.new()

# Fossil forgiveness subsystem (§3.6) — logic lives in FossilSystem.gd
var fossil_system: FossilSystem = FossilSystem.new()

# Wandering Trader state
# Each entry: {world_pos: Vector2, tier: int, pulse: float}
var _active_traders: Array = []
var _trader_milestones_seen: Array[bool] = [false, false, false, false]
var _trader_shop_layer: CanvasLayer = null
var _trader_shop_visible: bool = false
var _current_trader: Dictionary = {}

# Run-length buffs granted by trader items
var _shroom_charges: int = 0       # Mining Shroom: remaining ores with doubled yield
var _lucky_compass_active: bool = false   # Lucky Compass: 2× lucky strike chance
var _ancient_map_active: bool = false     # Ancient Map: 2× sonar ping radius

# ---------------------------------------------------------------------------
# Forager Ant companion (§3.4)
# The forager follows the player underground, auto-collects a share of mined
# ore, and returns to the surface when full — banking those minerals safely
# even if the player later dies.
# ---------------------------------------------------------------------------
const FORAGER_CAPACITY_BASE: int = 30
const FORAGER_MOVE_SPEED: float = 140.0     # px/s while following/returning
const FORAGER_DEPOSIT_DELAY: float = 1.8    # seconds at surface before returning underground
const FORAGER_COLLECT_RADIUS: float = 80.0  # px radius within which forager sweeps up ore chunks
const FORAGER_COLLECT_INTERVAL: float = 0.25  # seconds between chunk-sweep passes

var _forager_world_pos: Vector2 = Vector2.ZERO
var _forager_state: String = "follow"   # "follow" | "return" | "deposit"
var _forager_carry: int = 0
var _forager_capacity: int = FORAGER_CAPACITY_BASE
var _forager_collect_timer: float = 0.0

# Settlement whetstone bonus: temporary +N mandible power for this run only
var _settlement_mandible_bonus: int = 0

# Per-run ore collection counts for inventory display
var _run_ore_counts: Dictionary = {}  # TileType int -> count mined this run

# Hazard damage cooldown to prevent instant death
var _hazard_cooldown: float = 0.0
const HAZARD_COOLDOWN_TIME: float = 1.0

@onready var player_node: PlayerProbe = $PlayerProbe
@onready var pause_menu = $PauseMenu

var _inventory_screen: InventoryScreen = null

# Farm animal NPCs
var _farm_npcs: Array = []
var _farm_npc_grid_cols: Array[int] = []
const FARM_NPC_ROW: int = 2  # Placed on the middle surface row

func _ready() -> void:
	var ant_spritesheet := load("res://assets/creatures/red_ant_spritesheet.png") as Texture2D
	var ant_atlas := AtlasTexture.new()
	ant_atlas.atlas = ant_spritesheet
	ant_atlas.region = Rect2(0, 0, 16, 16)
	player_texture = ant_atlas

	texture_filter = TEXTURE_FILTER_NEAREST

	_ore_noise = FastNoiseLite.new()
	_ore_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ore_noise.frequency = 0.06
	_ore_noise.seed = randi()

	_load_tile_textures()
	_generate_grid()
	_generate_cave_rooms()
	_setup_collision_tilemap()
	_sync_collision_tilemap()

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
	player_node.sprite.texture = player_texture

	EventBus.player_died.connect(_on_player_died)

	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)
	QuestManager.clear_quest()
	_setup_surface_hub()
	_setup_fuel_station_shop()
	_setup_farm_animals()

	# Apply settlement carry-over consumables (purchased at a settlement before this run)
	if GameManager.settlement_shroom_charges > 0:
		_shroom_charges += GameManager.settlement_shroom_charges
		GameManager.settlement_shroom_charges = 0
		EventBus.ore_mined_popup.emit(0, "Shroom charges ready!")
	if GameManager.settlement_mandible_bonus > 0:
		_settlement_mandible_bonus = GameManager.settlement_mandible_bonus
		GameManager.settlement_mandible_bonus = 0
	if GameManager.settlement_forager_bonus > 0:
		_forager_capacity += GameManager.settlement_forager_bonus
		GameManager.settlement_forager_bonus = 0

	# Spawn forager near the player's starting position
	_forager_world_pos = Vector2(
		(spawn_col + 2) * CELL_SIZE + CELL_SIZE * 0.5,
		spawn_row * CELL_SIZE + CELL_SIZE * 0.5
	)
	_forager_capacity = FORAGER_CAPACITY_BASE

	_setup_inventory_screen()
	queue_redraw()

# ---------------------------------------------------------------------------
# Collision TileMapLayer setup
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
# Grid generation (unchanged logic)
# ---------------------------------------------------------------------------

func _generate_grid() -> void:
	grid = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			if row < SURFACE_ROWS:
				column.append(TileType.SURFACE)
			elif col >= GRID_COLS - EXIT_COLS:
				column.append(_random_tile(col, row))
			else:
				column.append(_random_tile(col, row))
		grid.append(column)

	var refuel_col = GRID_COLS / 2
	grid[refuel_col][SURFACE_ROWS - 1] = TileType.REFUEL_STATION

	grid[GRID_COLS - 1][SURFACE_ROWS - 1] = TileType.EXIT_STATION

	for col in range(GRID_COLS - EXIT_COLS):
		grid[col][SURFACE_ROWS] = TileType.SURFACE_GRASS

	for col in range(GRID_COLS - EXIT_COLS):
		grid[col][SURFACE_ROWS + 1] = TileType.DIRT
	for col in range(GRID_COLS - EXIT_COLS):
		grid[col][SURFACE_ROWS + 2] = TileType.DIRT

func _generate_cave_rooms() -> void:
	# Carve open cavern chambers underground for exploration variety (dev notes: Medium Priority)
	# Each chamber is an ellipse with ore-rich walls.
	var num_rooms := randi_range(6, 10)
	for _i in range(num_rooms):
		var room_col := randi_range(5, GRID_COLS - 8)
		var room_row := randi_range(SURFACE_ROWS + 6, GRID_ROWS - 8)
		var half_w := randi_range(3, 7)
		var half_h := randi_range(2, 4)

		# Carve the interior empty space
		for dc in range(-half_w, half_w + 1):
			for dr in range(-half_h, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell <= 0.85:
					var nc := room_col + dc
					var nr := room_row + dr
					if nc >= 1 and nc < GRID_COLS - 1 and nr >= SURFACE_ROWS + 1 and nr < GRID_ROWS - 1:
						grid[nc][nr] = TileType.EMPTY

		# Seed ore pockets around the edge of the carved room
		var depth := float(room_row - SURFACE_ROWS) / float(GRID_ROWS - SURFACE_ROWS)
		for dc in range(-half_w - 1, half_w + 2):
			for dr in range(-half_h - 1, half_h + 2):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell > 0.85 and ell <= 1.35:
					var nc := room_col + dc
					var nr := room_row + dr
					if nc >= 1 and nc < GRID_COLS - 1 and nr >= SURFACE_ROWS + 1 and nr < GRID_ROWS - 1:
						if randf() < 0.38:
							var ore_tile := _depth_scaled_ore(depth)
							if ore_tile != TileType.EMPTY:
								grid[nc][nr] = ore_tile

func _depth_scaled_ore(depth: float) -> TileType:
	# Returns a depth-appropriate ore tile for cave room walls (respects allowed_ore_types)
	var allowed: Array = GameManager.allowed_ore_types
	var tiers: Array = []
	if depth > 0.65:
		if allowed.is_empty() or allowed.has("Gem"):   tiers.append(TileType.ORE_GEM_DEEP)
		if allowed.is_empty() or allowed.has("Gold"):  tiers.append(TileType.ORE_GOLD_DEEP)
		if allowed.is_empty() or allowed.has("Iron"):  tiers.append(TileType.ORE_IRON_DEEP)
	elif depth > 0.35:
		if allowed.is_empty() or allowed.has("Gold"):  tiers.append(TileType.ORE_GOLD)
		if allowed.is_empty() or allowed.has("Iron"):  tiers.append(TileType.ORE_IRON_DEEP)
		if allowed.is_empty() or allowed.has("Copper"): tiers.append(TileType.ORE_COPPER_DEEP)
	else:
		if allowed.is_empty() or allowed.has("Iron"):   tiers.append(TileType.ORE_IRON)
		if allowed.is_empty() or allowed.has("Copper"): tiers.append(TileType.ORE_COPPER_DEEP)
		if allowed.is_empty() or allowed.has("Copper"): tiers.append(TileType.ORE_COPPER)
	if tiers.is_empty():
		return TileType.EMPTY
	return tiers[randi() % tiers.size()]

func _random_tile(col: int, row: int) -> TileType:
	var r := randf()
	var depth := float(row - SURFACE_ROWS) / float(GRID_ROWS - SURFACE_ROWS)

	var allowed_hazards: Array = GameManager.allowed_hazard_types
	var explosive_ok := allowed_hazards.is_empty() or allowed_hazards.has("Explosives")
	var lava_ok := allowed_hazards.is_empty() or allowed_hazards.has("Lava")

	var base_hazard := 0.08 + depth * 0.20
	var explosive_bias := base_hazard * 0.6 if explosive_ok else 0.0
	var lava_bias      := base_hazard * 0.4 if lava_ok      else 0.0
	var total_hazard   := explosive_bias + lava_bias

	if   r < explosive_bias * (2.0 / 3.0):        return TileType.EXPLOSIVE
	elif r < explosive_bias:                        return TileType.EXPLOSIVE_ARMED
	elif r < explosive_bias + lava_bias * 0.5:     return TileType.LAVA
	elif r < total_hazard:                          return TileType.LAVA_FLOW

	elif r < total_hazard + 0.02: return TileType.FUEL_NODE
	elif r < total_hazard + 0.03: return TileType.FUEL_NODE_FULL

	var copper_chance := 0.14 - depth * 0.12
	var iron_chance   := 0.12 - depth * 0.04
	var gold_chance   := 0.04 + depth * 0.16
	var gem_chance    := 0.02 + depth * 0.18

	var allowed: Array = GameManager.allowed_ore_types
	if allowed.size() > 0:
		if not allowed.has("Copper"): copper_chance = 0.0
		if not allowed.has("Iron"):   iron_chance   = 0.0
		if not allowed.has("Gold"):   gold_chance   = 0.0
		if not allowed.has("Gem"):    gem_chance    = 0.0

	var noise_val: float = (_ore_noise.get_noise_2d(float(col), float(row)) + 1.0) * 0.5
	var ore_mult: float  = 0.3 + noise_val * 1.4
	copper_chance = maxf(0.0, copper_chance * ore_mult)
	iron_chance   = maxf(0.0, iron_chance   * ore_mult)
	gold_chance   = maxf(0.0, gold_chance   * ore_mult)
	gem_chance    = maxf(0.0, gem_chance    * ore_mult)

	var deep_ratio := 0.30 + depth * 0.50

	var ore_start := total_hazard + 0.03
	if r < ore_start + gem_chance * deep_ratio:                                             return TileType.ORE_GEM_DEEP
	elif r < ore_start + gem_chance:                                                         return TileType.ORE_GEM
	elif r < ore_start + gem_chance + gold_chance * deep_ratio:                              return TileType.ORE_GOLD_DEEP
	elif r < ore_start + gem_chance + gold_chance:                                           return TileType.ORE_GOLD
	elif r < ore_start + gem_chance + gold_chance + iron_chance * deep_ratio:                return TileType.ORE_IRON_DEEP
	elif r < ore_start + gem_chance + gold_chance + iron_chance:                             return TileType.ORE_IRON
	elif r < ore_start + gem_chance + gold_chance + iron_chance + copper_chance * deep_ratio: return TileType.ORE_COPPER_DEEP
	elif r < ore_start + gem_chance + gold_chance + iron_chance + copper_chance:              return TileType.ORE_COPPER

	var stone_chance := 0.10 + depth * 0.50
	var r2 := randf()
	if r2 < stone_chance * 0.6:    return TileType.STONE_DARK
	elif r2 < stone_chance:         return TileType.STONE
	elif r2 < stone_chance + 0.10:  return TileType.DIRT_DARK
	else:                            return TileType.DIRT

func _load_tile_textures() -> void:
	for tile_type in TILE_TEXTURE_PATHS:
		var path: String = TILE_TEXTURE_PATHS[tile_type]
		var tex := load(path) as Texture2D
		if tex:
			tile_textures[tile_type] = tex

# ---------------------------------------------------------------------------
# Camera follow (tracks player CharacterBody2D)
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	if not camera or not player_node:
		return
	camera.position = player_node.global_position

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _draw() -> void:
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

	# Background fills
	if min_row < SURFACE_ROWS:
		var sky_top := min_row * CELL_SIZE
		var sky_bottom := mini(SURFACE_ROWS, max_row + 1) * CELL_SIZE
		var bg_left: int = min_col * CELL_SIZE
		var bg_width: int = (max_col - min_col + 1) * CELL_SIZE
		draw_rect(Rect2(bg_left, sky_top, bg_width, sky_bottom - sky_top), Color(0.40, 0.65, 0.90))
	if max_row >= SURFACE_ROWS:
		var dirt_top := maxi(min_row, SURFACE_ROWS) * CELL_SIZE
		var dirt_bottom := (max_row + 1) * CELL_SIZE
		var bg_left: int = min_col * CELL_SIZE
		var bg_width: int = (max_col - min_col + 1) * CELL_SIZE
		var mid_row: float = float(min_row + max_row) * 0.5
		var view_depth_t: float = clamp(float(mid_row - SURFACE_ROWS) / float(GRID_ROWS - SURFACE_ROWS), 0.0, 1.0)
		var bg_color := Color(0.08, 0.06, 0.04).lerp(Color(0.10, 0.03, 0.05), view_depth_t)
		draw_rect(Rect2(bg_left, dirt_top, bg_width, dirt_bottom - dirt_top), bg_color)

	# Tile sprites
	for col in range(min_col, max_col + 1):
		for row in range(min_row, max_row + 1):
			var tile: int = grid[col][row]
			if tile == TileType.EMPTY or tile == TileType.SURFACE:
				continue

			var tile_rect := Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)

			if tile == TileType.EXIT_STATION:
				var pulse: float = sin(_exit_pulse_time * 3.0) * 0.5 + 0.5
				draw_rect(tile_rect, Color(0.10 + pulse * 0.10, 0.40 + pulse * 0.20, 0.10 + pulse * 0.10))
				var border_alpha := 0.55 + pulse * 0.45
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(border_alpha, border_alpha, border_alpha), false, 2.0)
				if pulse > 0.6:
					var glow_alpha: float = (pulse - 0.6) / 0.4 * 0.35
					draw_rect(Rect2(col * CELL_SIZE - 3, row * CELL_SIZE - 3, CELL_SIZE + 6, CELL_SIZE + 6),
						Color(0.20, 0.90, 0.20, glow_alpha), false, 3.0)
				var exit_font := ThemeDB.fallback_font
				draw_string(exit_font,
					Vector2(col * CELL_SIZE, row * CELL_SIZE + CELL_SIZE / 2 + 5),
					"EXIT",
					HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, 13,
					Color(0.35 + pulse * 0.45, 1.0, 0.35 + pulse * 0.20))
				continue

			var tex: Texture2D = tile_textures.get(tile)
			if tex:
				draw_texture_rect(tex, tile_rect, false)
			else:
				draw_rect(tile_rect, TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5)))

			if tile == TileType.REFUEL_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color.WHITE, false, 2.0)

			# Crack overlay
			var pk := Vector2i(col, row)
			if _tile_damage.has(pk):
				var tile_hp: int = TILE_HP.get(tile, 0)
				if tile_hp > 0:
					var damage_ratio := float(_tile_damage[pk]) / float(tile_hp)
					draw_rect(tile_rect, Color(0.0, 0.0, 0.0, damage_ratio * 0.6))

	# Impact flashes
	for pk in _flash_cells:
		var fc: int = pk.x
		var fr: int = pk.y
		if fc >= min_col and fc <= max_col and fr >= min_row and fr <= max_row:
			var frect := Rect2(fc * CELL_SIZE, fr * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(frect, Color(1.0, 1.0, 1.0, _flash_cells[pk]))

	# Cursor mining highlight
	if _cursor_grid_pos.x >= 0 and _cursor_grid_pos.y >= 0:
		var highlight_rect := Rect2(_cursor_grid_pos.x * CELL_SIZE, _cursor_grid_pos.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(highlight_rect, Color(1.0, 1.0, 1.0, 0.2), false, 2.0)

	# Pheromone trail overlay — faint purple on player-mined EMPTY tiles (§3.3)
	for pk in _pheromone_trails:
		var tc: int = pk.x
		var tr: int = pk.y
		if tc >= min_col and tc <= max_col and tr >= min_row and tr <= max_row:
			var trail_alpha: float = _pheromone_trails[pk] * 0.22
			draw_rect(Rect2(tc * CELL_SIZE, tr * CELL_SIZE, CELL_SIZE, CELL_SIZE),
				Color(0.55, 0.30, 0.80, trail_alpha))

	# Wandering Trader nodes — pulsing gold circle with "T" glyph
	for trader in _active_traders:
		var tp: Vector2 = trader["world_pos"]
		var tc_grid := Vector2i(floori(tp.x / CELL_SIZE), floori(tp.y / CELL_SIZE))
		if tc_grid.x < min_col or tc_grid.x > max_col or tc_grid.y < min_row or tc_grid.y > max_row:
			continue
		var pulse: float = sin(trader["pulse"] * 3.0) * 0.5 + 0.5
		var trader_color := Color(1.0, 0.75 + pulse * 0.15, 0.0 + pulse * 0.15, 0.90)
		var cx_px := tc_grid.x * CELL_SIZE + CELL_SIZE * 0.5
		var cy_px := tc_grid.y * CELL_SIZE + CELL_SIZE * 0.5
		var radius := CELL_SIZE * 0.40 + pulse * 4.0
		draw_circle(Vector2(cx_px, cy_px), radius, trader_color)
		draw_arc(Vector2(cx_px, cy_px), radius + 3.0, 0.0, TAU, 24,
			Color(1.0, 0.95, 0.50, 0.55 + pulse * 0.35), 2.0)
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(cx_px - 6, cy_px + 8), "T",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.10, 0.05, 0.00))

	# Boss tile pulse overlay — pulsing glow on remaining boss tiles (§4)
	if _boss_active and not _boss_tile_positions.is_empty():
		var boss_pulse := sin(_boss_pulse_time * 4.5) * 0.5 + 0.5

		# Choose boss tile colours based on boss type
		var core_fill := Color(1.0, 0.05, 0.05, 0.28 + boss_pulse * 0.28)
		var core_border := Color(1.0, 0.80, 0.10, 0.50 + boss_pulse * 0.30)
		var seg_fill := Color(0.85, 0.15, 0.05, 0.18 + boss_pulse * 0.18)
		var seg_border := Color(0.70, 0.20, 0.05, 0.40 + boss_pulse * 0.25)
		match _boss_type:
			BOSS_TYPE_MOLE:
				core_fill   = Color(0.50, 0.30, 0.08, 0.30 + boss_pulse * 0.28)
				core_border = Color(0.80, 0.60, 0.20, 0.55 + boss_pulse * 0.30)
				seg_fill    = Color(0.40, 0.25, 0.05, 0.18 + boss_pulse * 0.18)
				seg_border  = Color(0.60, 0.40, 0.10, 0.40 + boss_pulse * 0.25)
			BOSS_TYPE_GOLEM:
				# Colour shifts with each armor phase
				var phase_colors: Array = [
					[Color(0.80, 0.50, 0.20), Color(0.95, 0.70, 0.40)],  # copper phase
					[Color(0.55, 0.55, 0.65), Color(0.75, 0.75, 0.90)],  # iron phase
					[Color(1.00, 0.85, 0.10), Color(1.00, 1.00, 0.50)],  # gold phase
				]
				var pi := clampi(_golem_phase, 0, phase_colors.size() - 1)
				core_fill   = Color(phase_colors[pi][0], 0.30 + boss_pulse * 0.28)
				core_border = Color(phase_colors[pi][1], 0.55 + boss_pulse * 0.30)
				seg_fill    = Color(phase_colors[pi][0], 0.18 + boss_pulse * 0.18)
				seg_border  = Color(phase_colors[pi][1], 0.40 + boss_pulse * 0.25)

		for bp in _boss_tile_positions:
			if bp.x < min_col or bp.x > max_col or bp.y < min_row or bp.y > max_row:
				continue
			var btile: int = grid[bp.x][bp.y]
			if btile != TileType.BOSS_SEGMENT and btile != TileType.BOSS_CORE:
				continue
			var brect := Rect2(bp.x * CELL_SIZE, bp.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			if btile == TileType.BOSS_CORE:
				draw_rect(brect, core_fill)
				draw_rect(brect, core_border, false, 2.5)
			else:
				draw_rect(brect, seg_fill)
				draw_rect(brect, seg_border, false, 1.5)

		# Boss fuel-drain warning — red vignette flicker on screen edges
		if boss_pulse > 0.75:
			var vignette_a := (boss_pulse - 0.75) / 0.25 * 0.12
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 4), Color(1.0, 0.0, 0.0, vignette_a))
			draw_rect(Rect2(min_col * CELL_SIZE, max_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 4), Color(1.0, 0.0, 0.0, vignette_a))

		# Blind Mole: tremor warning overlay — brown screen-edge pulse
		if _boss_type == BOSS_TYPE_MOLE and _mole_tremor_warning_active:
			var warn_ratio := 1.0 - (_mole_tremor_warning_timer / MOLE_TREMOR_WARNING)
			var warn_a := warn_ratio * 0.35
			var warn_color := Color(0.55, 0.30, 0.05, warn_a)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), warn_color)
			draw_rect(Rect2(min_col * CELL_SIZE, max_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), warn_color)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), warn_color)
			draw_rect(Rect2(max_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), warn_color)

		# Stone Golem: show required ore type indicator near the golem core
		if _boss_type == BOSS_TYPE_GOLEM and _golem_phase < GOLEM_PHASE_ORES.size():
			var golem_label := "Mine: " + GOLEM_PHASE_ORES[_golem_phase].capitalize()
			var label_px := Vector2(-9999.0, -9999.0)
			# Find core tile to draw label near
			for bp2 in _boss_tile_positions:
				if not _boss_tile_positions.is_empty() \
						and bp2.x >= 0 and bp2.x < GRID_COLS \
						and bp2.y >= 0 and bp2.y < GRID_ROWS \
						and grid[bp2.x][bp2.y] == TileType.BOSS_CORE:
					label_px = Vector2(bp2.x * CELL_SIZE - 40, bp2.y * CELL_SIZE - 22)
					break
			if label_px.x > -9000.0:
				var gfont := ThemeDB.fallback_font
				draw_string(gfont, label_px, golem_label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.95, 0.50, 0.90))

	# Forager Ant companion — amber circle with carry indicator (§3.4)
	var fg := _forager_world_pos
	var fg_col := floori(fg.x / CELL_SIZE)
	var fg_row := floori(fg.y / CELL_SIZE)
	if fg_col >= min_col - 1 and fg_col <= max_col + 1 and fg_row >= min_row - 1 and fg_row <= max_row + 1:
		var carry_ratio := float(_forager_carry) / float(max(_forager_capacity, 1))
		var forager_color: Color
		match _forager_state:
			"follow":
				forager_color = Color(0.95, 0.65, 0.05, 0.92)
			"return":
				forager_color = Color(0.55, 0.90, 0.30, 0.95)  # green when heading home
			_:  # deposit
				forager_color = Color(0.30, 0.70, 1.00, 0.85)  # blue while depositing
		draw_circle(fg, 10.0, forager_color)
		# Carry bar above the forager
		var bar_w := 26.0
		var bar_h := 4.0
		var bar_x := fg.x - bar_w * 0.5
		var bar_y := fg.y - 18.0
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.15, 0.15, 0.15, 0.80))
		draw_rect(Rect2(bar_x, bar_y, bar_w * carry_ratio, bar_h), Color(0.95, 0.80, 0.05, 0.90))
		# "F" glyph
		var fnt := ThemeDB.fallback_font
		draw_string(fnt, Vector2(fg.x - 4.0, fg.y + 6.0), "F",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.10, 0.05, 0.00))

	# Sonar ping overlay — expanding wave reveals ore tiles through rock (§3.2)
	if _sonar_ping_active and _sonar_ping_center.x >= 0:
		var ping_alpha := 1.0 - _sonar_ping_elapsed / SONAR_PING_DURATION
		var max_radius := GameManager.get_sonar_ping_radius()
		var cx := _sonar_ping_center.x
		var cy := _sonar_ping_center.y
		var scan_r := int(max_radius) + 2
		# Glow each ore tile that the expanding wave has already swept over
		for sc in range(maxi(min_col, cx - scan_r), mini(max_col + 1, cx + scan_r + 1)):
			for sr in range(maxi(min_row, cy - scan_r), mini(max_row + 1, cy + scan_r + 1)):
				var stile: int = grid[sc][sr]
				if stile != TileType.ORE_COPPER and stile != TileType.ORE_COPPER_DEEP \
				and stile != TileType.ORE_IRON and stile != TileType.ORE_IRON_DEEP \
				and stile != TileType.ORE_GOLD and stile != TileType.ORE_GOLD_DEEP \
				and stile != TileType.ORE_GEM and stile != TileType.ORE_GEM_DEEP \
				and stile != TileType.FUEL_NODE and stile != TileType.FUEL_NODE_FULL:
					continue
				var dist := Vector2(sc - cx, sr - cy).length()
				if dist > _sonar_wave_radius:
					continue
				# Glow age: how far behind the wave front this tile is
				var glow_age := _sonar_wave_radius - dist
				var glow_alpha := maxf(0.0, ping_alpha - glow_age * 0.12) * 0.80
				if glow_alpha <= 0.02:
					continue
				# Color by ore tier (level 1: uniform green; level 2+: color-coded)
				var glow_color := Color(0.20, 1.0, 0.40, glow_alpha)
				if GameManager.mineral_sense_level >= 2:
					if stile == TileType.ORE_GEM or stile == TileType.ORE_GEM_DEEP:
						glow_color = Color(0.10, 0.90, 1.00, glow_alpha)
					elif stile == TileType.ORE_GOLD or stile == TileType.ORE_GOLD_DEEP:
						glow_color = Color(1.00, 0.85, 0.10, glow_alpha)
					elif stile == TileType.ORE_IRON or stile == TileType.ORE_IRON_DEEP:
						glow_color = Color(0.65, 0.65, 1.00, glow_alpha)
					elif stile == TileType.FUEL_NODE or stile == TileType.FUEL_NODE_FULL:
						glow_color = Color(0.30, 1.00, 0.30, glow_alpha)
				draw_rect(Rect2(sc * CELL_SIZE, sr * CELL_SIZE, CELL_SIZE, CELL_SIZE), glow_color)
		# Expanding wave ring arc
		var wave_px := _sonar_wave_radius * CELL_SIZE
		var center_px := Vector2(cx * CELL_SIZE + CELL_SIZE * 0.5, cy * CELL_SIZE + CELL_SIZE * 0.5)
		if wave_px > 0:
			draw_arc(center_px, wave_px, 0.0, TAU, 48, Color(0.40, 1.0, 0.60, ping_alpha * 0.55), 2.0)

# ---------------------------------------------------------------------------
# Process — fuel drain, cursor highlight, flashes
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_exit_pulse_time += delta
	queue_redraw()

	# Fade impact flashes
	if _flash_cells.size() > 0:
		var to_remove: Array = []
		for pos_key in _flash_cells:
			_flash_cells[pos_key] -= delta * 5.0
			if _flash_cells[pos_key] <= 0.0:
				to_remove.append(pos_key)
		for k in to_remove:
			_flash_cells.erase(k)

	# Fade pheromone trails (§3.3)
	if _pheromone_trails.size() > 0:
		var to_remove_pt: Array = []
		for pk in _pheromone_trails:
			_pheromone_trails[pk] -= PHEROMONE_FADE_RATE * delta
			if _pheromone_trails[pk] <= 0.0:
				to_remove_pt.append(pk)
		for k in to_remove_pt:
			_pheromone_trails.erase(k)

	# Update sonar ping wave (§3.2)
	_update_sonar_ping(delta)

	# Pulse wandering traders and boss tiles regardless of menu state
	for trader in _active_traders:
		trader["pulse"] += delta
	if _boss_active:
		_boss_pulse_time += delta
		_update_blind_mole(delta)

	# Update forager regardless of menu state so it can animate returning home
	_update_forager(delta)

	if _hub_visible or _game_over or _fuel_shop_visible or _trader_shop_visible:
		return

	# Update cursor highlight
	_update_cursor_highlight()

	# Update camera to follow player
	_update_camera()

	# Update depth tracking
	_update_depth()

	# Check interact prompt (refuel station, farm NPCs)
	_update_interact_prompt()

	# Check if player reached exit zone
	_check_exit_zone()

	# Hazard cooldown
	if _hazard_cooldown > 0.0:
		_hazard_cooldown -= delta

	# Time-based fuel drain (only underground)
	if player_node:
		var depth_row := player_node.get_depth_row()
		if depth_row > 0:
			var depth_ratio := float(depth_row) / float(GRID_ROWS - SURFACE_ROWS)
			var boss_mult := BOSS_DRAIN_MULT if _boss_active else 1.0
			var drain_rate := (FUEL_DRAIN_BASE + depth_ratio * FUEL_DRAIN_DEPTH_MULT) * boss_mult
			_fuel_drain_accum += drain_rate * delta
			if _fuel_drain_accum >= 1.0:
				var drain_amount := int(_fuel_drain_accum)
				_fuel_drain_accum -= float(drain_amount)
				if not GameManager.consume_fuel(drain_amount):
					_on_out_of_fuel()

func _update_cursor_highlight() -> void:
	if not player_node:
		_cursor_grid_pos = Vector2i(-1, -1)
		return
	var mouse_world := get_global_mouse_position()
	var gp := Vector2i(floori(mouse_world.x / CELL_SIZE), floori(mouse_world.y / CELL_SIZE))
	if gp.x >= 0 and gp.x < GRID_COLS and gp.y >= 0 and gp.y < GRID_ROWS:
		var player_tile := player_node.get_grid_pos()
		var dist := Vector2(gp - player_tile).length()
		if dist <= player_node.mine_range:
			_cursor_grid_pos = gp
		else:
			_cursor_grid_pos = Vector2i(-1, -1)
	else:
		_cursor_grid_pos = Vector2i(-1, -1)

func _check_exit_zone() -> void:
	if not player_node or _game_over:
		return
	var player_col := floori(player_node.global_position.x / CELL_SIZE)
	var player_row := floori(player_node.global_position.y / CELL_SIZE)
	if player_col < GRID_COLS - EXIT_COLS:
		has_left_spawn = true
	if has_left_spawn and player_col >= GRID_COLS - EXIT_COLS and player_row < SURFACE_ROWS:
		_show_surface_hub()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _hub_visible or _game_over or _fuel_shop_visible or _trader_shop_visible:
		return
	if event.is_action_pressed("toggle_inventory"):
		if _inventory_screen:
			if _inventory_screen.visible:
				_inventory_screen.close()
			else:
				_inventory_screen.open(_run_ore_counts, _shroom_charges,
					_lucky_compass_active, _ancient_map_active)
		return
	if event.is_action_pressed("ui_cancel"):
		pause_menu.show_menu()
		return
	if event.is_action_pressed("interact"):
		_try_interact()
		return
	if event.is_action_pressed("sonar_ping"):
		_try_sonar_ping()

# ---------------------------------------------------------------------------
# Mining API — called by PlayerProbe
# ---------------------------------------------------------------------------

func try_mine_at(grid_pos: Vector2i) -> void:
	var col := grid_pos.x
	var row := grid_pos.y
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return

	var tile: int = grid[col][row]
	if tile == TileType.EMPTY or tile == TileType.SURFACE:
		return

	# Fuel nodes — collect immediately
	if tile == TileType.FUEL_NODE or tile == TileType.FUEL_NODE_FULL:
		_mine_cell(col, row)
		GameManager.restore_fuel(10)
		EventBus.ore_mined_popup.emit(10, "Fuel")
		SoundManager.play_drill_sound()
		return

	# Explosives — detonate
	if tile == TileType.EXPLOSIVE or tile == TileType.EXPLOSIVE_ARMED:
		_mine_cell(col, row)
		_explode_area(col, row)
		_damage_player(1)
		return

	# Lava — can't mine lava
	if tile == TileType.LAVA or tile == TileType.LAVA_FLOW:
		return

	# Refuel station / Exit station — not mineable
	if tile == TileType.REFUEL_STATION or tile == TileType.EXIT_STATION:
		return

	# Stone Golem phase resistance — boss tiles only take damage when player last mined
	# the required ore type for the current armor phase.
	if _boss_active and _boss_type == BOSS_TYPE_GOLEM \
			and (tile == TileType.BOSS_SEGMENT or tile == TileType.BOSS_CORE):
		if _golem_phase < GOLEM_PHASE_ORES.size():
			var required := GOLEM_PHASE_ORES[_golem_phase]
			if smelt_system.last_ore_group != required:
				EventBus.ore_mined_popup.emit(0,
					"Resists! Mine " + required.capitalize() + " ore first!")
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
		_mine_cell(col, row)
		# Boss tile tracking — check defeat after removal from grid
		if tile == TileType.BOSS_SEGMENT or tile == TileType.BOSS_CORE:
			_boss_tile_positions.erase(Vector2i(col, row))
			# Stone Golem: count mined segments to advance armor phases
			if _boss_active and _boss_type == BOSS_TYPE_GOLEM \
					and tile == TileType.BOSS_SEGMENT:
				_golem_segments_this_phase += 1
				if _golem_segments_this_phase >= GOLEM_SEGMENTS_PER_PHASE:
					_golem_segments_this_phase = 0
					_golem_phase += 1
					if _golem_phase < GOLEM_PHASE_ORES.size():
						var next_ore := GOLEM_PHASE_ORES[_golem_phase].capitalize()
						_show_zone_banner("ARMOR CRACKED!", Color(0.85, 0.70, 0.20))
						EventBus.ore_mined_popup.emit(0, "Now mine " + next_ore + "!")
						_shake_camera(8.0, 0.4)
					else:
						# All armor phases complete — core is fully exposed
						_show_zone_banner("CORE EXPOSED!", Color(1.00, 0.40, 0.00))
						EventBus.ore_mined_popup.emit(0, "Strike the core!")
						_shake_camera(8.0, 0.4)
			if _boss_tile_positions.is_empty() and _boss_active:
				_on_boss_defeated()
		if tile in MINEABLE_TILES:
			var minerals: int = TILE_MINERALS.get(tile, 1)
			_mine_streak += 1
			var lucky_chance := LUCKY_STRIKE_CHANCE * (2.0 if _lucky_compass_active else 1.0)
			var lucky := tile in ORE_TILES and randf() < lucky_chance
			if lucky:
				minerals *= 2
			# Mining Shroom buff: doubled yield on ore tiles
			if _shroom_charges > 0 and tile in ORE_TILES:
				minerals *= 2
				_shroom_charges -= 1
			# Track ore counts for inventory (ore tiles only)
			if tile in ORE_TILES:
				_run_ore_counts[tile] = _run_ore_counts.get(tile, 0) + 1
			# Fossil forgiveness check (§3.6) — before awarding base minerals
			fossil_system.check(tile, FOSSIL_TYPES.get(tile, {}))
			# Consecutive smelting bonus (§3.5) — awards extra currency internally
			smelt_system.process(SMELT_ORE_GROUPS.get(tile, ""), minerals)
			if tile in ORE_TILES:
				# Ore tiles break into physical chunks the player (or forager) must collect.
				var world_pos := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
				_spawn_ore_chunks(tile, minerals, world_pos)
				GameManager.track_ore_mined(tile, minerals)
				var popup_label: String = "LUCKY!" if lucky else TILE_NAMES.get(tile, "Mineral")
				EventBus.ore_mined_popup.emit(minerals, popup_label)
			else:
				# Non-ore tiles (dirt, stone, grass) still reward instantly.
				GameManager.add_currency(minerals)
				GameManager.track_ore_mined(tile, minerals)
				EventBus.minerals_earned.emit(minerals)
				EventBus.ore_mined_popup.emit(minerals, TILE_NAMES.get(tile, "Mineral"))
			_check_streak_milestone()
		SoundManager.play_drill_sound()
	else:
		_tile_damage[pos_key] = new_damage
		_tile_hits[pos_key] = hits_so_far + 1
		SoundManager.play_impact_sound()

# Called by PlayerProbe when it overlaps a hazard tile
func check_player_hazard(col: int, row: int) -> void:
	if _hazard_cooldown > 0.0 or _game_over:
		return
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return
	var tile: int = grid[col][row]
	if tile == TileType.LAVA or tile == TileType.LAVA_FLOW:
		_damage_player(1)
		_hazard_cooldown = HAZARD_COOLDOWN_TIME
	elif tile == TileType.EXPLOSIVE or tile == TileType.EXPLOSIVE_ARMED:
		_mine_cell(col, row)
		_explode_area(col, row)
		_damage_player(1)
		_hazard_cooldown = HAZARD_COOLDOWN_TIME

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _check_streak_milestone() -> void:
	if _mine_streak > 0 and _mine_streak % 5 == 0:
		var bonus := mini(_mine_streak, 15)
		GameManager.add_currency(bonus)
		EventBus.minerals_earned.emit(bonus)
		EventBus.ore_mined_popup.emit(bonus, "Streak!")

func _mine_cell(col: int, row: int) -> void:
	grid[col][row] = TileType.EMPTY
	_set_tile_collision(col, row, false)
	# Record pheromone trail on player-mined cells (§3.3)
	_pheromone_trails[Vector2i(col, row)] = 1.0

# Spawns physical ore chunks that scatter from the mined tile position.
# The player and forager ant must collect them to bank the minerals.
func _spawn_ore_chunks(tile: int, minerals: int, world_pos: Vector2) -> void:
	if minerals <= 0:
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
	for dc in range(-1, 2):
		for dr in range(-1, 2):
			var nc := center_col + dc
			var nr := center_row + dr
			if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
				grid[nc][nr] = TileType.EMPTY
				_set_tile_collision(nc, nr, false)
	SoundManager.play_explosion_sound()
	_shake_camera(6.0, 0.35)

func _damage_player(amount: int) -> void:
	if player_node and player_node.has_method("take_damage"):
		player_node.take_damage(amount)
		SoundManager.play_damage_sound()
		_shake_camera(5.0, 0.25)

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	_show_game_over_overlay("YOU DIED", "Run minerals have been lost...")
	await get_tree().create_timer(2.5).timeout
	GameManager.lose_run()

func _on_out_of_fuel() -> void:
	if _game_over:
		return
	_game_over = true
	_show_game_over_overlay("OUT OF FUEL", "Run minerals have been lost...")
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
# Sonar ping (§3.2)
# ---------------------------------------------------------------------------

func _try_sonar_ping() -> void:
	if _sonar_ping_active or not player_node:
		return
	var fuel_cost := GameManager.get_sonar_ping_fuel_cost()
	if GameManager.current_fuel < fuel_cost:
		EventBus.ore_mined_popup.emit(0, "No fuel for ping")
		return
	GameManager.consume_fuel(fuel_cost)
	_sonar_ping_active = true
	_sonar_ping_elapsed = 0.0
	_sonar_wave_radius = 0.0
	_sonar_ping_center = player_node.get_grid_pos()

func _update_sonar_ping(delta: float) -> void:
	if not _sonar_ping_active:
		return
	_sonar_ping_elapsed += delta
	var max_radius := GameManager.get_sonar_ping_radius() * (2.0 if _ancient_map_active else 1.0)
	_sonar_wave_radius = (_sonar_ping_elapsed / SONAR_PING_DURATION) * max_radius
	if _sonar_ping_elapsed >= SONAR_PING_DURATION:
		_sonar_ping_active = false

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
	if not player_node:
		return
	var depth: int = player_node.get_depth_row()
	if depth != _last_depth:
		_last_depth = depth
		EventBus.depth_changed.emit(depth)
		_check_zone_transition(depth)
		_check_trader_milestone(depth)
		_check_boss_milestone(depth)
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
			_show_zone_banner(DEPTH_ZONE_NAMES[new_zone_idx], DEPTH_ZONE_COLORS[new_zone_idx])
			if new_zone_idx > 0 and not _zones_discovered[new_zone_idx]:
				_zones_discovered[new_zone_idx] = true
				const DISCOVERY_FUEL := 20
				GameManager.restore_fuel(DISCOVERY_FUEL)
				EventBus.ore_mined_popup.emit(DISCOVERY_FUEL, "Discovery!")

func _show_zone_banner(zone_name: String, color: Color) -> void:
	const VW: int = 1280
	const VH: int = 720
	const BANNER_H: int = 52
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var banner := ColorRect.new()
	banner.size = Vector2(VW, BANNER_H)
	banner.position = Vector2(0, VH / 2 - BANNER_H / 2)
	banner.color = Color(0.0, 0.0, 0.0, 0.78)
	layer.add_child(banner)
	var label := Label.new()
	label.text = zone_name.to_upper()
	label.size = Vector2(VW, BANNER_H)
	label.position = Vector2(0, VH / 2 - BANNER_H / 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 26)
	label.modulate = color
	layer.add_child(label)
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
	if not player_node:
		return
	var player_gp := player_node.get_grid_pos()
	if player_gp.x >= 0 and player_gp.x < GRID_COLS and player_gp.y >= 0 and player_gp.y < GRID_ROWS:
		var current_tile: int = grid[player_gp.x][player_gp.y]
		if current_tile == TileType.REFUEL_STATION:
			var key_name := _get_interact_key_name()
			player_node.show_prompt("Press %s to open shop" % key_name)
			var world_pos := Vector2(player_gp.x * CELL_SIZE + CELL_SIZE * 0.5, player_gp.y * CELL_SIZE)
			var screen_pos := get_viewport().get_canvas_transform() * world_pos
			player_node.set_prompt_position(screen_pos)
			return
	# Check adjacent tiles for refuel station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.REFUEL_STATION:
				var key_name := _get_interact_key_name()
				player_node.show_prompt("Press %s to open shop" % key_name)
				var world_pos := Vector2(check.x * CELL_SIZE + CELL_SIZE * 0.5, check.y * CELL_SIZE)
				var screen_pos := get_viewport().get_canvas_transform() * world_pos
				player_node.set_prompt_position(screen_pos)
				return
	var nearby_trader := _get_nearby_trader()
	if nearby_trader.size() > 0:
		var key_name := _get_interact_key_name()
		player_node.show_prompt("Press %s to trade" % key_name)
		var screen_pos := get_viewport().get_canvas_transform() * (nearby_trader["world_pos"] as Vector2)
		player_node.set_prompt_position(screen_pos + Vector2(0, -CELL_SIZE))
		return
	var nearby_npc: FarmAnimalNPC = _get_nearby_farm_npc()
	if nearby_npc:
		var key_name := _get_interact_key_name()
		player_node.show_prompt("Press %s to pet the %s" % [key_name, nearby_npc.animal_name])
		var world_pos := player_node.global_position + Vector2(0, -CELL_SIZE)
		var screen_pos := get_viewport().get_canvas_transform() * world_pos
		player_node.set_prompt_position(screen_pos)
	else:
		player_node.hide_prompt()

func _get_nearby_farm_npc() -> FarmAnimalNPC:
	if not player_node:
		return null
	var player_gp := player_node.get_grid_pos()
	if player_gp.y >= SURFACE_ROWS:
		return null
	for i in range(_farm_npcs.size()):
		if abs(_farm_npc_grid_cols[i] - player_gp.x) <= 1:
			return _farm_npcs[i]
	return null

func _try_interact() -> void:
	if not player_node:
		return
	# Wandering Trader takes priority when in range
	var nearby_trader := _get_nearby_trader()
	if nearby_trader.size() > 0:
		_show_trader_shop(nearby_trader)
		return
	# Check current + adjacent tiles for refuel station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.REFUEL_STATION:
				_show_fuel_station_shop()
				return
	var nearby_npc: FarmAnimalNPC = _get_nearby_farm_npc()
	if nearby_npc:
		nearby_npc.wiggle()

# ---------------------------------------------------------------------------
# Farm animals
# ---------------------------------------------------------------------------

func _setup_farm_animals() -> void:
	var npc_scene := load("res://src/entities/npcs/FarmAnimalNPC.tscn") as PackedScene
	if not npc_scene:
		return
	var animals := [
		{"name": "Chicken", "texture_path": "res://assets/creatures/chicken_spritesheet.png", "col": 4},
		{"name": "Sheep",   "texture_path": "res://assets/creatures/sheep_spritesheet.png",   "col": 8},
		{"name": "Pig",     "texture_path": "res://assets/creatures/pig_spritesheet.png",     "col": 12},
	]
	for a in animals:
		var npc := npc_scene.instantiate() as FarmAnimalNPC
		npc.animal_name = a["name"]
		var tex := load(a["texture_path"]) as Texture2D
		if tex:
			npc.get_node("Sprite2D").texture = tex
		npc.scale = Vector2(2.0, 2.0)
		npc.position = Vector2(
			a["col"] * CELL_SIZE + CELL_SIZE * 0.5,
			FARM_NPC_ROW * CELL_SIZE + CELL_SIZE * 0.5
		)
		add_child(npc)
		_farm_npcs.append(npc)
		_farm_npc_grid_cols.append(a["col"])

# ---------------------------------------------------------------------------
# Inventory Screen
# ---------------------------------------------------------------------------

func _setup_inventory_screen() -> void:
	var inv_scene := load("res://src/ui/InventoryScreen.tscn") as PackedScene
	if inv_scene:
		_inventory_screen = inv_scene.instantiate() as InventoryScreen
		_inventory_screen.mining_level = self
		add_child(_inventory_screen)

# ---------------------------------------------------------------------------
# Surface Hub
# ---------------------------------------------------------------------------

func _setup_surface_hub() -> void:
	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 460
	const PANEL_H: int = 310
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_hub_layer = CanvasLayer.new()
	_hub_layer.layer = 10
	_hub_layer.visible = false
	add_child(_hub_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.70)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_hub_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.30, 0.70, 0.25, 1.0)
	_hub_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.09, 0.08, 0.06, 0.97)
	_hub_layer.add_child(panel)

	var title := Label.new()
	title.text = "You surfaced!"
	title.position = Vector2(PX, PY + 14)
	title.size = Vector2(PANEL_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_layer.add_child(title)

	_hub_minerals_label = Label.new()
	_hub_minerals_label.position = Vector2(PX, PY + 50)
	_hub_minerals_label.size = Vector2(PANEL_W, 28)
	_hub_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_minerals_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	_hub_layer.add_child(_hub_minerals_label)

	var divider := ColorRect.new()
	divider.position = Vector2(PX + 20, PY + 86)
	divider.size = Vector2(PANEL_W - 40, 2)
	divider.color = Color(0.30, 0.70, 0.25, 0.6)
	_hub_layer.add_child(divider)

	const BTN_X: int = PX + 30
	const BTN_W: int = PANEL_W - 60
	const BTN_H: int = 46

	var bank_btn := Button.new()
	bank_btn.text = "Bank Minerals & Keep Mining"
	bank_btn.position = Vector2(BTN_X, PY + 100)
	bank_btn.size = Vector2(BTN_W, BTN_H)
	bank_btn.pressed.connect(_hub_bank_and_continue)
	_hub_layer.add_child(bank_btn)

	var shop_btn := Button.new()
	shop_btn.text = "Open Colony Shop (banks minerals)"
	shop_btn.position = Vector2(BTN_X, PY + 156)
	shop_btn.size = Vector2(BTN_W, BTN_H)
	shop_btn.pressed.connect(_hub_open_shop)
	_hub_layer.add_child(shop_btn)

	var end_btn := Button.new()
	end_btn.text = "End Run & Return to Colony"
	end_btn.position = Vector2(BTN_X, PY + 212)
	end_btn.size = Vector2(BTN_W, BTN_H)
	end_btn.pressed.connect(_hub_end_run)
	_hub_layer.add_child(end_btn)

func _show_surface_hub() -> void:
	_hub_minerals_label.text = "Minerals this run: %d" % GameManager.run_mineral_currency
	_hub_layer.visible = true
	_hub_visible = true

func _hide_surface_hub() -> void:
	_hub_layer.visible = false
	_hub_visible = false

func _hub_bank_and_continue() -> void:
	GameManager.bank_currency()
	_hide_surface_hub()

func _hub_open_shop() -> void:
	GameManager.bank_currency()
	_hide_surface_hub()
	_open_upgrade_overlay()

func _hub_end_run() -> void:
	_hide_surface_hub()
	GameManager.complete_run()

# ---------------------------------------------------------------------------
# Upgrade overlay
# ---------------------------------------------------------------------------

func _open_upgrade_overlay() -> void:
	const VW: int = 1280
	const VH: int = 720
	_upgrade_layer = CanvasLayer.new()
	_upgrade_layer.layer = 10
	add_child(_upgrade_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_layer.add_child(dim)

	var upgrade_scene := load("res://src/ui/UpgradeMenu.tscn") as PackedScene
	if upgrade_scene:
		var upgrade_menu: Node = upgrade_scene.instantiate()
		if upgrade_menu is Control:
			(upgrade_menu as Control).set_anchors_preset(Control.PRESET_CENTER)
		_upgrade_layer.add_child(upgrade_menu)

	var close_btn := Button.new()
	close_btn.text = "Continue Mining"
	close_btn.position = Vector2((VW - 260) / 2, VH - 70)
	close_btn.size = Vector2(260, 44)
	close_btn.pressed.connect(_close_upgrade_overlay)
	_upgrade_layer.add_child(close_btn)

func _close_upgrade_overlay() -> void:
	if _upgrade_layer:
		_upgrade_layer.queue_free()
		_upgrade_layer = null

# ---------------------------------------------------------------------------
# Fuel Station Shop
# ---------------------------------------------------------------------------

const SHOP_REFUEL_FULL_COST: int = 10
const SHOP_REFUEL_HALF_COST: int = 5
const SHOP_REPAIR_COST: int = 15

func _setup_fuel_station_shop() -> void:
	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 420
	const PANEL_H: int = 330
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_fuel_shop_layer = CanvasLayer.new()
	_fuel_shop_layer.layer = 10
	_fuel_shop_layer.visible = false
	add_child(_fuel_shop_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_fuel_shop_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.20, 0.60, 0.90, 1.0)
	_fuel_shop_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.07, 0.10, 0.14, 0.97)
	_fuel_shop_layer.add_child(panel)

	var title := Label.new()
	title.text = "Fuel Station Shop"
	title.position = Vector2(PX, PY + 12)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.55, 0.85, 1.0)
	_fuel_shop_layer.add_child(title)

	_fuel_shop_minerals_label = Label.new()
	_fuel_shop_minerals_label.position = Vector2(PX, PY + 48)
	_fuel_shop_minerals_label.size = Vector2(PANEL_W, 24)
	_fuel_shop_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fuel_shop_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_fuel_shop_layer.add_child(_fuel_shop_minerals_label)

	var divider := ColorRect.new()
	divider.position = Vector2(PX + 20, PY + 80)
	divider.size = Vector2(PANEL_W - 40, 2)
	divider.color = Color(0.20, 0.60, 0.90, 0.5)
	_fuel_shop_layer.add_child(divider)

	const BTN_X: int = PX + 25
	const BTN_W: int = PANEL_W - 50
	const BTN_H: int = 48

	_fuel_shop_btn_refuel_full = Button.new()
	_fuel_shop_btn_refuel_full.position = Vector2(BTN_X, PY + 94)
	_fuel_shop_btn_refuel_full.size = Vector2(BTN_W, BTN_H)
	_fuel_shop_btn_refuel_full.pressed.connect(_shop_refuel_full)
	_fuel_shop_layer.add_child(_fuel_shop_btn_refuel_full)

	_fuel_shop_btn_refuel_half = Button.new()
	_fuel_shop_btn_refuel_half.position = Vector2(BTN_X, PY + 152)
	_fuel_shop_btn_refuel_half.size = Vector2(BTN_W, BTN_H)
	_fuel_shop_btn_refuel_half.pressed.connect(_shop_refuel_half)
	_fuel_shop_layer.add_child(_fuel_shop_btn_refuel_half)

	_fuel_shop_btn_repair = Button.new()
	_fuel_shop_btn_repair.position = Vector2(BTN_X, PY + 210)
	_fuel_shop_btn_repair.size = Vector2(BTN_W, BTN_H)
	_fuel_shop_btn_repair.pressed.connect(_shop_repair)
	_fuel_shop_layer.add_child(_fuel_shop_btn_repair)

	var divider2 := ColorRect.new()
	divider2.position = Vector2(PX + 20, PY + 268)
	divider2.size = Vector2(PANEL_W - 40, 2)
	divider2.color = Color(0.20, 0.60, 0.90, 0.5)
	_fuel_shop_layer.add_child(divider2)

	var close_btn := Button.new()
	close_btn.text = "Close Shop"
	close_btn.position = Vector2(BTN_X + (BTN_W - 180) / 2, PY + 278)
	close_btn.size = Vector2(180, 40)
	close_btn.pressed.connect(_hide_fuel_station_shop)
	_fuel_shop_layer.add_child(close_btn)

func _show_fuel_station_shop() -> void:
	_fuel_shop_minerals_label.text = "Run Minerals: %d" % GameManager.run_mineral_currency
	_fuel_shop_btn_refuel_full.text = "Full Refuel  (%d -> %d fuel)  -- %d minerals" % [
		GameManager.current_fuel, GameManager.get_max_fuel(), SHOP_REFUEL_FULL_COST]
	_fuel_shop_btn_refuel_half.text = "Refuel 50%%  (+%d fuel)  -- %d minerals" % [
		GameManager.get_max_fuel() / 2, SHOP_REFUEL_HALF_COST]
	_fuel_shop_btn_repair.text = "Emergency Repair  (+1 HP)  -- %d minerals" % SHOP_REPAIR_COST
	_fuel_shop_btn_refuel_full.disabled = GameManager.run_mineral_currency < SHOP_REFUEL_FULL_COST \
		or GameManager.current_fuel >= GameManager.get_max_fuel()
	_fuel_shop_btn_refuel_half.disabled = GameManager.run_mineral_currency < SHOP_REFUEL_HALF_COST \
		or GameManager.current_fuel >= GameManager.get_max_fuel()
	var at_max_hp: bool = player_node != null and player_node.is_at_max_health()
	_fuel_shop_btn_repair.disabled = GameManager.run_mineral_currency < SHOP_REPAIR_COST or at_max_hp
	_fuel_shop_layer.visible = true
	_fuel_shop_visible = true

func _hide_fuel_station_shop() -> void:
	_fuel_shop_layer.visible = false
	_fuel_shop_visible = false

func _shop_refuel_full() -> void:
	if GameManager.run_mineral_currency >= SHOP_REFUEL_FULL_COST:
		GameManager.run_mineral_currency -= SHOP_REFUEL_FULL_COST
		GameManager.current_fuel = GameManager.get_max_fuel()
		EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
		EventBus.fuel_changed.emit(GameManager.current_fuel, GameManager.get_max_fuel())
		SoundManager.play_drill_sound()
		_show_fuel_station_shop()

func _shop_refuel_half() -> void:
	if GameManager.run_mineral_currency >= SHOP_REFUEL_HALF_COST:
		GameManager.run_mineral_currency -= SHOP_REFUEL_HALF_COST
		GameManager.restore_fuel(GameManager.get_max_fuel() / 2)
		EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
		SoundManager.play_drill_sound()
		_show_fuel_station_shop()

func _shop_repair() -> void:
	if GameManager.run_mineral_currency >= SHOP_REPAIR_COST and player_node:
		GameManager.run_mineral_currency -= SHOP_REPAIR_COST
		EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
		player_node.heal(1)
		SoundManager.play_drill_sound()
		_show_fuel_station_shop()

# ---------------------------------------------------------------------------
# Wandering Trader
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Boss encounter system (§4)
# ---------------------------------------------------------------------------

func _check_boss_milestone(depth_row: int) -> void:
	if _boss_active:
		return  # Only one boss at a time
	for i in range(BOSS_MILESTONES.size()):
		if not _boss_milestones_seen[i] and depth_row >= BOSS_MILESTONES[i]:
			_boss_milestones_seen[i] = true
			match i:
				0: _spawn_centipede_king()
				1: _spawn_cave_spider_matriarch()
				2: _spawn_blind_mole()
				3: _spawn_stone_golem()

func _spawn_centipede_king() -> void:
	if not player_node:
		return
	var player_col := player_node.get_grid_pos().x
	var boss_row := BOSS_MILESTONES[0]

	# Build a two-row centipede body: head row + shorter underbelly row
	var positions: Array[Vector2i] = []
	var half := BOSS_SEGMENT_COUNT / 2

	for dc in range(-half, half + 1):
		var col: int = clamp(player_col + dc, 2, GRID_COLS - 3)
		var tile_type := TileType.BOSS_CORE if dc == 0 else TileType.BOSS_SEGMENT
		grid[col][boss_row] = tile_type
		_set_tile_collision(col, boss_row, true)
		positions.append(Vector2i(col, boss_row))

	# Underbelly — shorter row one tile below, no core
	for dc in range(-half + 2, half - 1):
		var col: int = clamp(player_col + dc, 2, GRID_COLS - 3)
		if grid[col][boss_row + 1] != TileType.SURFACE and grid[col][boss_row + 1] != TileType.EXIT_STATION:
			grid[col][boss_row + 1] = TileType.BOSS_SEGMENT
			_set_tile_collision(col, boss_row + 1, true)
			positions.append(Vector2i(col, boss_row + 1))

	_boss_tile_positions = positions
	_boss_active = true
	_boss_spawn_row = boss_row
	_boss_type = BOSS_TYPE_CENTIPEDE
	_boss_pulse_time = 0.0

	_show_zone_banner("CENTIPEDE KING AWAKENS!", Color(0.90, 0.10, 0.05))
	EventBus.ore_mined_popup.emit(0, "Boss! Fuel drains faster!")
	_shake_camera(8.0, 0.4)

func _spawn_cave_spider_matriarch() -> void:
	if not player_node:
		return
	var player_col := player_node.get_grid_pos().x
	var boss_row := BOSS_MILESTONES[1]
	var positions: Array[Vector2i] = []

	# Spider body — cross/diamond pattern centred on player column
	var offsets: Array = [
		Vector2i(0, 0),   # core (head)
		Vector2i(-1, 0), Vector2i(1, 0),  # body
		Vector2i(0, -1), Vector2i(0, 1),  # legs vertical
		Vector2i(-2, 0), Vector2i(2, 0),  # leg tips horizontal
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),  # web corners
	]

	for offset in offsets:
		var col: int = clamp(player_col + offset.x, 2, GRID_COLS - 3)
		var row: int = clamp(boss_row + offset.y, SURFACE_ROWS + 1, GRID_ROWS - 2)
		var tile_type := TileType.BOSS_CORE if offset == Vector2i(0, 0) else TileType.BOSS_SEGMENT
		grid[col][row] = tile_type
		_set_tile_collision(col, row, true)
		positions.append(Vector2i(col, row))

	_boss_tile_positions = positions
	_boss_active = true
	_boss_spawn_row = boss_row
	_boss_type = BOSS_TYPE_SPIDER
	_boss_pulse_time = 0.0

	_show_zone_banner("CAVE SPIDER MATRIARCH!", Color(0.60, 0.10, 0.80))
	EventBus.ore_mined_popup.emit(0, "Boss! Fuel drains faster!")
	_shake_camera(8.0, 0.4)

func _on_boss_defeated() -> void:
	_boss_active = false
	_boss_tile_positions.clear()
	_boss_type = BOSS_TYPE_NONE
	# Reset Blind Mole state
	_mole_tremor_timer = 0.0
	_mole_tremor_warning_active = false
	_mole_center = Vector2i(-1, -1)
	# Reset Stone Golem state
	_golem_phase = 0
	_golem_segments_this_phase = 0
	GameManager.add_currency(BOSS_REWARD_BONUS)
	EventBus.minerals_earned.emit(BOSS_REWARD_BONUS)
	EventBus.ore_mined_popup.emit(BOSS_REWARD_BONUS, "Boss defeated!")
	_show_zone_banner("BOSS DEFEATED!", Color(0.30, 1.00, 0.40))
	GameManager.restore_fuel(30)
	EventBus.ore_mined_popup.emit(30, "Fuel restored!")
	_shake_camera(14.0, 0.6)

func _spawn_blind_mole() -> void:
	if not player_node:
		return
	var player_col := player_node.get_grid_pos().x
	var boss_row := BOSS_MILESTONES[2]   # row 96
	var positions: Array[Vector2i] = []

	# Mole body — large oval cluster centred at boss_row
	var offsets: Array = [
		Vector2i(0, 0),                                              # core
		Vector2i(-1, 0), Vector2i(1, 0),                            # mid row
		Vector2i(-2, 0), Vector2i(2, 0),
		Vector2i(0, -1), Vector2i(0, 1),                            # vertical centre
		Vector2i(-1, -1), Vector2i(1, -1),                          # top arc
		Vector2i(-1,  1), Vector2i(1,  1),                          # bottom arc
		Vector2i(-2, -1), Vector2i(2, -1),                          # wide shoulders
		Vector2i(-2,  1), Vector2i(2,  1),
		Vector2i(0, -2), Vector2i(0,  2),                           # snout / tail tips
	]

	for offset in offsets:
		var col: int = clamp(player_col + offset.x, 2, GRID_COLS - 3)
		var row: int = clamp(boss_row + offset.y, SURFACE_ROWS + 1, GRID_ROWS - 2)
		var tile_type := TileType.BOSS_CORE if offset == Vector2i(0, 0) else TileType.BOSS_SEGMENT
		grid[col][row] = tile_type
		_set_tile_collision(col, row, true)
		positions.append(Vector2i(col, row))

	_boss_tile_positions = positions
	_boss_active = true
	_boss_spawn_row = boss_row
	_boss_type = BOSS_TYPE_MOLE
	_boss_pulse_time = 0.0
	_mole_center = Vector2i(player_col, boss_row)
	_mole_tremor_timer = MOLE_TREMOR_INTERVAL  # first tremor after full interval

	_show_zone_banner("THE BLIND MOLE STIRS!", Color(0.55, 0.35, 0.10))
	EventBus.ore_mined_popup.emit(0, "Boss! Tremors will collapse tunnels!")
	_shake_camera(12.0, 0.6)


func _update_blind_mole(delta: float) -> void:
	if not _boss_active or _boss_type != BOSS_TYPE_MOLE:
		return

	if _mole_tremor_warning_active:
		_mole_tremor_warning_timer -= delta
		if _mole_tremor_warning_timer <= 0.0:
			_mole_tremor_warning_active = false
			_execute_mole_tremor()
		return

	_mole_tremor_timer -= delta
	if _mole_tremor_timer <= 0.0:
		_mole_tremor_timer = MOLE_TREMOR_INTERVAL
		_mole_tremor_warning_active = true
		_mole_tremor_warning_timer = MOLE_TREMOR_WARNING
		EventBus.ore_mined_popup.emit(0, "TREMOR INCOMING!")
		_shake_camera(5.0, 0.3)


func _execute_mole_tremor() -> void:
	# Collapse a portion of empty tiles within the tremor radius back to dirt
	var cx := _mole_center.x
	var cy := _mole_center.y
	var r := MOLE_TREMOR_RADIUS
	var collapsed := 0
	for tc in range(maxi(0, cx - r), mini(GRID_COLS, cx + r + 1)):
		for tr in range(maxi(SURFACE_ROWS + 1, cy - r), mini(GRID_ROWS - 1, cy + r + 1)):
			if grid[tc][tr] != TileType.EMPTY:
				continue
			var dist := Vector2(tc - cx, tr - cy).length()
			if dist > float(r):
				continue
			if randf() < MOLE_TREMOR_FILL_CHANCE:
				var new_tile := TileType.DIRT_DARK if tr > SURFACE_ROWS + 8 else TileType.DIRT
				grid[tc][tr] = new_tile
				_set_tile_collision(tc, tr, true)
				# Erase any stored damage on refilled tile
				_tile_damage.erase(Vector2i(tc, tr))
				_tile_hits.erase(Vector2i(tc, tr))
				collapsed += 1
	if collapsed > 0:
		queue_redraw()
	EventBus.ore_mined_popup.emit(0, "Tremor! " + str(collapsed) + " tiles collapsed!")
	_shake_camera(10.0, 0.5)


func _spawn_stone_golem() -> void:
	if not player_node:
		return
	var player_col := player_node.get_grid_pos().x
	var boss_row := BOSS_MILESTONES[3]   # row 112
	var positions: Array[Vector2i] = []

	# Golem body — thick rectangular armoured form
	var offsets: Array = [
		Vector2i(0, 0),                                              # core
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(2, 0),   # top row
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),            # mid row
		Vector2i(-2, 1), Vector2i(2, 1),
		Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2),            # leg row
		Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),            # shoulders
	]

	for offset in offsets:
		var col: int = clamp(player_col + offset.x, 2, GRID_COLS - 3)
		var row: int = clamp(boss_row + offset.y, SURFACE_ROWS + 1, GRID_ROWS - 2)
		var tile_type := TileType.BOSS_CORE if offset == Vector2i(0, 0) else TileType.BOSS_SEGMENT
		grid[col][row] = tile_type
		_set_tile_collision(col, row, true)
		positions.append(Vector2i(col, row))

	_boss_tile_positions = positions
	_boss_active = true
	_boss_spawn_row = boss_row
	_boss_type = BOSS_TYPE_GOLEM
	_boss_pulse_time = 0.0
	_golem_phase = 0
	_golem_segments_this_phase = 0

	var required := GOLEM_PHASE_ORES[0].capitalize()
	_show_zone_banner("STONE GOLEM AWAKENS!", Color(0.60, 0.55, 0.45))
	EventBus.ore_mined_popup.emit(0, "Mine " + required + " to crack its armor!")
	_shake_camera(14.0, 0.8)


func _check_trader_milestone(depth_row: int) -> void:
	for i in range(TRADER_DEPTH_MILESTONES.size()):
		if not _trader_milestones_seen[i] and depth_row >= TRADER_DEPTH_MILESTONES[i]:
			_trader_milestones_seen[i] = true
			_spawn_wandering_trader(i + 1)  # tier 1–4

func _spawn_wandering_trader(tier: int) -> void:
	if not player_node:
		return
	# Place the trader a couple of tiles to the right of the player
	var spawn_pos := player_node.global_position + Vector2(CELL_SIZE * 2.5, 0.0)
	_active_traders.append({"world_pos": spawn_pos, "tier": tier, "pulse": 0.0})
	EventBus.ore_mined_popup.emit(0, "Wandering Trader!")

func _get_nearby_trader() -> Dictionary:
	if not player_node:
		return {}
	for trader in _active_traders:
		if (player_node.global_position - trader["world_pos"]).length() <= TRADER_INTERACT_RADIUS:
			return trader
	return {}

func _show_trader_shop(trader: Dictionary) -> void:
	_current_trader = trader
	_trader_shop_visible = true

	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 480
	const PX: int = (VW - PANEL_W) / 2

	var tier: int = trader.get("tier", 1)
	var available_items: Array = []
	for item in TRADER_ITEMS:
		if item["tier"] <= tier:
			available_items.append(item)

	var panel_h: int = 120 + available_items.size() * 54 + 54
	var py: int = (VH - panel_h) / 2

	_trader_shop_layer = CanvasLayer.new()
	_trader_shop_layer.layer = 10
	add_child(_trader_shop_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_trader_shop_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, py - 3)
	border.size = Vector2(PANEL_W + 6, panel_h + 6)
	border.color = Color(0.85, 0.65, 0.10, 1.0)
	_trader_shop_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, py)
	panel.size = Vector2(PANEL_W, panel_h)
	panel.color = Color(0.08, 0.06, 0.03, 0.97)
	_trader_shop_layer.add_child(panel)

	var title := Label.new()
	title.text = "Wandering Trader  —  Tier %d" % tier
	title.position = Vector2(PX, py + 10)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.85, 0.20)
	_trader_shop_layer.add_child(title)

	var minerals_label := Label.new()
	minerals_label.text = "Run Minerals: %d" % GameManager.run_mineral_currency
	minerals_label.position = Vector2(PX, py + 42)
	minerals_label.size = Vector2(PANEL_W, 22)
	minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_trader_shop_layer.add_child(minerals_label)

	const BTN_W: int = PANEL_W - 60
	const BTN_X: int = PX + 30
	const BTN_H: int = 44
	var btn_y := py + 78
	for item in available_items:
		var btn := Button.new()
		btn.text = "%s  —  %s  (%d minerals)" % [item["label"], item["desc"], item["cost"]]
		btn.position = Vector2(BTN_X, btn_y)
		btn.size = Vector2(BTN_W, BTN_H)
		var item_key: String = item["key"]
		btn.pressed.connect(_trader_purchase.bind(item_key))
		_trader_shop_layer.add_child(btn)
		btn_y += BTN_H + 10

	var close_btn := Button.new()
	close_btn.text = "Farewell"
	close_btn.position = Vector2(BTN_X, btn_y + 4)
	close_btn.size = Vector2(BTN_W, BTN_H)
	close_btn.pressed.connect(_close_trader_shop)
	_trader_shop_layer.add_child(close_btn)

func _close_trader_shop() -> void:
	if _trader_shop_layer:
		_trader_shop_layer.queue_free()
		_trader_shop_layer = null
	_trader_shop_visible = false
	_current_trader = {}

# ---------------------------------------------------------------------------
# Forager Ant movement and banking (§3.4)
# ---------------------------------------------------------------------------

func _update_forager(delta: float) -> void:
	if not player_node or _game_over:
		return
	match _forager_state:
		"follow":
			# Hover a tile behind and above the player
			var target := player_node.global_position + Vector2(-CELL_SIZE * 1.2, -CELL_SIZE * 0.5)
			_forager_world_pos = _forager_world_pos.move_toward(target, FORAGER_MOVE_SPEED * delta)
			# Periodically sweep up nearby ore chunks
			_forager_collect_timer -= delta
			if _forager_collect_timer <= 0.0:
				_forager_collect_timer = FORAGER_COLLECT_INTERVAL
				_forager_sweep_chunks()
		"return":
			# Fly toward the left-centre surface strip to deposit
			var surface_y := (SURFACE_ROWS - 1) * CELL_SIZE + CELL_SIZE * 0.5
			var deposit_x := 46.0 * CELL_SIZE
			var target := Vector2(deposit_x, surface_y)
			_forager_world_pos = _forager_world_pos.move_toward(target, FORAGER_MOVE_SPEED * 1.8 * delta)
			if _forager_world_pos.distance_to(target) < 12.0:
				_forager_deposit()
		"deposit":
			# Stay put; timer ticks in _process below
			pass

	# Deposit timer — counted here so it works regardless of hub/shop state
	if _forager_state == "deposit":
		# Repurpose _forager_capacity as a timer storage trick; use a dedicated var instead
		pass  # handled inline in _forager_deposit()

# Scan for ore chunks near the forager and collect them into its carry.
func _forager_sweep_chunks() -> void:
	var chunks := get_tree().get_nodes_in_group("ore_chunk")
	for chunk in chunks:
		if not is_instance_valid(chunk):
			continue
		if _forager_world_pos.distance_to(chunk.global_position) < FORAGER_COLLECT_RADIUS:
			_forager_carry = mini(_forager_carry + chunk.value, _forager_capacity)
			chunk.collect_silent()
			if _forager_carry >= _forager_capacity:
				_forager_start_return()
				return

func _forager_start_return() -> void:
	_forager_state = "return"
	EventBus.ore_mined_popup.emit(0, "Forager heading home!")

func _forager_deposit() -> void:
	# Bank the carry directly to mineral_currency (bypasses run risk)
	if _forager_carry > 0:
		GameManager.mineral_currency += _forager_carry
		EventBus.ore_mined_popup.emit(_forager_carry, "Forager banked!")
		_forager_carry = 0
	_forager_state = "deposit"
	# After a short pause return underground via a timer
	await get_tree().create_timer(FORAGER_DEPOSIT_DELAY).timeout
	if not is_instance_valid(self):
		return
	_forager_state = "follow"

func _trader_purchase(item_key: String) -> void:
	var item_def: Dictionary = {}
	for item in TRADER_ITEMS:
		if item["key"] == item_key:
			item_def = item
			break
	if item_def.is_empty():
		return

	var cost: int = item_def["cost"]
	if GameManager.run_mineral_currency < cost:
		EventBus.ore_mined_popup.emit(0, "Not enough minerals")
		return

	match item_key:
		"fuel":
			GameManager.run_mineral_currency -= cost
			GameManager.restore_fuel(50)
			EventBus.ore_mined_popup.emit(0, "Fuel Pack!")
		"repair":
			if player_node and player_node.is_at_max_health():
				EventBus.ore_mined_popup.emit(0, "Already at full HP")
				return
			GameManager.run_mineral_currency -= cost
			player_node.heal(1)
			EventBus.ore_mined_popup.emit(0, "Carapace Patched!")
		"shroom":
			GameManager.run_mineral_currency -= cost
			_shroom_charges += 12
			EventBus.ore_mined_popup.emit(0, "Mining Shroom!")
		"compass":
			GameManager.run_mineral_currency -= cost
			_lucky_compass_active = true
			EventBus.ore_mined_popup.emit(0, "Lucky Compass!")
		"map":
			GameManager.run_mineral_currency -= cost
			_ancient_map_active = true
			EventBus.ore_mined_popup.emit(0, "Ancient Map!")

	EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
	SoundManager.play_drill_sound()
	_close_trader_shop()
	# Re-open with updated mineral count
	if _current_trader.size() == 0:
		_current_trader = _get_nearby_trader()
	if _current_trader.size() > 0:
		_show_trader_shop(_current_trader)
