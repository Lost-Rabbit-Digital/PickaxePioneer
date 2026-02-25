extends Node2D

# Grid-based Mining Level
# Player spawns on the right (exit zone) and moves LEFT to mine.
# Right EXIT_COLS columns are empty — returning there ends the run.
# Map is 32x128 tiles; Camera2D follows the player.

const GRID_COLS: int = 32
const GRID_ROWS: int = 128
const CELL_SIZE: int = 64
const EXIT_COLS: int = 2  # Rightmost columns are the exit/spawn zone

const VIEWPORT_W: int = 1280
const VIEWPORT_H: int = 720

enum TileType {
	EMPTY            = 0,
	DIRT             = 1,
	DIRT_DARK        = 2,   # Darker soil variant
	ORE_COPPER       = 3,
	ORE_COPPER_DEEP  = 4,   # Deeper copper ore
	ORE_IRON         = 5,
	ORE_IRON_DEEP    = 6,   # Deeper iron ore
	ORE_GOLD         = 7,
	ORE_GOLD_DEEP    = 8,   # Deeper gold ore
	ORE_GEM          = 9,
	ORE_GEM_DEEP     = 10,  # Deeper gem ore
	STONE            = 11,  # Regular stone
	STONE_DARK       = 12,  # Dark stone variant
	EXPLOSIVE        = 13,
	EXPLOSIVE_ARMED  = 14,  # Armed explosive variant
	LAVA             = 15,
	LAVA_FLOW        = 16,  # Lava flow variant
	FUEL_NODE        = 17,
	FUEL_NODE_FULL   = 18,  # Fully charged fuel node
	REFUEL_STATION   = 19,
	SURFACE          = 20,  # Surface tile - no fuel consumption, left/right only
	SURFACE_GRASS    = 21,  # Grass surface variant
	EXIT_STATION     = 22,  # Exit station tile on the surface (far right)
}

# Display names shown in the HUD earnings popup
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
}

const TILE_COLORS: Dictionary = {
	TileType.DIRT:           Color(0.45, 0.28, 0.12),  # Brown
	TileType.DIRT_DARK:      Color(0.35, 0.20, 0.08),  # Dark brown
	TileType.ORE_COPPER:     Color(0.80, 0.50, 0.20),  # Copper orange
	TileType.ORE_COPPER_DEEP: Color(0.70, 0.40, 0.10), # Deep copper
	TileType.ORE_IRON:       Color(0.65, 0.65, 0.72),  # Iron silver
	TileType.ORE_IRON_DEEP:  Color(0.55, 0.55, 0.65),  # Deep iron
	TileType.ORE_GOLD:       Color(1.00, 0.85, 0.10),  # Gold yellow
	TileType.ORE_GOLD_DEEP:  Color(0.90, 0.75, 0.05),  # Deep gold
	TileType.ORE_GEM:        Color(0.15, 0.85, 0.75),  # Gem cyan
	TileType.ORE_GEM_DEEP:   Color(0.10, 0.75, 0.65),  # Deep gem
	TileType.STONE:          Color(0.50, 0.50, 0.50),  # Stone grey
	TileType.STONE_DARK:     Color(0.40, 0.40, 0.40),  # Dark stone
	TileType.EXPLOSIVE:      Color(0.90, 0.10, 0.10),  # Explosive red
	TileType.EXPLOSIVE_ARMED: Color(1.00, 0.00, 0.00), # Armed explosive bright red
	TileType.LAVA:           Color(1.00, 0.45, 0.00),  # Lava orange
	TileType.LAVA_FLOW:      Color(1.00, 0.30, 0.00),  # Lava flow darker
	TileType.FUEL_NODE:      Color(0.20, 0.80, 0.20),  # Fuel green
	TileType.FUEL_NODE_FULL: Color(0.10, 1.00, 0.10),  # Full fuel bright green
	TileType.REFUEL_STATION: Color(0.50, 0.50, 0.50),  # Refuel station grey
	TileType.SURFACE:        Color(0.35, 0.35, 0.35),  # Surface dark grey
	TileType.SURFACE_GRASS:  Color(0.25, 0.50, 0.25),  # Surface grass green
	TileType.EXIT_STATION:   Color(0.15, 0.55, 0.15),   # Exit station green
}

# Individual block texture paths for each tile type
const TILE_TEXTURE_PATHS: Dictionary = {
	TileType.DIRT:            "res://assets/blocks/dirt.png",
	TileType.DIRT_DARK:       "res://assets/blocks/mud.png",
	TileType.STONE:           "res://assets/blocks/stone_generic.png",
	TileType.STONE_DARK:      "res://assets/blocks/slate.png",
	TileType.ORE_COPPER:      "res://assets/blocks/stone_generic_ore_nuggets.png",
	TileType.ORE_COPPER_DEEP: "res://assets/blocks/stone_generic_ore_crystalline.png",
	TileType.ORE_IRON:        "res://assets/blocks/gabbro.png",
	TileType.ORE_IRON_DEEP:   "res://assets/blocks/schist.png",
	TileType.ORE_GOLD:        "res://assets/blocks/sandstone.png",
	TileType.ORE_GOLD_DEEP:   "res://assets/blocks/granite.png",
	TileType.ORE_GEM:         "res://assets/blocks/amethyst.png",
	TileType.ORE_GEM_DEEP:    "res://assets/blocks/obsidian.png",
	TileType.EXPLOSIVE:       "res://assets/blocks/rhyolite.png",
	TileType.EXPLOSIVE_ARMED: "res://assets/blocks/rhyolite_tiles.png",
	TileType.LAVA:            "res://assets/blocks/basalt_flow.png",
	TileType.LAVA_FLOW:       "res://assets/blocks/basalt.png",
	TileType.FUEL_NODE:       "res://assets/blocks/limestone.png",
	TileType.FUEL_NODE_FULL:  "res://assets/blocks/marble.png",
	TileType.REFUEL_STATION:  "res://assets/blocks/cobblestone_bricks.png",
	TileType.SURFACE:         "res://assets/blocks/grass_top.png",
	TileType.SURFACE_GRASS:   "res://assets/blocks/grass_side.png",
}

# Auto-move: after holding a direction key for AUTO_MOVE_DELAY seconds the
# player automatically steps in that direction every AUTO_MOVE_INTERVAL seconds.
const AUTO_MOVE_DELAY: float = 0.15    # Hold threshold before repeating starts
const AUTO_MOVE_INTERVAL: float = 0.15 # Time between repeated steps

# HP per tile type — determines how many hits needed to mine it.
# Base mandibles power = 5 (get_mandibles_power()). Each upgrade adds 3.
# Each upgrade level unlocks 1-hit mining for the next ore tier:
#   Lv0→dirt(1-hit), Lv1→stone(1-hit), Lv2→copper(1-hit), Lv3→iron(1-hit),
#   Lv5→gold(1-hit), Lv8→gem(1-hit)
const TILE_HP: Dictionary = {
	TileType.SURFACE_GRASS:   4,   # Always 1 hit (HP < base power 5)
	TileType.DIRT:            4,
	TileType.DIRT_DARK:       4,
	TileType.STONE:           8,   # 2 hits base; 1 hit at Lv1 (power 8)
	TileType.STONE_DARK:      10,  # 2 hits base; 1 hit at Lv2 (power 11)
	TileType.ORE_COPPER:      11,  # 3 hits base; 1 hit at Lv2 (power 11)
	TileType.ORE_COPPER_DEEP: 13,  # 3 hits base; 1 hit at Lv3 (power 14)
	TileType.ORE_IRON:        14,  # 3 hits base; 1 hit at Lv3 (power 14)
	TileType.ORE_IRON_DEEP:   17,  # 4 hits base; 1 hit at Lv4 (power 17)
	TileType.ORE_GOLD:        20,  # 4 hits base; 1 hit at Lv5 (power 20)
	TileType.ORE_GOLD_DEEP:   23,  # 5 hits base; 1 hit at Lv6 (power 23)
	TileType.ORE_GEM:         29,  # 6 hits base; 1 hit at Lv8 (power 29)
	TileType.ORE_GEM_DEEP:    32,  # 7 hits base; 1 hit at Lv9 (power 32)
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

var grid: Array = []
var player_grid_pos: Vector2i = Vector2i(2, 2)  # Start at top-left (on surface)
var has_left_spawn: bool = false  # True once player moves into the mining area
var is_on_surface: bool = true  # Whether player is on the surface layer

# Auto-move state
var _held_dir: Vector2i = Vector2i.ZERO
var _hold_time: float = 0.0
var _auto_move_time: float = 0.0

# Textures
var player_texture: Texture2D
var tile_textures: Dictionary = {}  # TileType → Texture2D loaded from assets/blocks/

# Camera
var camera: Camera2D

# Surface Hub — shown when the ant reaches the Exit Station
var _hub_layer: CanvasLayer
var _hub_minerals_label: Label
var _hub_visible: bool = false
var _upgrade_layer: CanvasLayer  # Hosts the UpgradeMenu overlay when opened in-mine

# Depth tracking — rows below the surface
var _last_depth: int = 0

# Set to true when the game-over overlay is shown to block further input
var _game_over: bool = false

# Per-tile damage tracking for multi-hit blocks (key: Vector2i, value: damage dealt)
var _tile_damage: Dictionary = {}

# Per-tile white impact flash (key: Vector2i, value: alpha 0-1, fades in _process)
var _flash_cells: Dictionary = {}

@onready var player_node = $PlayerProbe
@onready var pause_menu = $PauseMenu

func _ready() -> void:
	var ant_spritesheet := load("res://assets/creatures/red_ant_spritesheet.png") as Texture2D
	var ant_atlas := AtlasTexture.new()
	ant_atlas.atlas = ant_spritesheet
	ant_atlas.region = Rect2(0, 0, 16, 16)
	player_texture = ant_atlas

	# Use nearest-neighbor filtering for crisp pixel-art tile textures
	texture_filter = TEXTURE_FILTER_NEAREST

	# Load individual block textures from assets/blocks/
	_load_tile_textures()

	_generate_grid()

	# Create Camera2D and configure it to follow the player with map bounds
	camera = Camera2D.new()
	add_child(camera)
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = GRID_COLS * CELL_SIZE
	camera.limit_bottom = GRID_ROWS * CELL_SIZE
	_update_camera()

	EventBus.player_died.connect(_on_player_died)

	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)
	QuestManager.clear_quest()
	_setup_surface_hub()
	queue_redraw()

const SURFACE_ROWS: int = 3  # Top 3 rows are surface

func _generate_grid() -> void:
	grid = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			if row < SURFACE_ROWS:
				# Surface layer - accessible to player, no fuel consumption
				column.append(TileType.SURFACE)
			elif col >= GRID_COLS - EXIT_COLS:
				# Exit zone
				column.append(TileType.EMPTY)
			else:
				# Mining area — ore richness increases with depth
				column.append(_random_tile(row))
		grid.append(column)

	# Place refuel station on surface (middle area)
	var refuel_col = GRID_COLS / 2
	grid[refuel_col][SURFACE_ROWS - 1] = TileType.REFUEL_STATION

	# Place exit station on surface (far right)
	grid[GRID_COLS - 1][SURFACE_ROWS - 1] = TileType.EXIT_STATION

	# First mine-able row is a grass layer (row SURFACE_ROWS = 3)
	for col in range(GRID_COLS - EXIT_COLS):
		grid[col][SURFACE_ROWS] = TileType.SURFACE_GRASS

# Depth-weighted random tile: rarer ores are more common deeper
func _random_tile(row: int = SURFACE_ROWS) -> TileType:
	var r := randf()
	# Depth factor: 0.0 at surface, 1.0 at bottom row
	var depth := float(row - SURFACE_ROWS) / float(GRID_ROWS - SURFACE_ROWS)

	# Hazards (10% total, slightly more at depth)
	var hazard_bias := 0.10 + depth * 0.05
	if   r < hazard_bias * 0.4:  return TileType.EXPLOSIVE
	elif r < hazard_bias * 0.6:  return TileType.EXPLOSIVE_ARMED
	elif r < hazard_bias * 0.8:  return TileType.LAVA
	elif r < hazard_bias:        return TileType.LAVA_FLOW

	# Fuel nodes (3%)
	elif r < hazard_bias + 0.02: return TileType.FUEL_NODE
	elif r < hazard_bias + 0.03: return TileType.FUEL_NODE_FULL

	# Rare ores (gem/gold) more common at depth
	var gem_chance   := 0.04 + depth * 0.08
	var gold_chance  := 0.06 + depth * 0.06
	var iron_chance  := 0.08
	var copper_chance := 0.08

	var ore_start := hazard_bias + 0.03
	if r < ore_start + gem_chance * 0.5:             return TileType.ORE_GEM_DEEP
	elif r < ore_start + gem_chance:                  return TileType.ORE_GEM
	elif r < ore_start + gem_chance + gold_chance * 0.5:  return TileType.ORE_GOLD_DEEP
	elif r < ore_start + gem_chance + gold_chance:    return TileType.ORE_GOLD
	elif r < ore_start + gem_chance + gold_chance + iron_chance * 0.5:  return TileType.ORE_IRON_DEEP
	elif r < ore_start + gem_chance + gold_chance + iron_chance:         return TileType.ORE_IRON
	elif r < ore_start + gem_chance + gold_chance + iron_chance + copper_chance * 0.5: return TileType.ORE_COPPER_DEEP
	elif r < ore_start + gem_chance + gold_chance + iron_chance + copper_chance:       return TileType.ORE_COPPER

	# Stone (heavier at depth) vs Dirt (heavier at surface)
	var stone_chance := 0.10 + depth * 0.30
	var r2 := randf()
	if r2 < stone_chance * 0.6:  return TileType.STONE_DARK
	elif r2 < stone_chance:       return TileType.STONE
	elif r2 < stone_chance + 0.15: return TileType.DIRT_DARK
	else:                          return TileType.DIRT

func _load_tile_textures() -> void:
	# Load each tile's individual block PNG from assets/blocks/
	for tile_type in TILE_TEXTURE_PATHS:
		var path: String = TILE_TEXTURE_PATHS[tile_type]
		var tex := load(path) as Texture2D
		if tex:
			tile_textures[tile_type] = tex
		else:
			push_warning("Failed to load block texture: " + path)

# ---------------------------------------------------------------------------
# Camera follow
# ---------------------------------------------------------------------------

func _update_camera() -> void:
	if not camera:
		return
	# Center the camera on the player in world space; Camera2D limits handle clamping.
	camera.position = Vector2(
		player_grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5,
		player_grid_pos.y * CELL_SIZE + CELL_SIZE * 0.5
	)

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _draw() -> void:
	# Determine which tiles are inside the visible viewport (culling).
	# Camera position equals camera.position when limits are respected.
	var cam_x: float
	var cam_y: float
	if camera:
		cam_x = clamp(camera.position.x, VIEWPORT_W * 0.5, GRID_COLS * CELL_SIZE - VIEWPORT_W * 0.5)
		cam_y = clamp(camera.position.y, VIEWPORT_H * 0.5, GRID_ROWS * CELL_SIZE - VIEWPORT_H * 0.5)
	else:
		cam_x = VIEWPORT_W * 0.5
		cam_y = VIEWPORT_H * 0.5

	var half_w: float = float(VIEWPORT_W) * 0.5 + float(CELL_SIZE)  # one-cell overdraw margin
	var half_h: float = float(VIEWPORT_H) * 0.5 + float(CELL_SIZE)

	var min_col: int = maxi(0,             int((cam_x - half_w) / float(CELL_SIZE)))
	var max_col: int = mini(GRID_COLS - 1, int((cam_x + half_w) / float(CELL_SIZE)))
	var min_row: int = maxi(0,             int((cam_y - half_h) / float(CELL_SIZE)))
	var max_row: int = mini(GRID_ROWS - 1, int((cam_y + half_h) / float(CELL_SIZE)))

	# ---- Background fills (only the visible strip) ----
	var bg_left: int   = min_col * CELL_SIZE
	var bg_top: int    = min_row * CELL_SIZE
	var bg_width: int  = (max_col - min_col + 1) * CELL_SIZE
	var bg_height: int = (max_row - min_row + 1) * CELL_SIZE

	# Sky blue for surface rows (open sky look), dark dirt for underground
	if min_row < SURFACE_ROWS:
		var sky_top := min_row * CELL_SIZE
		var sky_bottom := mini(SURFACE_ROWS, max_row + 1) * CELL_SIZE
		draw_rect(Rect2(bg_left, sky_top, bg_width, sky_bottom - sky_top), Color(0.40, 0.65, 0.90))
	if max_row >= SURFACE_ROWS:
		var dirt_top := maxi(min_row, SURFACE_ROWS) * CELL_SIZE
		var dirt_bottom := (max_row + 1) * CELL_SIZE
		draw_rect(Rect2(bg_left, dirt_top, bg_width, dirt_bottom - dirt_top), Color(0.08, 0.06, 0.04))

	# ---- Tile sprites ----
	for col in range(min_col, max_col + 1):
		for row in range(min_row, max_row + 1):
			var tile: int = grid[col][row]
			# SURFACE tiles are rendered as open sky (blue background shows through)
			if tile == TileType.EMPTY or tile == TileType.SURFACE:
				continue

			var tile_rect := Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)

			# Exit station gets custom rendering (green square + white border + EXIT label)
			if tile == TileType.EXIT_STATION:
				draw_rect(tile_rect, Color(0.15, 0.55, 0.15))
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color.WHITE, false, 2.0)
				var exit_font := ThemeDB.fallback_font
				draw_string(exit_font,
					Vector2(col * CELL_SIZE, row * CELL_SIZE + CELL_SIZE / 2 + 5),
					"EXIT",
					HORIZONTAL_ALIGNMENT_CENTER, CELL_SIZE, 13,
					Color(0.4, 1.0, 0.4))
				continue

			# Draw the block sprite, fall back to color if texture not loaded
			var tex: Texture2D = tile_textures.get(tile)
			if tex:
				draw_texture_rect(tex, tile_rect, false)
			else:
				draw_rect(tile_rect, TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5)))

			# Refuel station gets a white border highlight
			if tile == TileType.REFUEL_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4),
					Color.WHITE, false, 2.0)

			# Crack overlay — darkens as block loses HP from repeated hits
			var pk := Vector2i(col, row)
			if _tile_damage.has(pk):
				var tile_hp: int = TILE_HP.get(tile, 0)
				if tile_hp > 0:
					var damage_ratio := float(_tile_damage[pk]) / float(tile_hp)
					draw_rect(tile_rect, Color(0.0, 0.0, 0.0, damage_ratio * 0.6))

	# ---- Impact flashes (drawn on top of tiles, below player) ----
	for pk in _flash_cells:
		var fc: int = pk.x
		var fr: int = pk.y
		if fc >= min_col and fc <= max_col and fr >= min_row and fr <= max_row:
			var frect := Rect2(fc * CELL_SIZE, fr * CELL_SIZE, CELL_SIZE, CELL_SIZE)
			draw_rect(frect, Color(1.0, 1.0, 1.0, _flash_cells[pk]))

	# ---- Player sprite ----
	var player_rect := Rect2(
		player_grid_pos.x * CELL_SIZE + 2,
		player_grid_pos.y * CELL_SIZE + 2,
		CELL_SIZE - 4,
		CELL_SIZE - 4
	)
	if player_texture:
		draw_texture_rect(player_texture, player_rect, false)
	else:
		draw_rect(player_rect, Color(0.20, 0.80, 1.00))


# ---------------------------------------------------------------------------
# Auto-move (hold-to-repeat)
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
	var current_tile: int = grid[player_grid_pos.x][player_grid_pos.y]
	if current_tile == TileType.REFUEL_STATION:
		var key_name := _get_interact_key_name()
		player_node.show_prompt("Press %s to refuel" % key_name)
		var world_pos := Vector2(
			player_grid_pos.x * CELL_SIZE + CELL_SIZE * 0.5,
			player_grid_pos.y * CELL_SIZE
		)
		var screen_pos := get_viewport().get_canvas_transform() * world_pos
		player_node.set_prompt_position(screen_pos)
	else:
		player_node.hide_prompt()

func _try_interact() -> void:
	if grid[player_grid_pos.x][player_grid_pos.y] == TileType.REFUEL_STATION:
		if GameManager.refuel_completely(10):
			SoundManager.play_drill_sound()

func _process(delta: float) -> void:
	# Fade impact flashes — runs regardless of hub/game-over state
	if _flash_cells.size() > 0:
		var to_remove: Array = []
		for pos_key in _flash_cells:
			_flash_cells[pos_key] -= delta * 5.0
			if _flash_cells[pos_key] <= 0.0:
				to_remove.append(pos_key)
		for k in to_remove:
			_flash_cells.erase(k)
		queue_redraw()

	if _hub_visible or _game_over:
		return  # Block all movement while the surface hub is open or game-over screen shows
	_update_interact_prompt()
	# Determine which direction (if any) is currently held
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		dir = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir = Vector2i(1, 0)
	elif Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		dir = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		dir = Vector2i(0, 1)

	# Reset timers whenever the held direction changes (including key release)
	if dir != _held_dir:
		_held_dir = dir
		_hold_time = 0.0
		_auto_move_time = 0.0

	if _held_dir == Vector2i.ZERO:
		return

	# Accumulate hold time; auto-repeat only kicks in after the delay
	_hold_time += delta
	if _hold_time < AUTO_MOVE_DELAY:
		return

	_auto_move_time += delta
	if _auto_move_time >= AUTO_MOVE_INTERVAL:
		_auto_move_time -= AUTO_MOVE_INTERVAL
		_try_move(_held_dir.x, _held_dir.y)

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _hub_visible or _game_over:
		return  # Hub or game-over screen captures input
	if event.is_action_pressed("ui_cancel"):
		pause_menu.show_menu()
		return

	if event.is_action_pressed("ui_left"):
		_try_move(-1, 0)
	elif event.is_action_pressed("ui_right"):
		_try_move(1, 0)
	elif event.is_action_pressed("ui_up"):
		_try_move(0, -1)
	elif event.is_action_pressed("ui_down"):
		_try_move(0, 1)
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A: _try_move(-1, 0)
			KEY_D: _try_move(1, 0)
			KEY_W: _try_move(0, -1)
			KEY_S: _try_move(0, 1)

func _try_move(dc: int, dr: int) -> void:
	var new_col := player_grid_pos.x + dc
	var new_row := player_grid_pos.y + dr

	# Bounds check
	if new_col < 0 or new_col >= GRID_COLS or new_row < 0 or new_row >= GRID_ROWS:
		return

	var tile: int = grid[new_col][new_row]
	var current_tile: int = grid[player_grid_pos.x][player_grid_pos.y]
	var was_on_surface := current_tile == TileType.SURFACE

	# Surface movement rules
	if was_on_surface:
		# On surface: left/right only; allow downward to enter the mining area
		if dr != 0 and dr != 1:
			return
		if dr == 1:
			var new_tile: int = grid[new_col][new_row]
			if new_tile != TileType.EMPTY:
				# Entering the mining area: apply normal underground movement rules.
				if new_tile == TileType.LAVA or new_tile == TileType.LAVA_FLOW:
					_damage_player(1)
					return
				if new_tile == TileType.EXPLOSIVE or new_tile == TileType.EXPLOSIVE_ARMED:
					_mine_cell(new_col, new_row)
					_explode_area(new_col, new_row)
					_damage_player(1)
					queue_redraw()
					return
				if not GameManager.consume_fuel(1):
					_on_out_of_fuel()
					return
				# Don't move player until the target tile is cleared
				if new_tile == TileType.FUEL_NODE or new_tile == TileType.FUEL_NODE_FULL:
					_mine_cell(new_col, new_row)
					GameManager.restore_fuel(10)
					EventBus.ore_mined_popup.emit(10, "Fuel")
					SoundManager.play_drill_sound()
					player_grid_pos = Vector2i(new_col, new_row)
					is_on_surface = false
				elif new_tile == TileType.REFUEL_STATION:
					player_grid_pos = Vector2i(new_col, new_row)
					is_on_surface = false
				else:
					var pos_key := Vector2i(new_col, new_row)
					var tile_hp: int = TILE_HP.get(new_tile, 1)
					var new_damage: int = _tile_damage.get(pos_key, 0) + GameManager.get_mandibles_power()
					_flash_cells[pos_key] = 1.0
					if new_damage >= tile_hp:
						_tile_damage.erase(pos_key)
						_mine_cell(new_col, new_row)
						var minerals: int = TILE_MINERALS.get(new_tile, 1)
						GameManager.add_currency(minerals)
						EventBus.minerals_earned.emit(minerals)
						EventBus.ore_mined_popup.emit(minerals, TILE_NAMES.get(new_tile, "Mineral"))
						SoundManager.play_drill_sound()
						player_grid_pos = Vector2i(new_col, new_row)
						is_on_surface = false
					else:
						_tile_damage[pos_key] = new_damage
						SoundManager.play_impact_sound()
						queue_redraw()
						return  # Player stays on surface; no camera/depth update needed
				_update_camera()
				queue_redraw()
				return
			else:
				return
		player_grid_pos = Vector2i(new_col, new_row)
		is_on_surface = (grid[new_col][new_row] == TileType.SURFACE)
		_update_depth()
		_update_camera()
		queue_redraw()
		if grid[new_col][new_row] == TileType.EXIT_STATION:
			_show_surface_hub()
			return
		return

	# Below surface: hazard checks first
	if tile == TileType.LAVA:
		_damage_player(1)
		return

	if tile == TileType.EXPLOSIVE:
		_mine_cell(new_col, new_row)
		_explode_area(new_col, new_row)
		_damage_player(1)
		queue_redraw()
		return

	# Fuel cost for underground movement
	if not GameManager.consume_fuel(1):
		_on_out_of_fuel()
		return

	# Returning to surface from below
	if grid[new_col][new_row] == TileType.SURFACE:
		player_grid_pos = Vector2i(new_col, new_row)
		is_on_surface = true
		_update_depth()
		_update_camera()
		queue_redraw()
		return

	# Move player or deal damage — depends on tile hardness
	var player_moved := false

	if tile == TileType.FUEL_NODE or tile == TileType.FUEL_NODE_FULL:
		_mine_cell(new_col, new_row)
		GameManager.restore_fuel(10)
		EventBus.ore_mined_popup.emit(10, "Fuel")
		SoundManager.play_drill_sound()
		player_grid_pos = Vector2i(new_col, new_row)
		player_moved = true
	elif tile == TileType.REFUEL_STATION or tile == TileType.EMPTY:
		player_grid_pos = Vector2i(new_col, new_row)
		player_moved = true
	else:
		# Minable tile: apply mandibles damage; move in only when destroyed
		var pos_key := Vector2i(new_col, new_row)
		var tile_hp: int = TILE_HP.get(tile, 1)
		var new_damage: int = _tile_damage.get(pos_key, 0) + GameManager.get_mandibles_power()
		_flash_cells[pos_key] = 1.0
		if new_damage >= tile_hp:
			_tile_damage.erase(pos_key)
			_mine_cell(new_col, new_row)
			var minerals: int = TILE_MINERALS.get(tile, 1)
			GameManager.add_currency(minerals)
			EventBus.minerals_earned.emit(minerals)
			EventBus.ore_mined_popup.emit(minerals, TILE_NAMES.get(tile, "Mineral"))
			SoundManager.play_drill_sound()
			player_grid_pos = Vector2i(new_col, new_row)
			player_moved = true
		else:
			_tile_damage[pos_key] = new_damage
			SoundManager.play_impact_sound()

	if player_moved:
		# Track first departure from spawn zone
		if new_col < GRID_COLS - EXIT_COLS:
			has_left_spawn = true

		# Reaching exit after having mined = prompt the surface hub
		if has_left_spawn and new_col >= GRID_COLS - EXIT_COLS:
			_update_depth()
			_update_camera()
			queue_redraw()
			_show_surface_hub()
			return

	_update_depth()
	_update_camera()
	queue_redraw()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _mine_cell(col: int, row: int) -> void:
	grid[col][row] = TileType.EMPTY

func _explode_area(center_col: int, center_row: int) -> void:
	for dc in range(-1, 2):
		for dr in range(-1, 2):
			var nc := center_col + dc
			var nr := center_row + dr
			if nc >= 0 and nc < GRID_COLS and nr >= 0 and nr < GRID_ROWS:
				grid[nc][nr] = TileType.EMPTY
	SoundManager.play_explosion_sound()
	_shake_camera(6.0, 0.35)

func _damage_player(amount: int) -> void:
	if player_node and player_node.has_method("take_damage"):
		player_node.take_damage(amount)

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
	var depth: int = maxi(0, player_grid_pos.y - SURFACE_ROWS)
	if depth != _last_depth:
		_last_depth = depth
		EventBus.depth_changed.emit(depth)

# ---------------------------------------------------------------------------
# Surface Hub — the mine's shop/bank at the Exit Station
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

	# Full-screen semi-transparent overlay — also blocks world input
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.70)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_hub_layer.add_child(dim)

	# Coloured border (drawn first, sits behind the panel)
	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.30, 0.70, 0.25, 1.0)
	_hub_layer.add_child(border)

	# Panel background
	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.09, 0.08, 0.06, 0.97)
	_hub_layer.add_child(panel)

	# Title
	var title := Label.new()
	title.text = "You surfaced!"
	title.position = Vector2(PX, PY + 14)
	title.size = Vector2(PANEL_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_layer.add_child(title)

	# Minerals sub-label (updated dynamically when hub opens)
	_hub_minerals_label = Label.new()
	_hub_minerals_label.position = Vector2(PX, PY + 50)
	_hub_minerals_label.size = Vector2(PANEL_W, 28)
	_hub_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_minerals_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
	_hub_layer.add_child(_hub_minerals_label)

	# Divider line
	var divider := ColorRect.new()
	divider.position = Vector2(PX + 20, PY + 86)
	divider.size = Vector2(PANEL_W - 40, 2)
	divider.color = Color(0.30, 0.70, 0.25, 0.6)
	_hub_layer.add_child(divider)

	# Button setup helper
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
# In-mine upgrade overlay — Colony Shop accessible from the Exit Station
# ---------------------------------------------------------------------------

func _open_upgrade_overlay() -> void:
	const VW: int = 1280
	const VH: int = 720

	_upgrade_layer = CanvasLayer.new()
	_upgrade_layer.layer = 10
	add_child(_upgrade_layer)

	# Dim backdrop
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_layer.add_child(dim)

	# UpgradeMenu scene
	var upgrade_scene := load("res://src/ui/UpgradeMenu.tscn") as PackedScene
	if upgrade_scene:
		var upgrade_menu: Node = upgrade_scene.instantiate()
		# Centre it on screen
		if upgrade_menu is Control:
			(upgrade_menu as Control).set_anchors_preset(Control.PRESET_CENTER)
		_upgrade_layer.add_child(upgrade_menu)

	# "Continue Mining" close button
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
