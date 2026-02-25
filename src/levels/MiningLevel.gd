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

const TILE_SCRAP: Dictionary = {
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

	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)
	QuestManager.clear_quest()
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
	var current_tile := grid[player_grid_pos.x][player_grid_pos.y]
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
				player_grid_pos = Vector2i(new_col, new_row)
				is_on_surface = false
				if new_tile == TileType.FUEL_NODE or new_tile == TileType.FUEL_NODE_FULL:
					_mine_cell(new_col, new_row)
					GameManager.restore_fuel(10)
					SoundManager.play_drill_sound()
				elif new_tile == TileType.REFUEL_STATION:
					pass  # Interact prompt handles refueling
				else:
					_mine_cell(new_col, new_row)
					var scrap: int = TILE_SCRAP.get(new_tile, 1)
					GameManager.add_currency(scrap)
					EventBus.scrap_earned.emit(scrap)
					SoundManager.play_drill_sound()
				_update_camera()
				queue_redraw()
				return
			else:
				return
		player_grid_pos = Vector2i(new_col, new_row)
		is_on_surface = (grid[new_col][new_row] == TileType.SURFACE)
		_update_camera()
		queue_redraw()
		if grid[new_col][new_row] == TileType.EXIT_STATION:
			GameManager.complete_run()
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
		_update_camera()
		queue_redraw()
		return

	# Move player
	player_grid_pos = Vector2i(new_col, new_row)

	if tile == TileType.FUEL_NODE or tile == TileType.FUEL_NODE_FULL:
		_mine_cell(new_col, new_row)
		GameManager.restore_fuel(10)
		SoundManager.play_drill_sound()
	elif tile == TileType.REFUEL_STATION:
		pass  # Interact prompt handles refueling
	elif tile != TileType.EMPTY:
		_mine_cell(new_col, new_row)
		var scrap: int = TILE_SCRAP.get(tile, 1)
		GameManager.add_currency(scrap)
		EventBus.scrap_earned.emit(scrap)
		SoundManager.play_drill_sound()

	# Track first departure from spawn zone
	if new_col < GRID_COLS - EXIT_COLS:
		has_left_spawn = true

	# Reaching exit after having mined = run complete
	if has_left_spawn and new_col >= GRID_COLS - EXIT_COLS:
		_update_camera()
		queue_redraw()
		GameManager.complete_run()
		return

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

func _damage_player(amount: int) -> void:
	if player_node and player_node.has_method("take_damage"):
		player_node.take_damage(amount)

func _on_out_of_fuel() -> void:
	print("Out of fuel! Game Over")
	GameManager.lose_run()
