extends Node2D

# Grid-based Mining Level
# Player spawns on the right (exit zone) and moves LEFT to mine.
# Right EXIT_COLS columns are empty — returning there ends the run.

const GRID_COLS: int = 20
const GRID_ROWS: int = 11
const CELL_SIZE: int = 64
const EXIT_COLS: int = 2  # Rightmost columns are the exit/spawn zone

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
}

# Sprite indices for terrain spritesheet with 16x16 individual block sprites
const TILE_SPRITES: Dictionary = {
	TileType.DIRT:           0,  # dirt_block
	TileType.DIRT_DARK:      1,  # dark_dirt_block
	TileType.STONE:          2,  # stone_block
	TileType.STONE_DARK:     3,  # dark_stone_block
	TileType.ORE_COPPER:     4,  # copper_ore
	TileType.ORE_COPPER_DEEP: 5,  # deep_copper_ore
	TileType.ORE_IRON:       6,  # iron_ore
	TileType.ORE_IRON_DEEP:  7,  # deep_iron_ore
	TileType.ORE_GOLD:       8,  # gold_ore
	TileType.ORE_GOLD_DEEP:  9,  # deep_gold_ore
	TileType.ORE_GEM:        10, # gem_ore
	TileType.ORE_GEM_DEEP:   11, # deep_gem_ore
	TileType.EXPLOSIVE:      12, # explosive
	TileType.EXPLOSIVE_ARMED: 13, # armed_explosive
	TileType.LAVA:           14, # lava
	TileType.LAVA_FLOW:      15, # lava_flow
	TileType.FUEL_NODE:      16, # fuel_node
	TileType.FUEL_NODE_FULL: 17, # fuel_node_full
	TileType.REFUEL_STATION: 18, # refuel_station (special rendering adds border)
	TileType.SURFACE:        19, # surface
	TileType.SURFACE_GRASS:  20, # surface_grass
}

# Spritesheet layout: 18 pixels wide, 357 pixels tall for 21 sprites at 16x16 with 1px buffer
const SPRITE_SHEET_WIDTH: int = 18
const SPRITE_WIDTH: int = 16
const SPRITE_HEIGHT: int = 16
const SPRITE_BUFFER: int = 1

const TILE_SCRAP: Dictionary = {
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

# Textures
var player_texture: Texture2D
var scrap_pile_texture: Texture2D
var scrap_chunk_texture: Texture2D
var terrain_spritesheet: Texture2D
var sprite_atlases: Array[AtlasTexture] = []  # Pre-created atlas textures for each sprite

@onready var player_node = $PlayerProbe
@onready var pause_menu = $PauseMenu

func _ready() -> void:
	player_texture = load("res://assets/player_ship.svg")
	scrap_pile_texture = load("res://assets/scrap_pile.svg")
	scrap_chunk_texture = load("res://assets/scrap_chunk.svg")
	terrain_spritesheet = load("res://assets/terrain/terrain_spritesheet.png")

	# Pre-create AtlasTexture objects for each sprite in the sheet
	_create_sprite_atlases()

	_generate_grid()
	var music = load("res://assets/mine.mp3")
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
				# Mining area
				column.append(_random_tile())
		grid.append(column)

	# Place refuel station on surface (middle area)
	var refuel_col = GRID_COLS / 2
	grid[refuel_col][SURFACE_ROWS - 1] = TileType.REFUEL_STATION

func _random_tile() -> TileType:
	var r := randf()
	# Hazards (10% total)
	if   r < 0.04: return TileType.EXPLOSIVE
	elif r < 0.06: return TileType.EXPLOSIVE_ARMED  # 2% armed explosive
	elif r < 0.08: return TileType.LAVA
	elif r < 0.09: return TileType.LAVA_FLOW  # 1% lava flow
	# Fuel nodes (3% total)
	elif r < 0.11: return TileType.FUEL_NODE
	elif r < 0.12: return TileType.FUEL_NODE_FULL  # 1% full fuel
	# Copper ore (8% total)
	elif r < 0.16: return TileType.ORE_COPPER
	elif r < 0.18: return TileType.ORE_COPPER_DEEP  # 2% deep copper
	# Iron ore (8% total)
	elif r < 0.22: return TileType.ORE_IRON
	elif r < 0.25: return TileType.ORE_IRON_DEEP  # 3% deep iron
	# Gold ore (6% total)
	elif r < 0.29: return TileType.ORE_GOLD
	elif r < 0.31: return TileType.ORE_GOLD_DEEP  # 2% deep gold
	# Gem ore (4% total)
	elif r < 0.33: return TileType.ORE_GEM
	elif r < 0.35: return TileType.ORE_GEM_DEEP  # 2% deep gem
	# Stone (10% total)
	elif r < 0.42: return TileType.STONE
	elif r < 0.45: return TileType.STONE_DARK  # 3% dark stone
	# Dirt (48% total)
	elif r < 0.87: return TileType.DIRT
	else:          return TileType.DIRT_DARK  # 13% dark dirt

func _create_sprite_atlases() -> void:
	# Create 21 AtlasTexture objects for each sprite in the spritesheet
	# Spritesheet is laid out vertically with 1px buffer around each 16x16 sprite
	if not terrain_spritesheet:
		push_error("terrain_spritesheet failed to load! Check path: res://assets/terrain/terrain_spritesheet.png")
		return

	for i in range(21):
		var atlas = AtlasTexture.new()
		atlas.atlas = terrain_spritesheet
		var y_pos = SPRITE_BUFFER + i * (SPRITE_HEIGHT + SPRITE_BUFFER)
		atlas.region = Rect2(SPRITE_BUFFER, y_pos, SPRITE_WIDTH, SPRITE_HEIGHT)
		sprite_atlases.append(atlas)

func _draw() -> void:
	# Dark dirt background for the mining area
	draw_rect(
		Rect2(0, 0, (GRID_COLS - EXIT_COLS) * CELL_SIZE, GRID_ROWS * CELL_SIZE),
		Color(0.08, 0.06, 0.04)
	)

	# Exit zone — dark green background
	var exit_x := (GRID_COLS - EXIT_COLS) * CELL_SIZE
	draw_rect(
		Rect2(exit_x, 0, EXIT_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE),
		Color(0.05, 0.18, 0.05)
	)

	# Draw all tiles in the mining area and surface
	for col in range(GRID_COLS - EXIT_COLS):
		for row in range(GRID_ROWS):
			var tile: int = grid[col][row]
			if tile == TileType.EMPTY:
				continue

			var tile_screen_rect := Rect2(
				col * CELL_SIZE,
				row * CELL_SIZE,
				CELL_SIZE,
				CELL_SIZE
			)

			# Draw sprite from terrain spritesheet
			if sprite_atlases.size() > 0:
				var sprite_index = TILE_SPRITES.get(tile, 2)  # Default to dirt_block if not found
				var sprite_texture = sprite_atlases[sprite_index] if sprite_index < sprite_atlases.size() else sprite_atlases[0]
				if sprite_texture:
					draw_texture_rect(sprite_texture, tile_screen_rect, false)
				else:
					# Fallback to colored squares if texture fails to load
					var color = TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5))
					draw_rect(tile_screen_rect, color)
			else:
				# No sprite atlases loaded - draw colored squares as fallback
				var color = TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5))
				draw_rect(tile_screen_rect, color)

			# Draw refuel station border highlight
			if tile == TileType.REFUEL_STATION:
				draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4), Color.WHITE, false, 2.0)
				continue

			# Overlay SVG icon for ore nodes on top of sprite background
			var svg_rect := Rect2(
				col * CELL_SIZE + 6,
				row * CELL_SIZE + 6,
				CELL_SIZE - 12,
				CELL_SIZE - 12
			)
			match tile:
				TileType.ORE_COPPER, TileType.ORE_COPPER_DEEP, TileType.ORE_IRON, TileType.ORE_IRON_DEEP:
					if scrap_pile_texture:
						draw_texture_rect(scrap_pile_texture, svg_rect, false)
				TileType.ORE_GOLD, TileType.ORE_GOLD_DEEP, TileType.ORE_GEM, TileType.ORE_GEM_DEEP:
					if scrap_chunk_texture:
						draw_texture_rect(scrap_chunk_texture, svg_rect, false)

	# Draw player using player_ship.svg
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

	# Exit zone label
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(exit_x + 6, GRID_ROWS * CELL_SIZE / 2 - 6),
		"EXIT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 13,
		Color(0.4, 1.0, 0.4)
	)

func _unhandled_input(event: InputEvent) -> void:
	# Open pause menu with Escape
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
	var was_on_surface = current_tile == TileType.SURFACE

	# Check if trying to move on surface
	if was_on_surface:
		# Surface only allows left/right movement, except downward to enter mining area
		if dr != 0 and dr != 1:
			return
		# If moving down from surface, allow it (enters mining area)
		if dr == 1:
			# Allow moving down into mining area
			var new_tile = grid[new_col][new_row]
			if new_tile != TileType.EMPTY:
				player_grid_pos = Vector2i(new_col, new_row)
				is_on_surface = false
				queue_redraw()
				return
			else:
				return
		# Moving on surface is always allowed if in bounds
		player_grid_pos = Vector2i(new_col, new_row)
		is_on_surface = (grid[new_col][new_row] == TileType.SURFACE)
		queue_redraw()
		return

	# Below surface: check for hazards and fuel
	if tile == TileType.LAVA:
		# Lava burns — can't step in, but takes damage
		_damage_player(1)
		return

	if tile == TileType.EXPLOSIVE:
		# Explosion — destroys 3×3 area around it, deals damage; player stays put
		_mine_cell(new_col, new_row)
		_explode_area(new_col, new_row)
		_damage_player(1)
		queue_redraw()
		return

	# Consume fuel for movement in mining area
	if not GameManager.consume_fuel(1):
		# Out of fuel - game over
		_on_out_of_fuel()
		return

	# Check if moving to surface from below
	if grid[new_col][new_row] == TileType.SURFACE:
		player_grid_pos = Vector2i(new_col, new_row)
		is_on_surface = true
		queue_redraw()
		return

	# Move player to target cell
	player_grid_pos = Vector2i(new_col, new_row)

	# Handle fuel nodes
	if tile == TileType.FUEL_NODE:
		_mine_cell(new_col, new_row)
		GameManager.restore_fuel(10)
		SoundManager.play_drill_sound()
	# Handle refuel station
	elif tile == TileType.REFUEL_STATION:
		# Try to refuel
		if GameManager.refuel_completely(10):
			SoundManager.play_drill_sound()
		else:
			# Not enough scrap - do nothing but move is still consumed
			pass
	# Handle regular mining
	elif tile != TileType.EMPTY:
		_mine_cell(new_col, new_row)
		var scrap: int = TILE_SCRAP.get(tile, 1)
		GameManager.add_currency(scrap)
		SoundManager.play_drill_sound()

	# Track when player first leaves spawn zone
	if new_col < GRID_COLS - EXIT_COLS:
		has_left_spawn = true

	# Reaching the exit zone AFTER having mined = run complete
	if has_left_spawn and new_col >= GRID_COLS - EXIT_COLS:
		queue_redraw()
		GameManager.complete_run()
		return

	queue_redraw()

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
