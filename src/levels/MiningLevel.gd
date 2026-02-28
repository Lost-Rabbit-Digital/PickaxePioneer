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
	TileType.LADDER:          "Ladder",
	TileType.CAT_TAVERN:      "Cat Tavern",
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
	TileType.UPGRADE_STATION:  Color(0.40, 0.50, 0.60),
	TileType.SMELTERY_STATION: Color(0.40, 0.50, 0.60),
	TileType.LADDER:           Color(0.80, 0.60, 0.15),
	TileType.CAT_TAVERN:       Color(0.40, 0.50, 0.60),
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
	TileType.UPGRADE_STATION:  "res://assets/blocks/cobblestone_bricks.png",
	TileType.SMELTERY_STATION: "res://assets/blocks/cobblestone_bricks.png",
	TileType.CAT_TAVERN:       "res://assets/blocks/cobblestone_bricks.png",
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
const GRAVITY_TILES: Array = [TileType.STONE_DARK]

# Seconds between each row-step a gravity tile falls
const GRAVITY_FALL_DELAY: float = 0.2

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

# Shop + Trader systems (Node children — own all shop UI and trader NPC logic)
var shop_system: MiningShopSystem = null
var trader_system: TraderSystem = null

# Depth tracking
var _last_depth: int = 0
var _current_zone_idx: int = -1

var _game_over: bool = false

# Per-tile damage/hit tracking for multi-hit mining
var _tile_damage: Dictionary = {}
var _tile_hits: Dictionary = {}
var _flash_cells: Dictionary = {}
var _breaking_overlays: Dictionary = {}  # Maps Vector2i -> AnimatedSprite2D instance

# Gravity-tile fall queue: Vector2i(col, row) -> float seconds_until_next_step
var _gravity_pending: Dictionary = {}
var _mine_streak: int = 0
var _zones_discovered: Array[bool] = [false, false, false, false, false]
var _exit_pulse_time: float = 0.0

# Cursor highlight
var _cursor_grid_pos: Vector2i = Vector2i(-1, -1)

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

@onready var player_node: PlayerProbe = $PlayerProbe
@onready var pause_menu = $PauseMenu

var _inventory_screen: InventoryScreen = null

# Farm animal NPCs
var _farm_npcs: Array = []
const FARM_NPC_ROW: int = 2  # Placed on the middle surface row

var _pickaxe_texture: Texture2D

func _ready() -> void:
	_pickaxe_texture = load("res://assets/db32_rpg_items/pickaxe_steel.png") as Texture2D
	

	texture_filter = TEXTURE_FILTER_NEAREST

	_load_tile_textures()
	_generate_grid()
	_generate_ore_veins()   # hydrothermal veins — all ore originates here
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
		grid, GRID_COLS, GRID_ROWS, SURFACE_ROWS,
		func(c, r, solid): _set_tile_collision(c, r, solid),
		func(text, color): _show_zone_banner(text, color),
		func(intensity, duration): _shake_camera(intensity, duration),
		func(pos): _tile_damage.erase(pos); _tile_hits.erase(pos); _remove_breaking_overlay(pos)
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

	# Underground Cat Tavern — placed in the first sub-zone (~17 rows below surface)
	var tavern_col := clampi(reenergy_col + 10, 5, GRID_COLS - 6)
	grid[tavern_col][SURFACE_ROWS + 17] = TileType.CAT_TAVERN

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
						if randf() < 0.20:
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

# ---------------------------------------------------------------------------
# Hydrothermal Vein Generation — modelled after porphyry deposit geology.
#
# Ore deposits form as tall, narrow vertical veins that meander slightly
# through the rock.  Each vein tier is depth-stratified:
#
#   Copper  → shallow (Asteroid Belt, rows  5–41)
#   Iron    → mid     (Asteroid Belt → Star Cluster, rows 16–71)
#   Gold    → deep    (Nebula Zone → Deep Space, rows 41–101)
#   Gem     → deepest (Star Cluster → bottom, rows 71–126)
#
# The top of every iron/gold/gem vein has a "cap" of shallower ore — so a
# copper cap hints at an iron vein below; an iron cap hints at gold, etc.
# This rewards players who follow veins down through multiple depth zones.
# ---------------------------------------------------------------------------
const VEIN_MEANDER_CHANCE: float = 0.35  # per-row probability of centre drift

func _generate_ore_veins() -> void:
	var allowed: Array = GameManager.allowed_ore_types

	# Each spec defines a population of veins for one ore tier.
	# zone:    [first_row, last_row] — primary depth band for this ore.
	# cap:     ore tile used in the top portion of the vein (-1 = none).
	# cap_len: [min, max] rows of cap material.
	var specs := [
		# ── Copper — shallow (Asteroid Belt) ──────────────────────────────
		{
			"ore": TileType.ORE_COPPER,      "ore_deep": TileType.ORE_COPPER_DEEP,
			"cap": -1,                        "cap_len": [0, 0],
			"zone":  [SURFACE_ROWS + 2,       DEPTH_ZONE_ROWS[2]],
			"count": [4, 7],  "length": [14, 26],  "width": [1, 2],
			"key": "Copper",
		},
		# ── Iron — mid-depth (Asteroid Belt → Star Cluster) ───────────────
		{
			"ore": TileType.ORE_IRON,        "ore_deep": TileType.ORE_IRON_DEEP,
			"cap": TileType.ORE_COPPER_DEEP, "cap_len": [7, 14],
			"zone":  [DEPTH_ZONE_ROWS[1],     DEPTH_ZONE_ROWS[3]],
			"count": [4, 6],  "length": [18, 32],  "width": [1, 2],
			"key": "Iron",
		},
		# ── Gold — deep (Nebula Zone → Deep Space) ────────────────────────
		{
			"ore": TileType.ORE_GOLD,        "ore_deep": TileType.ORE_GOLD_DEEP,
			"cap": TileType.ORE_IRON_DEEP,   "cap_len": [8, 16],
			"zone":  [DEPTH_ZONE_ROWS[2],     DEPTH_ZONE_ROWS[4]],
			"count": [3, 5],  "length": [18, 32],  "width": [1, 2],
			"key": "Gold",
		},
		# ── Gem — deepest (Star Cluster → bottom) ─────────────────────────
		{
			"ore": TileType.ORE_GEM,         "ore_deep": TileType.ORE_GEM_DEEP,
			"cap": TileType.ORE_GOLD_DEEP,   "cap_len": [10, 20],
			"zone":  [DEPTH_ZONE_ROWS[3],     GRID_ROWS - 2],
			"count": [2, 4],  "length": [14, 24],  "width": [1, 2],
			"key": "Gem",
		},
	]

	for spec in specs:
		if not allowed.is_empty() and not allowed.has(spec["key"]):
			continue
		var count := randi_range(spec["count"][0], spec["count"][1])
		for _i in range(count):
			_place_ore_vein(spec)

func _place_ore_vein(spec: Dictionary) -> void:
	var zone_start: int = spec["zone"][0]
	var zone_end: int   = spec["zone"][1]
	var length: int     = randi_range(spec["length"][0], spec["length"][1])
	var width: int      = randi_range(spec["width"][0],  spec["width"][1])

	# Start row inside the zone (ensure the full vein fits vertically).
	var max_start := maxi(zone_start, zone_end - length)
	var start_row: int  = randi_range(zone_start, max_start)

	# Random horizontal centre, away from the map edges.
	var center_col: int = randi_range(3, GRID_COLS - 4)

	# Cap occupies the topmost rows with a shallower ore as a visual hint.
	var cap_len: int = 0
	if spec["cap"] != -1:
		cap_len = randi_range(spec["cap_len"][0], spec["cap_len"][1])
		cap_len = mini(cap_len, length - 4)  # guarantee at least 4 primary rows

	for i in range(length):
		var row := start_row + i
		if row < SURFACE_ROWS + 1 or row >= GRID_ROWS - 1:
			continue

		# Ore type: cap at top, shallow primary variant in upper half, deep in lower.
		var ore_tile: int
		if i < cap_len:
			ore_tile = spec["cap"]
		else:
			var primary_t := float(i - cap_len) / float(maxi(1, length - cap_len))
			ore_tile = spec["ore_deep"] if primary_t > 0.5 else spec["ore"]

		# Meander: random-walk the centre column.
		if randf() < VEIN_MEANDER_CHANCE:
			center_col += randi_range(-1, 1)
			center_col = clampi(center_col, 2, GRID_COLS - 3)

		# Place ore across the vein width, centred on center_col.
		for w in range(width):
			var place_col := center_col - width / 2 + w
			if place_col < 1 or place_col >= GRID_COLS - 1:
				continue
			var current: int = grid[place_col][row]
			# Only overwrite background rock — never hazards, stations, or surface.
			if current in [TileType.DIRT, TileType.DIRT_DARK,
							TileType.STONE, TileType.STONE_DARK]:
				grid[place_col][row] = ore_tile

func _random_tile(_col: int, row: int) -> TileType:
	# All ore comes from hydrothermal veins (_generate_ore_veins).
	# This function only determines background rock and hazard composition.
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

	# Rock composition grows harder with depth.
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

			# Ladders — transparent overlay (two poles + rungs), skip normal texture
			if tile == TileType.LADDER:
				var lx := col * CELL_SIZE
				var ly := row * CELL_SIZE
				draw_rect(Rect2(lx + 10, ly + 2, 8, CELL_SIZE - 4), Color(0.80, 0.60, 0.15, 0.90))
				draw_rect(Rect2(lx + CELL_SIZE - 18, ly + 2, 8, CELL_SIZE - 4), Color(0.80, 0.60, 0.15, 0.90))
				for rung in 3:
					draw_rect(Rect2(lx + 10, ly + 10 + rung * 18, CELL_SIZE - 20, 5),
						Color(0.70, 0.50, 0.10, 0.90))
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

			if tile == TileType.CAT_TAVERN:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color(0.75, 0.35, 0.90), false, 2.0)
				var cfont := ThemeDB.fallback_font
				draw_string(cfont,
					Vector2(col * CELL_SIZE + 4, row * CELL_SIZE + CELL_SIZE / 2 + 5),
					"CAT", HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE - 8, 11, Color(0.90, 0.70, 1.00))

			# Breaking overlay is handled by child AnimatedSprite2D instances

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

	# Trader nodes are drawn by TraderSystem._draw() (Node2D child)

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

	# CatSystem draws itself as a Node2D child (AnimatedSprite2D nodes + carry bars via its own _draw)

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
# UI-blocking helper — used by PlayerProbe to pause input while any shop is open
# ---------------------------------------------------------------------------

func any_ui_open() -> bool:
	return shop_system != null and (shop_system.any_shop_open() or trader_system.shop_visible)

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

	# Gravity tile falling (gravel etc. drop when unsupported)
	_process_gravity(delta)

	# Update sonar ping wave (§3.2) — delegated to SonarSystem
	sonar_system.update(delta, 2.0 if _ancient_map_active[0] else 1.0)

	# Boss system update (trader_system has its own _process as a Node child)
	var _boss_pcol := floori(player_node.global_position.x / CELL_SIZE) if player_node else -1
	var _boss_prow := floori(player_node.global_position.y / CELL_SIZE) if player_node else -1
	boss_system.update(delta, _boss_pcol, _boss_prow)

	# Update player on_ladder flag each frame
	if player_node:
		var pgp := player_node.get_grid_pos()
		player_node.on_ladder = (
			pgp.x >= 0 and pgp.x < GRID_COLS and pgp.y >= 0 and pgp.y < GRID_ROWS
			and grid[pgp.x][pgp.y] == TileType.LADDER
		)

	if _game_over or shop_system.any_shop_open() or trader_system.shop_visible:
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
		shop_system.show_hub()
	# Reaching the bottom of the map also counts as a completed run
	elif player_row >= GRID_ROWS - 1:
		_game_over = true
		GameManager.complete_run()

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _game_over or shop_system.any_shop_open() or trader_system.shop_visible:
		return
	if event.is_action_pressed("toggle_inventory"):
		if _inventory_screen:
			if _inventory_screen.visible:
				_inventory_screen.close()
			else:
				_inventory_screen.open(shop_system.run_ore_counts, _shroom_charges[0],
					_lucky_compass_active[0], _ancient_map_active[0])
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
	# F key — place a ladder on the tile the player currently occupies
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_F:
		_try_place_ladder()

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
	if _breaking_overlays.has(pos_key):
		var overlay: AnimatedSprite2D = _breaking_overlays[pos_key]
		overlay.queue_free()
		_breaking_overlays.erase(pos_key)

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
		return

	# Lava — can't mine lava
	if tile == TileType.LAVA or tile == TileType.LAVA_FLOW:
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
		_remove_breaking_overlay(pos_key)
		_mine_cell(col, row)
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
			# Mining Shroom buff: doubled yield on ore tiles
			if _shroom_charges[0] > 0 and tile in ORE_TILES:
				minerals *= 2
				_shroom_charges[0] -= 1
			# Track ore counts for inventory (ore tiles only)
			if tile in ORE_TILES:
				shop_system.run_ore_counts[tile] = shop_system.run_ore_counts.get(tile, 0) + 1
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
		var damage_ratio := float(new_damage) / float(tile_hp)
		_update_breaking_overlay(pos_key, damage_ratio)
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

		# Clear any partial-damage state that belonged to the old position.
		_tile_damage.erase(pos)
		_tile_hits.erase(pos)
		_remove_breaking_overlay(pos)

		# Also clear damage on the destination (a tile falling onto an already-
		# damaged cell should start fresh).
		var new_pos := Vector2i(col, below_row)
		_tile_damage.erase(new_pos)
		_tile_hits.erase(new_pos)
		_remove_breaking_overlay(new_pos)

		queue_redraw()

		# Schedule the next fall step from the new position.
		_gravity_pending[new_pos] = GRAVITY_FALL_DELAY

		# If something was sitting above the old position, it may now be
		# unsupported — trigger a gravity check for it too.
		_trigger_gravity_above(col, row)

func _mine_cell(col: int, row: int) -> void:
	grid[col][row] = TileType.EMPTY
	_set_tile_collision(col, row, false)
	# A newly-empty cell may leave a gravity tile unsupported above it.
	_trigger_gravity_above(col, row)

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
				_remove_breaking_overlay(Vector2i(nc, nr))
				# Explosion may leave gravity tiles unsupported above cleared cells.
				_trigger_gravity_above(nc, nr)
	SoundManager.play_explosion_sound()
	_shake_camera(6.0, 0.35)
	if player_node:
		var player_col := int(player_node.global_position.x / CELL_SIZE)
		var player_row := int(player_node.global_position.y / CELL_SIZE)
		if abs(player_col - center_col) <= r and abs(player_row - center_row) <= r:
			_damage_player(1)

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
		var check: Vector2i = player_node.get_grid_pos() + offset
		if check.x < 0 or check.x >= GRID_COLS or check.y < 0 or check.y >= GRID_ROWS:
			continue
		var t: int = grid[check.x][check.y]
		if t in STATION_PROMPTS:
			player_node.show_prompt(STATION_PROMPTS[t] % key)
			var world_pos := Vector2(check.x * CELL_SIZE + CELL_SIZE * 0.5, check.y * CELL_SIZE)
			player_node.set_prompt_position(get_viewport().get_canvas_transform() * world_pos)
			return
	# Trader prompt
	var nearby_trader := trader_system.get_nearby_trader()
	if nearby_trader.size() > 0:
		player_node.show_prompt("Press %s to trade" % key)
		player_node.set_prompt_position(
			get_viewport().get_canvas_transform() * (nearby_trader["world_pos"] as Vector2)
			+ Vector2(0, -CELL_SIZE))
		return
	# Farm NPC prompt
	var nearby_npc: FarmAnimalNPC = _get_nearby_farm_npc()
	if nearby_npc:
		player_node.show_prompt("Press %s to pet the %s" % [key, nearby_npc.animal_name])
		player_node.set_prompt_position(
			get_viewport().get_canvas_transform() * (player_node.global_position + Vector2(0, -CELL_SIZE)))
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
		var check: Vector2i = player_node.get_grid_pos() + offset
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

func _try_place_ladder() -> void:
	if GameManager.selected_hotbar_slot != 1:
		EventBus.ore_mined_popup.emit(0, "Select the ladder (slot 2) to place ladders.")
		return
	if not player_node:
		return
	if GameManager.ladder_count <= 0:
		EventBus.ore_mined_popup.emit(0, "No ladders! Buy packs at the Refueling Dock.")
		return
	var gp := player_node.get_grid_pos()
	if gp.x < 0 or gp.x >= GRID_COLS or gp.y < 0 or gp.y >= GRID_ROWS:
		return
	if grid[gp.x][gp.y] != TileType.EMPTY:
		EventBus.ore_mined_popup.emit(0, "Can only place ladders in open space.")
		return
	grid[gp.x][gp.y] = TileType.LADDER
	GameManager.ladder_count -= 1
	GameManager.save_game()
	EventBus.ladder_count_changed.emit(GameManager.ladder_count)
	EventBus.ore_mined_popup.emit(0, "Ladder placed!  (%d remaining)" % GameManager.ladder_count)
	queue_redraw()
