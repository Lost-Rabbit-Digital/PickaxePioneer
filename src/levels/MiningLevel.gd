extends Node2D

# Grid-based Mining Level
# Player spawns on the right (exit zone) and moves LEFT to mine.
# Right EXIT_COLS columns are empty — returning there ends the run.

const GRID_COLS: int = 20
const GRID_ROWS: int = 11
const CELL_SIZE: int = 64
const EXIT_COLS: int = 2  # Rightmost columns are the exit/spawn zone

enum TileType {
	EMPTY     = 0,
	DIRT      = 1,
	ORE_COPPER = 2,
	ORE_IRON  = 3,
	ORE_GOLD  = 4,
	ORE_GEM   = 5,
	EXPLOSIVE = 6,
	LAVA      = 7,
}

const TILE_COLORS: Dictionary = {
	TileType.DIRT:        Color(0.45, 0.28, 0.12),  # Brown
	TileType.ORE_COPPER:  Color(0.80, 0.50, 0.20),  # Copper orange
	TileType.ORE_IRON:    Color(0.65, 0.65, 0.72),  # Iron silver
	TileType.ORE_GOLD:    Color(1.00, 0.85, 0.10),  # Gold yellow
	TileType.ORE_GEM:     Color(0.15, 0.85, 0.75),  # Gem cyan
	TileType.EXPLOSIVE:   Color(0.90, 0.10, 0.10),  # Explosive red
	TileType.LAVA:        Color(1.00, 0.45, 0.00),  # Lava orange
}

const TILE_SCRAP: Dictionary = {
	TileType.DIRT:       1,
	TileType.ORE_COPPER: 3,
	TileType.ORE_IRON:   5,
	TileType.ORE_GOLD:   10,
	TileType.ORE_GEM:    20,
}

var grid: Array = []
var player_grid_pos: Vector2i = Vector2i(GRID_COLS - 1, GRID_ROWS / 2)
var has_left_spawn: bool = false  # True once player moves into the mining area

@onready var player_node = $PlayerProbe

func _ready() -> void:
	_generate_grid()
	var music = load("res://assets/mine.mp3")
	MusicManager.play_music(music)
	QuestManager.clear_quest()
	queue_redraw()

func _generate_grid() -> void:
	grid = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			if col >= GRID_COLS - EXIT_COLS:
				column.append(TileType.EMPTY)
			else:
				column.append(_random_tile())
		grid.append(column)

func _random_tile() -> TileType:
	var r := randf()
	if   r < 0.06: return TileType.EXPLOSIVE
	elif r < 0.10: return TileType.LAVA
	elif r < 0.22: return TileType.ORE_COPPER
	elif r < 0.30: return TileType.ORE_IRON
	elif r < 0.35: return TileType.ORE_GOLD
	elif r < 0.37: return TileType.ORE_GEM
	else:          return TileType.DIRT

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

	# Draw all tiles in the mining area
	for col in range(GRID_COLS - EXIT_COLS):
		for row in range(GRID_ROWS):
			var tile: int = grid[col][row]
			if tile != TileType.EMPTY:
				draw_rect(
					Rect2(
						col * CELL_SIZE + 1,
						row * CELL_SIZE + 1,
						CELL_SIZE - 2,
						CELL_SIZE - 2
					),
					TILE_COLORS[tile]
				)

	# Draw player (cyan square)
	draw_rect(
		Rect2(
			player_grid_pos.x * CELL_SIZE + 2,
			player_grid_pos.y * CELL_SIZE + 2,
			CELL_SIZE - 4,
			CELL_SIZE - 4
		),
		Color(0.20, 0.80, 1.00)
	)

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

	# Move player to target cell
	player_grid_pos = Vector2i(new_col, new_row)

	if tile != TileType.EMPTY:
		# Mine the tile player stepped onto
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
