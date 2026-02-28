extends Node2D

# Space Mining Level — a cat miner in SPACE!
# Player is a CharacterBody2D that moves freely with gravity/jumping.
# Terrain is a grid rendered via _draw() with collision provided by a TileMapLayer.
# Mining is cursor-based: click to mine space rocks and asteroids within range.
# Fuel drains over time while in deep space (faster at distance).

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
	TileType.ENERGY_NODE:       "Fuel Cell",
	TileType.ENERGY_NODE_FULL:  "Fuel Cell",
	TileType.EXPLOSIVE:       "Space Mine",
	TileType.EXPLOSIVE_ARMED: "Armed Space Mine",
	TileType.LAVA:            "Plasma",
	TileType.LAVA_FLOW:       "Plasma Stream",
	TileType.REENERGY_STATION:  "Refueling Dock",
	TileType.SURFACE:         "Launchpad",
	TileType.EXIT_STATION:    "Airlock",
	TileType.BOSS_SEGMENT:    "Boss Segment",
	TileType.BOSS_CORE:       "Boss Core",
	TileType.UPGRADE_STATION: "Upgrade Bay",
	TileType.SMELTERY_STATION: "Space Forge",
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
	TileType.DIRT:           Color(0.30, 0.30, 0.38),
	TileType.DIRT_DARK:      Color(0.22, 0.22, 0.30),
	TileType.ORE_COPPER:     Color(0.90, 0.60, 0.25),
	TileType.ORE_COPPER_DEEP: Color(0.80, 0.50, 0.15),
	TileType.ORE_IRON:       Color(0.90, 0.45, 0.70),
	TileType.ORE_IRON_DEEP:  Color(0.75, 0.35, 0.60),
	TileType.ORE_GOLD:       Color(0.85, 0.80, 1.00),
	TileType.ORE_GOLD_DEEP:  Color(0.70, 0.65, 0.90),
	TileType.ORE_GEM:        Color(0.20, 0.90, 0.95),
	TileType.ORE_GEM_DEEP:   Color(0.10, 0.80, 0.85),
	TileType.STONE:          Color(0.35, 0.25, 0.55),
	TileType.STONE_DARK:     Color(0.25, 0.18, 0.45),
	TileType.EXPLOSIVE:      Color(0.90, 0.10, 0.10),
	TileType.EXPLOSIVE_ARMED: Color(1.00, 0.00, 0.00),
	TileType.LAVA:           Color(1.00, 0.65, 0.00),
	TileType.LAVA_FLOW:      Color(1.00, 0.50, 0.00),
	TileType.ENERGY_NODE:      Color(0.20, 0.80, 0.90),
	TileType.ENERGY_NODE_FULL: Color(0.10, 1.00, 0.95),
	TileType.REENERGY_STATION: Color(0.40, 0.50, 0.60),
	TileType.SURFACE:        Color(0.15, 0.15, 0.25),
	TileType.SURFACE_GRASS:  Color(0.10, 0.20, 0.35),
	TileType.EXIT_STATION:   Color(0.15, 0.55, 0.70),
	TileType.BOSS_SEGMENT:   Color(0.70, 0.15, 0.50),
	TileType.BOSS_CORE:      Color(0.90, 0.10, 0.40),
	TileType.UPGRADE_STATION: Color(0.40, 0.50, 0.60),
	TileType.SMELTERY_STATION: Color(0.40, 0.50, 0.60),
}

const TILE_TEXTURE_PATHS: Dictionary = {
	TileType.DIRT:            "res://assets/blocks/dirt.png",
	TileType.DIRT_DARK:       "res://assets/blocks/mud.png",
	TileType.STONE:           "res://assets/blocks/stone_generic.png",
	TileType.STONE_DARK:      "res://assets/blocks/gravel.png",
	TileType.ORE_COPPER:      "res://assets/blocks/stone_ore_copper.png",
	TileType.ORE_COPPER_DEEP: "res://assets/blocks/stone_ore_copper.png",
	TileType.ORE_IRON:        "res://assets/blocks/stone_ore_iron.png",
	TileType.ORE_IRON_DEEP:   "res://assets/blocks/stone_ore_iron.png",
	TileType.ORE_GOLD:        "res://assets/blocks/stone_ore_gold.png",
	TileType.ORE_GOLD_DEEP:   "res://assets/blocks/stone_ore_gold.png",
	TileType.ORE_GEM:         "res://assets/blocks/stone_generic_ore_crystalline.png",
	TileType.ORE_GEM_DEEP:    "res://assets/blocks/stone_generic_ore_crystalline.png",
	TileType.EXPLOSIVE:       "res://assets/blocks/eucalyptus_log_top.png",
	TileType.EXPLOSIVE_ARMED: "res://assets/blocks/eucalyptus_log_top.png",
	TileType.LAVA:            "res://assets/blocks/sand_ugly_3.png",
	TileType.LAVA_FLOW:       "res://assets/blocks/sand_ugly_3.png",
	TileType.ENERGY_NODE:       "res://assets/blocks/limestone.png",
	TileType.ENERGY_NODE_FULL:  "res://assets/blocks/marble.png",
	TileType.REENERGY_STATION:  "res://assets/blocks/cobblestone_bricks.png",
	TileType.SURFACE:         "res://assets/blocks/grass_top.png",
	TileType.SURFACE_GRASS:   "res://assets/blocks/grass_side.png",
	TileType.UPGRADE_STATION: "res://assets/blocks/cobblestone_bricks.png",
	TileType.SMELTERY_STATION: "res://assets/blocks/cobblestone_bricks.png",
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

# ---------------------------------------------------------------------------
# Space Forge — ore-to-bar conversion and bar selling
# ---------------------------------------------------------------------------
const SMELTERY_ORE_GROUPS_ORDER: Array = ["copper", "iron", "gold", "gem"]
const SMELTERY_ORE_GROUP_TILES: Dictionary = {
	"copper": [TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP],
	"iron":   [TileType.ORE_IRON, TileType.ORE_IRON_DEEP],
	"gold":   [TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP],
	"gem":    [TileType.ORE_GEM, TileType.ORE_GEM_DEEP],
}
const SMELTERY_ORES_PER_BAR: int = 3   # ores consumed per bar smelted
const SMELTERY_BAR_SELL_VALUES: Dictionary = {
	"copper": 15,
	"iron":   30,
	"gold":   50,
	"gem":    75,
}
const SMELTERY_BAR_NAMES: Dictionary = {
	"copper": "Lunar Bar",
	"iron":   "Meteor Bar",
	"gold":   "Star Bar",
	"gem":    "Cosmic Bar",
}
const SMELTERY_GROUP_COLORS: Dictionary = {
	"copper": Color(0.90, 0.60, 0.25),
	"iron":   Color(0.90, 0.45, 0.70),
	"gold":   Color(0.85, 0.80, 1.00),
	"gem":    Color(0.20, 0.90, 0.95),
}

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

# ---------------------------------------------------------------------------
# Wandering Space Trader system
# ---------------------------------------------------------------------------
# Traders spawn randomly as the player mines deeper — independent of bosses.
const TRADER_CHECK_INTERVAL: int   = 10    # check for a trader spawn every N depth rows
const TRADER_FIRST_CHECK: int      = 15    # first eligible depth row
const TRADER_SPAWN_CHANCE: float   = 0.15  # 15 % chance per check
const TRADER_MAX_PER_RUN: int      = 3     # cap traders spawned per run
# World-space radius within which the trader can be interacted with
const TRADER_INTERACT_RADIUS: float = 128.0  # px (~2 tiles)

# Tier-scaled item definitions: [label, description, run_mineral_cost, tier_required]
const TRADER_ITEMS: Array = [
	{"key": "energy",    "label": "Fuel Cell Cache",    "desc": "+50 Fuel",                        "cost": 12, "tier": 1},
	{"key": "repair",  "label": "Spacesuit Patch",   "desc": "Restore 1 HP",                   "cost": 18, "tier": 1},
	{"key": "shroom",  "label": "Astro Shroom",     "desc": "Next 12 ores yield +100%",        "cost": 30, "tier": 2},
	{"key": "compass", "label": "Lucky Star Chart", "desc": "2× Lucky Strike chance (run)",    "cost": 45, "tier": 3},
	{"key": "map",     "label": "Deep Space Map",   "desc": "2× Scanner radius (run)",         "cost": 65, "tier": 4},
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
	TileType.ENERGY_NODE, TileType.ENERGY_NODE_FULL,
	TileType.SURFACE_GRASS,
	TileType.BOSS_SEGMENT, TileType.BOSS_CORE,
]

# Depth zones
const DEPTH_ZONE_ROWS   = [0, 16, 41, 71, 101]
const DEPTH_ZONE_NAMES  = ["Low Orbit", "Asteroid Belt", "Nebula Zone", "Star Cluster", "Deep Space"]
const DEPTH_ZONE_COLORS = [
	Color(0.40, 0.55, 0.80),
	Color(0.50, 0.40, 0.70),
	Color(0.60, 0.30, 0.75),
	Color(0.85, 0.70, 1.00),
	Color(0.20, 0.80, 0.95),
]

# Time-based energy drain: base rate (energy per second) + depth multiplier
const ENERGY_DRAIN_BASE: float = 1.0      # 1 energy/sec on surface
const ENERGY_DRAIN_DEPTH_MULT: float = 2.0 # Extra drain per depth ratio
var _energy_drain_accum: float = 0.0

# ---------------------------------------------------------------------------
# Boss encounter system (§4) — logic lives in BossSystem.gd
# ---------------------------------------------------------------------------
const BOSS_DRAIN_MULT: float = 1.5   # energy drain multiplier while boss is alive

var grid: Array = []
var has_left_spawn: bool = false

var tile_textures: Dictionary = {}

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

# Energy Station Shop
var _energy_shop_layer: CanvasLayer
var _energy_shop_visible: bool = false
var _energy_shop_minerals_label: Label
var _energy_shop_btn_reenergy_full: Button
var _energy_shop_btn_reenergy_half: Button
var _energy_shop_btn_repair: Button

# Upgrade Station Shop
var _upgrade_station_layer: CanvasLayer
var _upgrade_station_visible: bool = false
var _upgrade_station_minerals_label: Label
var _upgrade_station_btn_carapace: Button
var _upgrade_station_btn_legs: Button
var _upgrade_station_btn_mandibles: Button

# Smeltery Station
var _smeltery_layer: CanvasLayer
var _smeltery_visible: bool = false
var _smeltery_minerals_label: Label
var _smeltery_ore_labels: Dictionary = {}       # ore_group -> Label showing ore count
var _smeltery_bar_labels: Dictionary = {}       # ore_group -> Label showing bar count
var _smeltery_smelt_btns: Dictionary = {}       # ore_group -> Button to smelt
var _smeltery_sell_btns: Dictionary = {}        # ore_group -> Button to sell bars
var _run_bar_counts: Dictionary = {}            # ore_group -> int (bars smelted this run)

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

# Sonar ping subsystem (§3.2) — logic lives in SonarSystem.gd
var sonar_system: SonarSystem = SonarSystem.new()

# Consecutive smelting subsystem (§3.5) — logic lives in SmeltingSystem.gd
var smelt_system: SmeltingSystem = SmeltingSystem.new()

# Fossil forgiveness subsystem (§3.6) — logic lives in FossilSystem.gd
var fossil_system: FossilSystem = FossilSystem.new()

# Boss encounter subsystem (§4) — logic lives in BossSystem.gd
var boss_system: BossSystem = BossSystem.new()

# Forager Ant subsystem (§3.4) — logic lives in ForagerSystem.gd
var forager_system: ForagerSystem = ForagerSystem.new()

# Wandering Trader state
# Each entry: {world_pos: Vector2, tier: int, pulse: float}
var _active_traders: Array = []
var _trader_last_check_row: int = 0   # last depth row where a spawn check was made
var _traders_spawned_count: int = 0   # total traders spawned this run
var _trader_shop_layer: CanvasLayer = null
var _trader_shop_visible: bool = false
var _current_trader: Dictionary = {}

# Run-length buffs granted by trader items
var _shroom_charges: int = 0       # Mining Shroom: remaining ores with doubled yield
var _lucky_compass_active: bool = false   # Lucky Compass: 2× lucky strike chance
var _ancient_map_active: bool = false     # Ancient Map: 2× sonar ping radius

# ---------------------------------------------------------------------------
# Forager Ant companion (§3.4) — logic lives in ForagerSystem.gd
# ---------------------------------------------------------------------------

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
const FARM_NPC_ROW: int = 2  # Placed on the middle surface row

var _pickaxe_texture: Texture2D

func _ready() -> void:
	_pickaxe_texture = load("res://assets/pickaxe_effect.png") as Texture2D

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
	_setup_map_barriers()

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

	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)
	QuestManager.clear_quest()
	_setup_surface_hub()
	_setup_energy_station_shop()
	_setup_upgrade_station_shop()
	_setup_smeltery_shop()
	_setup_farm_animals()

	# Apply settlement carry-over consumables (purchased at a settlement before this run)
	if GameManager.settlement_shroom_charges > 0:
		_shroom_charges += GameManager.settlement_shroom_charges
		GameManager.settlement_shroom_charges = 0
		EventBus.ore_mined_popup.emit(0, "Shroom charges ready!")
	if GameManager.settlement_mandible_bonus > 0:
		_settlement_mandible_bonus = GameManager.settlement_mandible_bonus
		GameManager.settlement_mandible_bonus = 0
	var forager_bonus: int = GameManager.get_forager_carry_bonus()
	if GameManager.settlement_forager_bonus > 0:
		forager_bonus += GameManager.settlement_forager_bonus
		GameManager.settlement_forager_bonus = 0

	# Initialise ForagerSystem near the player's starting position
	var forager_spawn := Vector2(
		(spawn_col + 2) * CELL_SIZE + CELL_SIZE * 0.5,
		spawn_row * CELL_SIZE + CELL_SIZE * 0.5
	)
	forager_system.setup(forager_spawn, forager_bonus)

	# Initialise BossSystem with grid reference and MiningLevel callbacks
	boss_system.setup(
		grid, GRID_COLS, GRID_ROWS, SURFACE_ROWS,
		func(c, r, solid): _set_tile_collision(c, r, solid),
		func(text, color): _show_zone_banner(text, color),
		func(intensity, duration): _shake_camera(intensity, duration),
		func(pos): _tile_damage.erase(pos); _tile_hits.erase(pos)
	)

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

	var reenergy_col = GRID_COLS / 2
	grid[reenergy_col][SURFACE_ROWS - 1] = TileType.REENERGY_STATION
	grid[reenergy_col - 5][SURFACE_ROWS - 1] = TileType.UPGRADE_STATION
	grid[reenergy_col + 5][SURFACE_ROWS - 1] = TileType.SMELTERY_STATION

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

	elif r < total_hazard + 0.02: return TileType.ENERGY_NODE
	elif r < total_hazard + 0.03: return TileType.ENERGY_NODE_FULL

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

			if tile == TileType.REENERGY_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color.WHITE, false, 2.0)

			if tile == TileType.UPGRADE_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(0.40, 1.00, 0.60), false, 2.0)

			if tile == TileType.SMELTERY_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(1.0, 0.55, 0.0), false, 2.0)

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
	# State is read from boss_system; draw calls remain in MiningLevel._draw()
	if boss_system.boss_active and not boss_system.boss_tile_positions.is_empty():
		var boss_pulse := sin(boss_system.boss_pulse_time * 4.5) * 0.5 + 0.5

		# Choose boss tile colours based on boss type
		var core_fill := Color(1.0, 0.05, 0.05, 0.28 + boss_pulse * 0.28)
		var core_border := Color(1.0, 0.80, 0.10, 0.50 + boss_pulse * 0.30)
		var seg_fill := Color(0.85, 0.15, 0.05, 0.18 + boss_pulse * 0.18)
		var seg_border := Color(0.70, 0.20, 0.05, 0.40 + boss_pulse * 0.25)
		match boss_system.boss_type:
			BossSystem.BOSS_TYPE_MOLE:
				core_fill   = Color(0.50, 0.30, 0.08, 0.30 + boss_pulse * 0.28)
				core_border = Color(0.80, 0.60, 0.20, 0.55 + boss_pulse * 0.30)
				seg_fill    = Color(0.40, 0.25, 0.05, 0.18 + boss_pulse * 0.18)
				seg_border  = Color(0.60, 0.40, 0.10, 0.40 + boss_pulse * 0.25)
			BossSystem.BOSS_TYPE_ANCIENT:
				# Colour shifts by phase: teal (shell) → purple (crystal) → white/gold (core)
				var ancient_phase_colors: Array = [
					[Color(0.10, 0.60, 0.80), Color(0.30, 0.90, 1.00)],  # phase 0 teal/cyan
					[Color(0.55, 0.10, 0.80), Color(0.78, 0.40, 1.00)],  # phase 1 purple/violet
					[Color(0.90, 0.90, 1.00), Color(1.00, 1.00, 0.60)],  # phase 2 white/gold
				]
				var ap := clampi(boss_system.ancient_phase, 0, ancient_phase_colors.size() - 1)
				core_fill   = Color(ancient_phase_colors[ap][0], 0.35 + boss_pulse * 0.30)
				core_border = Color(ancient_phase_colors[ap][1], 0.60 + boss_pulse * 0.30)
				seg_fill    = Color(ancient_phase_colors[ap][0], 0.20 + boss_pulse * 0.20)
				seg_border  = Color(ancient_phase_colors[ap][1], 0.45 + boss_pulse * 0.25)
			BossSystem.BOSS_TYPE_GOLEM:
				# Colour shifts with each armor phase
				var phase_colors: Array = [
					[Color(0.80, 0.50, 0.20), Color(0.95, 0.70, 0.40)],  # copper phase
					[Color(0.55, 0.55, 0.65), Color(0.75, 0.75, 0.90)],  # iron phase
					[Color(1.00, 0.85, 0.10), Color(1.00, 1.00, 0.50)],  # gold phase
				]
				var pi := clampi(boss_system.golem_phase, 0, phase_colors.size() - 1)
				core_fill   = Color(phase_colors[pi][0], 0.30 + boss_pulse * 0.28)
				core_border = Color(phase_colors[pi][1], 0.55 + boss_pulse * 0.30)
				seg_fill    = Color(phase_colors[pi][0], 0.18 + boss_pulse * 0.18)
				seg_border  = Color(phase_colors[pi][1], 0.40 + boss_pulse * 0.25)

		for bp in boss_system.boss_tile_positions:
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

		# Boss energy-drain warning — red vignette flicker on screen edges
		if boss_pulse > 0.75:
			var vignette_a := (boss_pulse - 0.75) / 0.25 * 0.12
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 4), Color(1.0, 0.0, 0.0, vignette_a))
			draw_rect(Rect2(min_col * CELL_SIZE, max_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 4), Color(1.0, 0.0, 0.0, vignette_a))

		# Blind Mole: tremor warning overlay — brown screen-edge pulse
		if boss_system.boss_type == BossSystem.BOSS_TYPE_MOLE and boss_system.mole_tremor_warning_active:
			var warn_ratio := 1.0 - (boss_system.mole_tremor_warning_timer / BossSystem.MOLE_TREMOR_WARNING)
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

		# Giant Rat: charge warning overlay — red/orange screen-edge pulse
		if boss_system.boss_type == BossSystem.BOSS_TYPE_GIANT_RAT and boss_system.rat_charge_warning_active:
			var rat_ratio := 1.0 - (boss_system.rat_charge_warning_timer / BossSystem.RAT_CHARGE_WARNING)
			var rat_a := rat_ratio * 0.40
			var rat_color := Color(0.90, 0.20, 0.05, rat_a)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), rat_color)
			draw_rect(Rect2(min_col * CELL_SIZE, max_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), rat_color)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), rat_color)
			draw_rect(Rect2(max_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), rat_color)

		# Void Spider: web warning — green screen-edge pulse + target indicator
		if boss_system.boss_type == BossSystem.BOSS_TYPE_SPIDER and boss_system.spider_web_warning_active:
			var web_ratio := 1.0 - (boss_system.spider_web_warning_timer / BossSystem.SPIDER_WEB_WARNING)
			var web_a := web_ratio * 0.40
			var web_color := Color(0.30, 0.80, 0.20, web_a)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), web_color)
			draw_rect(Rect2(min_col * CELL_SIZE, max_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), web_color)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), web_color)
			draw_rect(Rect2(max_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), web_color)
			# Draw target zone indicator so the player can dodge
			var wt := boss_system.spider_web_target_pos
			if wt.x >= 0:
				var web_pulse := sin(boss_system.boss_pulse_time * 8.0) * 0.5 + 0.5
				var web_zone := Rect2(
					(wt.x - BossSystem.SPIDER_WEB_RADIUS) * CELL_SIZE,
					(wt.y - BossSystem.SPIDER_WEB_RADIUS) * CELL_SIZE,
					(BossSystem.SPIDER_WEB_RADIUS * 2 + 1) * CELL_SIZE,
					(BossSystem.SPIDER_WEB_RADIUS * 2 + 1) * CELL_SIZE)
				draw_rect(web_zone, Color(0.30, 0.80, 0.20, 0.15 + web_pulse * 0.20), false, 2.0)

		# Stone Golem: show required ore type indicator near the golem core
		if boss_system.boss_type == BossSystem.BOSS_TYPE_GOLEM \
				and boss_system.golem_phase < BossSystem.GOLEM_PHASE_ORES.size():
			var golem_label := "Mine: " + BossSystem.GOLEM_PHASE_ORES[boss_system.golem_phase].capitalize()
			var label_px := Vector2(-9999.0, -9999.0)
			for bp2 in boss_system.boss_tile_positions:
				if bp2.x >= 0 and bp2.x < GRID_COLS \
						and bp2.y >= 0 and bp2.y < GRID_ROWS \
						and grid[bp2.x][bp2.y] == TileType.BOSS_CORE:
					label_px = Vector2(bp2.x * CELL_SIZE - 40, bp2.y * CELL_SIZE - 22)
					break
			if label_px.x > -9000.0:
				var gfont := ThemeDB.fallback_font
				draw_string(gfont, label_px, golem_label,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1.0, 0.95, 0.50, 0.90))

		# Ancient One: void-pulse warning — purple screen-edge pulse (phase 2)
		if boss_system.boss_type == BossSystem.BOSS_TYPE_ANCIENT \
				and boss_system.ancient_void_warning_active:
			var void_ratio := 1.0 - (boss_system.ancient_void_warning_timer / BossSystem.ANCIENT_VOID_PULSE_WARNING)
			var void_a := void_ratio * 0.45
			var void_color := Color(0.50, 0.05, 0.80, void_a)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), void_color)
			draw_rect(Rect2(min_col * CELL_SIZE, max_row * CELL_SIZE,
				(max_col - min_col + 1) * CELL_SIZE, 8), void_color)
			draw_rect(Rect2(min_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), void_color)
			draw_rect(Rect2(max_col * CELL_SIZE, min_row * CELL_SIZE,
				8, (max_row - min_row + 1) * CELL_SIZE), void_color)

		# Ancient One: core recharge warning — white pulsing ring around the core (phase 3)
		if boss_system.boss_type == BossSystem.BOSS_TYPE_ANCIENT \
				and boss_system.ancient_core_recharge_warning:
			for bp3 in boss_system.boss_tile_positions:
				if bp3.x >= 0 and bp3.x < GRID_COLS \
						and bp3.y >= 0 and bp3.y < GRID_ROWS \
						and grid[bp3.x][bp3.y] == TileType.BOSS_CORE:
					var recharge_a := (sin(boss_system.boss_pulse_time * 9.0) * 0.5 + 0.5) * 0.50
					var ring_rect := Rect2(
						(bp3.x - 2) * CELL_SIZE, (bp3.y - 2) * CELL_SIZE,
						5 * CELL_SIZE, 5 * CELL_SIZE)
					draw_rect(ring_rect, Color(1.0, 1.0, 0.80, recharge_a), false, 3.0)
					break

		# Ancient One: phase label near core
		if boss_system.boss_type == BossSystem.BOSS_TYPE_ANCIENT:
			var ancient_phase_labels := ["SHELL PHASE", "CRYSTAL PHASE", "CORE PHASE"]
			var al = ancient_phase_labels[clampi(boss_system.ancient_phase, 0, ancient_phase_labels.size() - 1)]
			var label_px2 := Vector2(-9999.0, -9999.0)
			for bp4 in boss_system.boss_tile_positions:
				if bp4.x >= 0 and bp4.x < GRID_COLS \
						and bp4.y >= 0 and bp4.y < GRID_ROWS \
						and grid[bp4.x][bp4.y] == TileType.BOSS_CORE:
					label_px2 = Vector2(bp4.x * CELL_SIZE - 44, bp4.y * CELL_SIZE - 22)
					break
			if label_px2.x > -9000.0:
				var afont := ThemeDB.fallback_font
				draw_string(afont, label_px2, al,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.80, 0.55, 1.00, 0.90))

	# Scout Cat companion — amber circle with carry indicator (§3.4)
	# State is read from forager_system; draw calls remain in MiningLevel._draw()
	var fg := forager_system.world_pos
	var fg_col := floori(fg.x / CELL_SIZE)
	var fg_row := floori(fg.y / CELL_SIZE)
	if fg_col >= min_col - 1 and fg_col <= max_col + 1 and fg_row >= min_row - 1 and fg_row <= max_row + 1:
		var carry_ratio := float(forager_system.carry) / float(max(forager_system.capacity, 1))
		var forager_color: Color
		match forager_system.state:
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
	# State is read from sonar_system; draw calls remain in MiningLevel._draw()
	if sonar_system.ping_active and sonar_system.ping_center.x >= 0:
		var ping_alpha := 1.0 - sonar_system.ping_elapsed / SonarSystem.PING_DURATION
		var max_radius := GameManager.get_sonar_ping_radius()
		var cx := sonar_system.ping_center.x
		var cy := sonar_system.ping_center.y
		var scan_r := int(max_radius) + 2
		# Glow each ore tile that the expanding wave has already swept over
		for sc in range(maxi(min_col, cx - scan_r), mini(max_col + 1, cx + scan_r + 1)):
			for sr in range(maxi(min_row, cy - scan_r), mini(max_row + 1, cy + scan_r + 1)):
				var stile: int = grid[sc][sr]
				if stile != TileType.ORE_COPPER and stile != TileType.ORE_COPPER_DEEP \
				and stile != TileType.ORE_IRON and stile != TileType.ORE_IRON_DEEP \
				and stile != TileType.ORE_GOLD and stile != TileType.ORE_GOLD_DEEP \
				and stile != TileType.ORE_GEM and stile != TileType.ORE_GEM_DEEP \
				and stile != TileType.ENERGY_NODE and stile != TileType.ENERGY_NODE_FULL:
					continue
				var dist := Vector2(sc - cx, sr - cy).length()
				if dist > sonar_system.wave_radius:
					continue
				# Glow age: how far behind the wave front this tile is
				var glow_age := sonar_system.wave_radius - dist
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
					elif stile == TileType.ENERGY_NODE or stile == TileType.ENERGY_NODE_FULL:
						glow_color = Color(0.30, 1.00, 0.30, glow_alpha)
				draw_rect(Rect2(sc * CELL_SIZE, sr * CELL_SIZE, CELL_SIZE, CELL_SIZE), glow_color)
		# Expanding wave ring arc
		var wave_px := sonar_system.wave_radius * CELL_SIZE
		var center_px := Vector2(cx * CELL_SIZE + CELL_SIZE * 0.5, cy * CELL_SIZE + CELL_SIZE * 0.5)
		if wave_px > 0:
			draw_arc(center_px, wave_px, 0.0, TAU, 48, Color(0.40, 1.0, 0.60, ping_alpha * 0.55), 2.0)

# ---------------------------------------------------------------------------
# Process — energy drain, cursor highlight, flashes
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

	# Update sonar ping wave (§3.2) — delegated to SonarSystem
	sonar_system.update(delta, 2.0 if _ancient_map_active else 1.0)

	# Pulse wandering traders and boss system regardless of menu state
	for trader in _active_traders:
		trader["pulse"] += delta
	var _boss_pcol := floori(player_node.global_position.x / CELL_SIZE) if player_node else -1
	var _boss_prow := floori(player_node.global_position.y / CELL_SIZE) if player_node else -1
	boss_system.update(delta, _boss_pcol, _boss_prow)

	# Update forager regardless of menu state so it can animate returning home
	var _surface_deposit_pos := Vector2(46.0 * CELL_SIZE, (SURFACE_ROWS - 1) * CELL_SIZE + CELL_SIZE * 0.5)
	forager_system.update(delta, player_node.global_position if player_node else Vector2.ZERO, _surface_deposit_pos)
	if forager_system.sweep_due:
		_forager_do_sweep()

	if _hub_visible or _game_over or _energy_shop_visible or _trader_shop_visible or _smeltery_visible:
		return

	# Update cursor highlight
	_update_cursor_highlight()

	# Update camera to follow player
	_update_camera()

	# Update depth tracking
	_update_depth()

	# Check interact prompt (reenergy station, farm NPCs)
	_update_interact_prompt()

	# Check if player reached exit zone
	_check_exit_zone()

	# Hazard cooldown
	if _hazard_cooldown > 0.0:
		_hazard_cooldown -= delta

	# Time-based energy drain (only underground)
	if player_node:
		var depth_row := player_node.get_depth_row()
		if depth_row > 0:
			var depth_ratio := float(depth_row) / float(GRID_ROWS - SURFACE_ROWS)
			var boss_mult := boss_system.get_energy_drain_mult()
			var drain_rate := (ENERGY_DRAIN_BASE + depth_ratio * ENERGY_DRAIN_DEPTH_MULT) * boss_mult
			_energy_drain_accum += drain_rate * delta
			if _energy_drain_accum >= 1.0:
				var drain_amount := int(_energy_drain_accum)
				_energy_drain_accum -= float(drain_amount)
				if not GameManager.consume_energy(drain_amount):
					_on_out_of_energy()

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
		_game_over = true
		GameManager.complete_run()
	# Reaching the bottom of the map also counts as a completed run
	elif player_row >= GRID_ROWS - 1:
		_game_over = true
		GameManager.complete_run()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _hub_visible or _game_over or _energy_shop_visible or _trader_shop_visible or _smeltery_visible:
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
		if player_node:
			sonar_system.try_ping(player_node.get_grid_pos())

# ---------------------------------------------------------------------------
# Pickaxe throw effect — spawns a pickaxe sprite that flies to the target
# ---------------------------------------------------------------------------

func _spawn_pickaxe_effect(from: Vector2, to: Vector2) -> void:
	if not _pickaxe_texture:
		return
	var sprite := Sprite2D.new()
	sprite.texture = _pickaxe_texture
	sprite.position = from
	sprite.scale = Vector2(0.5, 0.5)
	sprite.rotation = from.angle_to_point(to) + PI * 0.25
	sprite.texture_filter = TEXTURE_FILTER_NEAREST
	add_child(sprite)
	var dist := from.distance_to(to)
	var duration := clampf(dist / 800.0, 0.06, 0.18)
	var tween := create_tween()
	tween.tween_property(sprite, "position", to, duration)
	tween.tween_callback(sprite.queue_free)

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

	# Pickaxe throw effect — flies from player to clicked tile
	if player_node:
		var target_world := Vector2(col * CELL_SIZE + CELL_SIZE * 0.5, row * CELL_SIZE + CELL_SIZE * 0.5)
		_spawn_pickaxe_effect(player_node.global_position, target_world)

	# Energy nodes — collect immediately
	if tile == TileType.ENERGY_NODE or tile == TileType.ENERGY_NODE_FULL:
		_mine_cell(col, row)
		GameManager.restore_energy(10)
		EventBus.ore_mined_popup.emit(10, "Energy")
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

	# Reenergy station / Exit station / Upgrade station / Smeltery — not mineable
	if tile == TileType.REENERGY_STATION or tile == TileType.EXIT_STATION or tile == TileType.UPGRADE_STATION or tile == TileType.SMELTERY_STATION:
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
		_mine_cell(col, row)
		# Boss tile tracking — delegated to BossSystem
		if tile == TileType.BOSS_SEGMENT or tile == TileType.BOSS_CORE:
			boss_system.on_tile_mined(col, row, tile)
		# Gem tile: award a gem item immediately on mining (primary value)
		if tile == TileType.ORE_GEM or tile == TileType.ORE_GEM_DEEP:
			var gems_gained := 2 if tile == TileType.ORE_GEM_DEEP else 1
			GameManager.gem_count += gems_gained
			GameManager.save_game()
			EventBus.ore_mined_popup.emit(gems_gained, "Gem collected!")
		if tile in MINEABLE_TILES:
			var minerals: int = roundi(TILE_MINERALS.get(tile, 1) * GameManager.get_mineral_yield_mult())
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
				EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
				var popup_label: String = "LUCKY!" if lucky else TILE_NAMES.get(tile, "Mineral")
				EventBus.ore_mined_popup.emit(minerals, popup_label)
			# Non-ore tiles (dirt, stone, grass) give no minerals.
			_check_streak_milestone()
		SoundManager.play_drill_sound()
	else:
		_tile_damage[pos_key] = new_damage
		_tile_hits[pos_key] = hits_so_far + 1
		SoundManager.play_impact_sound()
		_shake_camera(1.5, 0.07)

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
	var r := 1 + GameManager.get_explosive_radius_bonus()
	for dc in range(-r, r + 1):
		for dr in range(-r, r + 1):
			var nc := center_col + dc
			var nr := center_row + dr
			if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
				var tile: int = grid[nc][nr]
				if tile in ORE_TILES:
					var minerals: int = roundi(TILE_MINERALS.get(tile, 1) * GameManager.get_mineral_yield_mult())
					var world_pos := Vector2(nc * CELL_SIZE + CELL_SIZE * 0.5, nr * CELL_SIZE + CELL_SIZE * 0.5)
					_spawn_ore_chunks(tile, minerals, world_pos)
					GameManager.track_ore_mined(tile, minerals)
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
	_show_game_over_overlay("LOST IN SPACE", "Run stardust has been lost...")
	await get_tree().create_timer(2.5).timeout
	GameManager.lose_run()

func _on_out_of_energy() -> void:
	if _game_over:
		return
	_game_over = true
	_show_game_over_overlay("OUT OF FUEL", "Run stardust has been lost...")
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
	if not player_node:
		return
	var depth: int = player_node.get_depth_row()
	if depth != _last_depth:
		_last_depth = depth
		EventBus.depth_changed.emit(depth)
		_check_zone_transition(depth)
		_check_trader_milestone(depth)
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
			_show_zone_banner(DEPTH_ZONE_NAMES[new_zone_idx], DEPTH_ZONE_COLORS[new_zone_idx])
			if new_zone_idx > 0 and not _zones_discovered[new_zone_idx]:
				_zones_discovered[new_zone_idx] = true
				const DISCOVERY_ENERGY := 20
				GameManager.restore_energy(DISCOVERY_ENERGY)
				EventBus.ore_mined_popup.emit(DISCOVERY_ENERGY, "Discovery!")

func _show_zone_banner(zone_name: String, color: Color) -> void:
	const VW: int = 1280
	const VH: int = 720
	const BANNER_H: int = 52
	var layer := CanvasLayer.new()
	layer.layer = 15
	add_child(layer)
	var banner := ColorRect.new()
	banner.size = Vector2(VW, BANNER_H)
	banner.position = Vector2(0, VH * 2 / 3 - BANNER_H / 2)
	banner.color = Color(0.0, 0.0, 0.0, 0.78)
	layer.add_child(banner)
	var label := Label.new()
	label.text = zone_name.to_upper()
	label.size = Vector2(VW, BANNER_H)
	label.position = Vector2(0, VH * 2 / 3 - BANNER_H / 2)
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
		if current_tile == TileType.REENERGY_STATION:
			var key_name := _get_interact_key_name()
			player_node.show_prompt("Press %s to open shop" % key_name)
			var world_pos := Vector2(player_gp.x * CELL_SIZE + CELL_SIZE * 0.5, player_gp.y * CELL_SIZE)
			var screen_pos := get_viewport().get_canvas_transform() * world_pos
			player_node.set_prompt_position(screen_pos)
			return
		if current_tile == TileType.UPGRADE_STATION:
			var key_name := _get_interact_key_name()
			player_node.show_prompt("Press %s to upgrade" % key_name)
			var world_pos := Vector2(player_gp.x * CELL_SIZE + CELL_SIZE * 0.5, player_gp.y * CELL_SIZE)
			var screen_pos := get_viewport().get_canvas_transform() * world_pos
			player_node.set_prompt_position(screen_pos)
			return
		if current_tile == TileType.SMELTERY_STATION:
			var key_name := _get_interact_key_name()
			player_node.show_prompt("Press %s to open smeltery" % key_name)
			var world_pos := Vector2(player_gp.x * CELL_SIZE + CELL_SIZE * 0.5, player_gp.y * CELL_SIZE)
			var screen_pos := get_viewport().get_canvas_transform() * world_pos
			player_node.set_prompt_position(screen_pos)
			return
	# Check adjacent tiles for reenergy station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.REENERGY_STATION:
				var key_name := _get_interact_key_name()
				player_node.show_prompt("Press %s to open shop" % key_name)
				var world_pos := Vector2(check.x * CELL_SIZE + CELL_SIZE * 0.5, check.y * CELL_SIZE)
				var screen_pos := get_viewport().get_canvas_transform() * world_pos
				player_node.set_prompt_position(screen_pos)
				return
	# Check adjacent tiles for upgrade station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.UPGRADE_STATION:
				var key_name := _get_interact_key_name()
				player_node.show_prompt("Press %s to upgrade" % key_name)
				var world_pos := Vector2(check.x * CELL_SIZE + CELL_SIZE * 0.5, check.y * CELL_SIZE)
				var screen_pos := get_viewport().get_canvas_transform() * world_pos
				player_node.set_prompt_position(screen_pos)
				return
	# Check adjacent tiles for smeltery station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.SMELTERY_STATION:
				var key_name := _get_interact_key_name()
				player_node.show_prompt("Press %s to open smeltery" % key_name)
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
	var player_pos := player_node.global_position
	for npc in _farm_npcs:
		if npc.global_position.distance_to(player_pos) <= CELL_SIZE * 2:
			return npc
	return null

func _try_interact() -> void:
	if not player_node:
		return
	# Wandering Trader takes priority when in range
	var nearby_trader := _get_nearby_trader()
	if nearby_trader.size() > 0:
		_show_trader_shop(nearby_trader)
		return
	# Check current + adjacent tiles for reenergy station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.REENERGY_STATION:
				_show_energy_station_shop()
				return
	# Check current + adjacent tiles for upgrade station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.UPGRADE_STATION:
				_show_upgrade_station_shop()
				return
	# Check current + adjacent tiles for smeltery station
	for offset in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x >= 0 and check.x < GRID_COLS and check.y >= 0 and check.y < GRID_ROWS:
			if grid[check.x][check.y] == TileType.SMELTERY_STATION:
				_show_smeltery_shop()
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
	var animals := [
		{"name": "Chicken", "texture_path": "res://assets/creatures/chicken_spritesheet.png", "col": 4},
		{"name": "Sheep",   "texture_path": "res://assets/creatures/sheep_spritesheet.png",   "col": 8},
		{"name": "Pig",     "texture_path": "res://assets/creatures/pig_spritesheet.png",     "col": 12},
	]
	var bounce_left := 1.0 * CELL_SIZE
	var bounce_right := 20.0 * CELL_SIZE
	for a in animals:
		var npc := npc_scene.instantiate() as FarmAnimalNPC
		npc.animal_name = a["name"]
		var tex := load(a["texture_path"]) as Texture2D
		if tex:
			var spr := npc.get_node("Sprite2D") as Sprite2D
			spr.texture = tex
			spr.hframes = 2
			spr.frame = 0
		npc.scale = Vector2(2.0, 2.0)
		npc.position = Vector2(
			a["col"] * CELL_SIZE + CELL_SIZE * 0.5,
			FARM_NPC_ROW * CELL_SIZE + CELL_SIZE * 0.5
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
	title.text = "You reached the station!"
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
	bank_btn.text = "Bank Minerals & Keep Exploring"
	bank_btn.position = Vector2(BTN_X, PY + 100)
	bank_btn.size = Vector2(BTN_W, BTN_H)
	bank_btn.pressed.connect(_hub_bank_and_continue)
	_hub_layer.add_child(bank_btn)

	var shop_btn := Button.new()
	shop_btn.text = "Open Station Shop (banks minerals)"
	shop_btn.position = Vector2(BTN_X, PY + 156)
	shop_btn.size = Vector2(BTN_W, BTN_H)
	shop_btn.pressed.connect(_hub_open_shop)
	_hub_layer.add_child(shop_btn)

	var end_btn := Button.new()
	end_btn.text = "End Run & Return to Station"
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
# Energy Station Shop
# ---------------------------------------------------------------------------

const SHOP_REENERGY_FULL_COST: int = 10
const SHOP_REENERGY_HALF_COST: int = 5
const SHOP_REPAIR_COST: int = 15

func _setup_energy_station_shop() -> void:
	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 420
	const PANEL_H: int = 330
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_energy_shop_layer = CanvasLayer.new()
	_energy_shop_layer.layer = 10
	_energy_shop_layer.visible = false
	add_child(_energy_shop_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_energy_shop_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.20, 0.60, 0.90, 1.0)
	_energy_shop_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.07, 0.10, 0.14, 0.97)
	_energy_shop_layer.add_child(panel)

	var title := Label.new()
	title.text = "Refueling Dock"
	title.position = Vector2(PX, PY + 12)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.55, 0.85, 1.0)
	_energy_shop_layer.add_child(title)

	_energy_shop_minerals_label = Label.new()
	_energy_shop_minerals_label.position = Vector2(PX, PY + 48)
	_energy_shop_minerals_label.size = Vector2(PANEL_W, 24)
	_energy_shop_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_shop_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_energy_shop_layer.add_child(_energy_shop_minerals_label)

	var divider := ColorRect.new()
	divider.position = Vector2(PX + 20, PY + 80)
	divider.size = Vector2(PANEL_W - 40, 2)
	divider.color = Color(0.20, 0.60, 0.90, 0.5)
	_energy_shop_layer.add_child(divider)

	const BTN_X: int = PX + 25
	const BTN_W: int = PANEL_W - 50
	const BTN_H: int = 48

	_energy_shop_btn_reenergy_full = Button.new()
	_energy_shop_btn_reenergy_full.position = Vector2(BTN_X, PY + 94)
	_energy_shop_btn_reenergy_full.size = Vector2(BTN_W, BTN_H)
	_energy_shop_btn_reenergy_full.pressed.connect(_shop_reenergy_full)
	_energy_shop_layer.add_child(_energy_shop_btn_reenergy_full)

	_energy_shop_btn_reenergy_half = Button.new()
	_energy_shop_btn_reenergy_half.position = Vector2(BTN_X, PY + 152)
	_energy_shop_btn_reenergy_half.size = Vector2(BTN_W, BTN_H)
	_energy_shop_btn_reenergy_half.pressed.connect(_shop_reenergy_half)
	_energy_shop_layer.add_child(_energy_shop_btn_reenergy_half)

	_energy_shop_btn_repair = Button.new()
	_energy_shop_btn_repair.position = Vector2(BTN_X, PY + 210)
	_energy_shop_btn_repair.size = Vector2(BTN_W, BTN_H)
	_energy_shop_btn_repair.pressed.connect(_shop_repair)
	_energy_shop_layer.add_child(_energy_shop_btn_repair)

	var divider2 := ColorRect.new()
	divider2.position = Vector2(PX + 20, PY + 268)
	divider2.size = Vector2(PANEL_W - 40, 2)
	divider2.color = Color(0.20, 0.60, 0.90, 0.5)
	_energy_shop_layer.add_child(divider2)

	var close_btn := Button.new()
	close_btn.text = "Close Shop"
	close_btn.position = Vector2(BTN_X + (BTN_W - 180) / 2, PY + 278)
	close_btn.size = Vector2(180, 40)
	close_btn.pressed.connect(_hide_energy_station_shop)
	_energy_shop_layer.add_child(close_btn)

func _show_energy_station_shop() -> void:
	_energy_shop_minerals_label.text = "Dollars: $%d" % GameManager.dollars
	_energy_shop_btn_reenergy_full.text = "Full Refuel  (%d -> %d fuel)  -- $%d" % [
		GameManager.current_energy, GameManager.get_max_energy(), SHOP_REENERGY_FULL_COST]
	_energy_shop_btn_reenergy_half.text = "Refuel 50%%  (+%d fuel)  -- $%d" % [
		GameManager.get_max_energy() / 2, SHOP_REENERGY_HALF_COST]
	_energy_shop_btn_repair.text = "Spacesuit Repair  (+1 HP)  -- $%d" % SHOP_REPAIR_COST
	_energy_shop_btn_reenergy_full.disabled = GameManager.dollars < SHOP_REENERGY_FULL_COST \
		or GameManager.current_energy >= GameManager.get_max_energy()
	_energy_shop_btn_reenergy_half.disabled = GameManager.dollars < SHOP_REENERGY_HALF_COST \
		or GameManager.current_energy >= GameManager.get_max_energy()
	var at_max_hp: bool = player_node != null and player_node.is_at_max_health()
	_energy_shop_btn_repair.disabled = GameManager.dollars < SHOP_REPAIR_COST or at_max_hp
	_energy_shop_layer.visible = true
	_energy_shop_visible = true

func _hide_energy_station_shop() -> void:
	_energy_shop_layer.visible = false
	_energy_shop_visible = false

func _shop_reenergy_full() -> void:
	if GameManager.dollars >= SHOP_REENERGY_FULL_COST:
		GameManager.dollars -= SHOP_REENERGY_FULL_COST
		GameManager.current_energy = GameManager.get_max_energy()
		EventBus.dollars_changed.emit(GameManager.dollars)
		EventBus.energy_changed.emit(GameManager.current_energy, GameManager.get_max_energy())
		GameManager.save_game()
		SoundManager.play_drill_sound()
		_show_energy_station_shop()

func _shop_reenergy_half() -> void:
	if GameManager.dollars >= SHOP_REENERGY_HALF_COST:
		GameManager.dollars -= SHOP_REENERGY_HALF_COST
		GameManager.restore_energy(GameManager.get_max_energy() / 2)
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.save_game()
		SoundManager.play_drill_sound()
		_show_energy_station_shop()

func _shop_repair() -> void:
	if GameManager.dollars >= SHOP_REPAIR_COST and player_node:
		GameManager.dollars -= SHOP_REPAIR_COST
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.save_game()
		player_node.heal(1)
		SoundManager.play_drill_sound()
		_show_energy_station_shop()

# ---------------------------------------------------------------------------
# Upgrade Station Shop
# ---------------------------------------------------------------------------

func _setup_upgrade_station_shop() -> void:
	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 500
	const PANEL_H: int = 360
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_upgrade_station_layer = CanvasLayer.new()
	_upgrade_station_layer.layer = 10
	_upgrade_station_layer.visible = false
	add_child(_upgrade_station_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_station_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.30, 0.85, 0.50, 1.0)
	_upgrade_station_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.07, 0.12, 0.09, 0.97)
	_upgrade_station_layer.add_child(panel)

	var title := Label.new()
	title.text = "Upgrade Bay"
	title.position = Vector2(PX, PY + 12)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.55, 1.0, 0.70)
	_upgrade_station_layer.add_child(title)

	_upgrade_station_minerals_label = Label.new()
	_upgrade_station_minerals_label.position = Vector2(PX, PY + 48)
	_upgrade_station_minerals_label.size = Vector2(PANEL_W, 24)
	_upgrade_station_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_station_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_upgrade_station_layer.add_child(_upgrade_station_minerals_label)

	var divider := ColorRect.new()
	divider.position = Vector2(PX + 20, PY + 80)
	divider.size = Vector2(PANEL_W - 40, 2)
	divider.color = Color(0.30, 0.85, 0.50, 0.5)
	_upgrade_station_layer.add_child(divider)

	const BTN_X: int = PX + 25
	const BTN_W: int = PANEL_W - 50
	const BTN_H: int = 52

	_upgrade_station_btn_carapace = Button.new()
	_upgrade_station_btn_carapace.position = Vector2(BTN_X, PY + 94)
	_upgrade_station_btn_carapace.size = Vector2(BTN_W, BTN_H)
	_upgrade_station_btn_carapace.pressed.connect(_upgrade_station_buy_carapace)
	_upgrade_station_layer.add_child(_upgrade_station_btn_carapace)

	_upgrade_station_btn_legs = Button.new()
	_upgrade_station_btn_legs.position = Vector2(BTN_X, PY + 156)
	_upgrade_station_btn_legs.size = Vector2(BTN_W, BTN_H)
	_upgrade_station_btn_legs.pressed.connect(_upgrade_station_buy_legs)
	_upgrade_station_layer.add_child(_upgrade_station_btn_legs)

	_upgrade_station_btn_mandibles = Button.new()
	_upgrade_station_btn_mandibles.position = Vector2(BTN_X, PY + 218)
	_upgrade_station_btn_mandibles.size = Vector2(BTN_W, BTN_H)
	_upgrade_station_btn_mandibles.pressed.connect(_upgrade_station_buy_mandibles)
	_upgrade_station_layer.add_child(_upgrade_station_btn_mandibles)

	var divider2 := ColorRect.new()
	divider2.position = Vector2(PX + 20, PY + 282)
	divider2.size = Vector2(PANEL_W - 40, 2)
	divider2.color = Color(0.30, 0.85, 0.50, 0.5)
	_upgrade_station_layer.add_child(divider2)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(BTN_X + (BTN_W - 180) / 2, PY + 292)
	close_btn.size = Vector2(180, 40)
	close_btn.pressed.connect(_hide_upgrade_station_shop)
	_upgrade_station_layer.add_child(close_btn)

func _show_upgrade_station_shop() -> void:
	_upgrade_station_minerals_label.text = "Dollars: $%d" % GameManager.dollars

	var carapace_cost := 50 + 25 * GameManager.carapace_level
	var current_hp := GameManager.get_max_health()
	_upgrade_station_btn_carapace.text = "Reinforce Spacesuit Lv%d — Max HP: %d → %d  ($%d)" % [
		GameManager.carapace_level, current_hp, current_hp + 1, carapace_cost]
	_upgrade_station_btn_carapace.disabled = GameManager.dollars < carapace_cost

	var legs_cost := 50 + 25 * GameManager.legs_level
	var current_energy_cap := GameManager.get_max_energy()
	_upgrade_station_btn_legs.text = "Upgrade Jet Boots Lv%d — Fuel Limit: %d → %d  ($%d)" % [
		GameManager.legs_level, current_energy_cap, current_energy_cap + 25, legs_cost]
	_upgrade_station_btn_legs.disabled = GameManager.dollars < legs_cost

	var mandibles_cost := 50 + 25 * GameManager.mandibles_level
	var current_power := GameManager.get_mandibles_power()
	_upgrade_station_btn_mandibles.text = "Enhance Space Pickaxe Lv%d — Mining Power: %d → %d  ($%d)" % [
		GameManager.mandibles_level, current_power, current_power + 3, mandibles_cost]
	_upgrade_station_btn_mandibles.disabled = GameManager.dollars < mandibles_cost

	_upgrade_station_layer.visible = true
	_upgrade_station_visible = true

func _hide_upgrade_station_shop() -> void:
	_upgrade_station_layer.visible = false
	_upgrade_station_visible = false

func _upgrade_station_buy_carapace() -> void:
	var cost := 50 + 25 * GameManager.carapace_level
	if GameManager.dollars >= cost:
		GameManager.dollars -= cost
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.upgrade_carapace()
		SoundManager.play_drill_sound()
		_show_upgrade_station_shop()

func _upgrade_station_buy_legs() -> void:
	var cost := 50 + 25 * GameManager.legs_level
	if GameManager.dollars >= cost:
		GameManager.dollars -= cost
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.upgrade_legs()
		EventBus.energy_changed.emit(GameManager.current_energy, GameManager.get_max_energy())
		SoundManager.play_drill_sound()
		_show_upgrade_station_shop()

func _upgrade_station_buy_mandibles() -> void:
	var cost := 50 + 25 * GameManager.mandibles_level
	if GameManager.dollars >= cost:
		GameManager.dollars -= cost
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.upgrade_mandibles()
		SoundManager.play_drill_sound()
		_show_upgrade_station_shop()

# ---------------------------------------------------------------------------
# Smeltery Shop
# ---------------------------------------------------------------------------

func _get_ore_group_count(ore_group: String) -> int:
	var total := 0
	for tile_type in SMELTERY_ORE_GROUP_TILES[ore_group]:
		total += _run_ore_counts.get(tile_type, 0)
	return total

func _consume_ores_for_smelt(ore_group: String, count: int) -> void:
	var remaining := count
	for tile_type in SMELTERY_ORE_GROUP_TILES[ore_group]:
		var have: int = _run_ore_counts.get(tile_type, 0)
		if have <= 0:
			continue
		var take := mini(have, remaining)
		_run_ore_counts[tile_type] = have - take
		remaining -= take
		if remaining <= 0:
			break

func _setup_smeltery_shop() -> void:
	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 520
	const PANEL_H: int = 420
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_smeltery_layer = CanvasLayer.new()
	_smeltery_layer.layer = 10
	_smeltery_layer.visible = false
	add_child(_smeltery_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_smeltery_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(1.0, 0.55, 0.0, 1.0)
	_smeltery_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.12, 0.08, 0.04, 0.97)
	_smeltery_layer.add_child(panel)

	var title := Label.new()
	title.text = "Space Forge"
	title.position = Vector2(PX, PY + 10)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.65, 0.15)
	_smeltery_layer.add_child(title)

	_smeltery_minerals_label = Label.new()
	_smeltery_minerals_label.position = Vector2(PX, PY + 40)
	_smeltery_minerals_label.size = Vector2(PANEL_W, 22)
	_smeltery_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_smeltery_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_smeltery_layer.add_child(_smeltery_minerals_label)

	var divider := ColorRect.new()
	divider.position = Vector2(PX + 15, PY + 68)
	divider.size = Vector2(PANEL_W - 30, 2)
	divider.color = Color(1.0, 0.55, 0.0, 0.5)
	_smeltery_layer.add_child(divider)

	# Header row
	var hdr_ores := Label.new()
	hdr_ores.text = "Ores"
	hdr_ores.position = Vector2(PX + 15, PY + 76)
	hdr_ores.size = Vector2(80, 20)
	hdr_ores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_ores.modulate = Color(0.8, 0.8, 0.8)
	_smeltery_layer.add_child(hdr_ores)

	var hdr_bars := Label.new()
	hdr_bars.text = "Bars"
	hdr_bars.position = Vector2(PX + 260, PY + 76)
	hdr_bars.size = Vector2(80, 20)
	hdr_bars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr_bars.modulate = Color(0.8, 0.8, 0.8)
	_smeltery_layer.add_child(hdr_bars)

	# Per-ore-group rows: [OreLabel] [SmeltBtn] [BarLabel] [SellBtn]
	var row_y := PY + 100
	const ROW_H: int = 58
	for ore_group in SMELTERY_ORE_GROUPS_ORDER:
		var group_color: Color = SMELTERY_GROUP_COLORS[ore_group]

		var ore_label := Label.new()
		ore_label.position = Vector2(PX + 15, row_y + 4)
		ore_label.size = Vector2(90, 24)
		ore_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ore_label.modulate = group_color
		_smeltery_layer.add_child(ore_label)
		_smeltery_ore_labels[ore_group] = ore_label

		var smelt_btn := Button.new()
		smelt_btn.position = Vector2(PX + 110, row_y)
		smelt_btn.size = Vector2(140, 36)
		smelt_btn.pressed.connect(_smeltery_smelt.bind(ore_group))
		_smeltery_layer.add_child(smelt_btn)
		_smeltery_smelt_btns[ore_group] = smelt_btn

		var bar_label := Label.new()
		bar_label.position = Vector2(PX + 260, row_y + 4)
		bar_label.size = Vector2(90, 24)
		bar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar_label.modulate = group_color
		_smeltery_layer.add_child(bar_label)
		_smeltery_bar_labels[ore_group] = bar_label

		var sell_btn := Button.new()
		sell_btn.position = Vector2(PX + 355, row_y)
		sell_btn.size = Vector2(150, 36)
		sell_btn.pressed.connect(_smeltery_sell.bind(ore_group))
		_smeltery_layer.add_child(sell_btn)
		_smeltery_sell_btns[ore_group] = sell_btn

		row_y += ROW_H

	var divider2 := ColorRect.new()
	divider2.position = Vector2(PX + 15, row_y + 4)
	divider2.size = Vector2(PANEL_W - 30, 2)
	divider2.color = Color(1.0, 0.55, 0.0, 0.5)
	_smeltery_layer.add_child(divider2)

	var close_btn := Button.new()
	close_btn.text = "Close Forge"
	close_btn.position = Vector2(PX + (PANEL_W - 200) / 2, row_y + 16)
	close_btn.size = Vector2(200, 40)
	close_btn.pressed.connect(_hide_smeltery_shop)
	_smeltery_layer.add_child(close_btn)

func _show_smeltery_shop() -> void:
	_smeltery_minerals_label.text = "Dollars: $%d" % GameManager.dollars

	for ore_group in SMELTERY_ORE_GROUPS_ORDER:
		var ore_count := _get_ore_group_count(ore_group)
		var bar_count: int = _run_bar_counts.get(ore_group, 0)
		var bar_name: String = SMELTERY_BAR_NAMES[ore_group]
		var sell_value: int = SMELTERY_BAR_SELL_VALUES[ore_group]

		_smeltery_ore_labels[ore_group].text = "%s: %d" % [ore_group.capitalize(), ore_count]
		_smeltery_smelt_btns[ore_group].text = "Smelt (%d ore)" % SMELTERY_ORES_PER_BAR
		_smeltery_smelt_btns[ore_group].disabled = ore_count < SMELTERY_ORES_PER_BAR

		_smeltery_bar_labels[ore_group].text = "%s: %d" % [bar_name, bar_count]
		_smeltery_sell_btns[ore_group].text = "Sell (+$%d)" % sell_value
		_smeltery_sell_btns[ore_group].disabled = bar_count <= 0

	_smeltery_layer.visible = true
	_smeltery_visible = true

func _hide_smeltery_shop() -> void:
	_smeltery_layer.visible = false
	_smeltery_visible = false

func _smeltery_smelt(ore_group: String) -> void:
	var ore_count := _get_ore_group_count(ore_group)
	if ore_count < SMELTERY_ORES_PER_BAR:
		return
	_consume_ores_for_smelt(ore_group, SMELTERY_ORES_PER_BAR)
	_run_bar_counts[ore_group] = _run_bar_counts.get(ore_group, 0) + 1
	SoundManager.play_drill_sound()
	EventBus.ore_mined_popup.emit(0, SMELTERY_BAR_NAMES[ore_group] + " smelted!")
	_show_smeltery_shop()

func _smeltery_sell(ore_group: String) -> void:
	var bar_count: int = _run_bar_counts.get(ore_group, 0)
	if bar_count <= 0:
		return
	var sell_value: int = SMELTERY_BAR_SELL_VALUES[ore_group]
	_run_bar_counts[ore_group] = bar_count - 1
	GameManager.add_dollars(sell_value)
	SoundManager.play_pickup_sound()
	EventBus.ore_mined_popup.emit(sell_value, SMELTERY_BAR_NAMES[ore_group] + " sold!")
	_show_smeltery_shop()

# ---------------------------------------------------------------------------
# Wandering Trader
# ---------------------------------------------------------------------------

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
		EventBus.ore_mined_popup.emit(0, hint)


func _check_trader_milestone(depth_row: int) -> void:
	if depth_row < TRADER_FIRST_CHECK:
		return
	if _traders_spawned_count >= TRADER_MAX_PER_RUN:
		return
	# Only check at regular intervals (every TRADER_CHECK_INTERVAL rows)
	var check_row := (depth_row / TRADER_CHECK_INTERVAL) * TRADER_CHECK_INTERVAL
	if check_row <= _trader_last_check_row:
		return
	_trader_last_check_row = check_row
	if randf() > TRADER_SPAWN_CHANCE:
		return
	# Tier scales with depth: 1-4
	var tier := clampi(depth_row / 32 + 1, 1, 4)
	_spawn_wandering_trader(tier)

func _spawn_wandering_trader(tier: int) -> void:
	if not player_node:
		return
	# Place the trader a couple of tiles to the right of the player
	var spawn_pos := player_node.global_position + Vector2(CELL_SIZE * 2.5, 0.0)
	_active_traders.append({"world_pos": spawn_pos, "tier": tier, "pulse": 0.0})
	_traders_spawned_count += 1
	EventBus.ore_mined_popup.emit(0, "Space Trader!")

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
	title.text = "Space Trader  —  Tier %d" % tier
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
# Forager Ant movement and banking (§3.4) — delegated to ForagerSystem
# ---------------------------------------------------------------------------
# forager_system.update(delta, player_pos, surface_deposit_pos) is called from _process().
# Ore chunk sweeping uses get_tree() so it stays here; ForagerSystem tracks the timer and carry.
# See src/systems/ForagerSystem.gd.

## Scan for ore chunks near the forager and let ForagerSystem collect them.
func _forager_do_sweep() -> void:
	var chunks := get_tree().get_nodes_in_group("ore_chunk")
	var nearby: Array = []
	for chunk in chunks:
		if is_instance_valid(chunk) \
				and forager_system.world_pos.distance_to(chunk.global_position) < ForagerSystem.COLLECT_RADIUS:
			nearby.append(chunk)
	forager_system.sweep_chunks(nearby)

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
		"energy":
			GameManager.run_mineral_currency -= cost
			GameManager.restore_energy(50)
			EventBus.ore_mined_popup.emit(0, "Fuel Cell Pack!")
		"repair":
			if player_node and player_node.is_at_max_health():
				EventBus.ore_mined_popup.emit(0, "Already at full HP")
				return
			GameManager.run_mineral_currency -= cost
			player_node.heal(1)
			EventBus.ore_mined_popup.emit(0, "Spacesuit Patched!")
		"shroom":
			GameManager.run_mineral_currency -= cost
			_shroom_charges += 12
			EventBus.ore_mined_popup.emit(0, "Astro Shroom!")
		"compass":
			GameManager.run_mineral_currency -= cost
			_lucky_compass_active = true
			EventBus.ore_mined_popup.emit(0, "Lucky Compass!")
		"map":
			GameManager.run_mineral_currency -= cost
			_ancient_map_active = true
			EventBus.ore_mined_popup.emit(0, "Deep Space Map!")

	EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
	SoundManager.play_drill_sound()
	_close_trader_shop()
	# Re-open with updated mineral count
	if _current_trader.size() == 0:
		_current_trader = _get_nearby_trader()
	if _current_trader.size() > 0:
		_show_trader_shop(_current_trader)
