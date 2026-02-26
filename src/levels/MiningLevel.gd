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
}

const MINEABLE_TILES: Array = [
	TileType.SURFACE_GRASS,
	TileType.DIRT, TileType.DIRT_DARK,
	TileType.STONE, TileType.STONE_DARK,
	TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP,
	TileType.ORE_IRON, TileType.ORE_IRON_DEEP,
	TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP,
	TileType.ORE_GEM, TileType.ORE_GEM_DEEP,
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
	TileType.EXPLOSIVE_ARMED: "res://assets/blocks/eucalyptus_log_side.png",
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
}

const ORE_TILES: Array = [
	TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP,
	TileType.ORE_IRON, TileType.ORE_IRON_DEEP,
	TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP,
	TileType.ORE_GEM, TileType.ORE_GEM_DEEP,
]

const LUCKY_STRIKE_CHANCE := 0.08
const SURFACE_ROWS: int = 3

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

# Hazard damage cooldown to prevent instant death
var _hazard_cooldown: float = 0.0
const HAZARD_COOLDOWN_TIME: float = 1.0

@onready var player_node: PlayerProbe = $PlayerProbe
@onready var pause_menu = $PauseMenu

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
	_setup_collision_tilemap()
	_sync_collision_tilemap()

	# Setup camera
	camera = Camera2D.new()
	add_child(camera)
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = GRID_COLS * CELL_SIZE
	camera.limit_bottom = GRID_ROWS * CELL_SIZE

	# Place player at spawn (exit zone, on surface)
	var spawn_col := GRID_COLS - 1
	var spawn_row := SURFACE_ROWS - 1
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
				column.append(TileType.EMPTY)
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

	if _hub_visible or _game_over or _fuel_shop_visible:
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
			var drain_rate := FUEL_DRAIN_BASE + depth_ratio * FUEL_DRAIN_DEPTH_MULT
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
	if _hub_visible or _game_over or _fuel_shop_visible:
		return
	if event.is_action_pressed("ui_cancel"):
		pause_menu.show_menu()
		return
	if event.is_action_pressed("interact"):
		_try_interact()

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

	# Normal mineable tile — multi-hit system
	var pos_key := Vector2i(col, row)
	var depth_row := row - SURFACE_ROWS
	var hardness_mult := 1.0 + (float(depth_row) / float(GRID_ROWS)) * 1.5
	var tile_hp: int = roundi(TILE_HP.get(tile, 6) * hardness_mult)
	var prev_damage: int = _tile_damage.get(pos_key, 0)
	var hits_so_far: int = _tile_hits.get(pos_key, 0)
	var new_damage: int = prev_damage + GameManager.get_mandibles_power()
	var min_hits: int = TILE_MIN_HITS.get(tile, 2)

	if hits_so_far + 1 < min_hits and new_damage >= tile_hp:
		new_damage = tile_hp - 1
	_flash_cells[pos_key] = 1.0

	if new_damage >= tile_hp:
		_tile_damage.erase(pos_key)
		_tile_hits.erase(pos_key)
		_mine_cell(col, row)
		if tile in MINEABLE_TILES:
			var minerals: int = TILE_MINERALS.get(tile, 1)
			_mine_streak += 1
			var lucky := tile in ORE_TILES and randf() < LUCKY_STRIKE_CHANCE
			if lucky:
				minerals *= 2
			GameManager.add_currency(minerals)
			EventBus.minerals_earned.emit(minerals)
			var popup_label: String = "LUCKY!" if lucky else TILE_NAMES.get(tile, "Mineral")
			EventBus.ore_mined_popup.emit(minerals, popup_label)
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
		{"name": "Chicken", "texture_path": "res://assets/chicken.svg", "col": 4},
		{"name": "Sheep",   "texture_path": "res://assets/sheep.svg",   "col": 8},
		{"name": "Pig",     "texture_path": "res://assets/pig.svg",     "col": 12},
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
