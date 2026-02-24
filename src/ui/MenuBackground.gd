extends Node2D

# MenuBackground
# Infinitely scrolling procedural mining level background for the main menu.
# Tile generation mirrors MiningLevel so the visual language is consistent.

const CELL_SIZE: int = 64
const GRID_ROWS: int = 12        # 12 * 64 = 768, covers 720-high viewport
const SCROLL_SPEED: float = 80.0 # Pixels per second, rightward columns move left
const VISIBLE_COLS: int = 22     # 22 * 64 = 1408, covers 1280-wide viewport + buffer

enum TileType {
	EMPTY      = 0,
	DIRT       = 1,
	ORE_COPPER = 2,
	ORE_IRON   = 3,
	ORE_GOLD   = 4,
	ORE_GEM    = 5,
	EXPLOSIVE  = 6,
	LAVA       = 7,
}

const TILE_COLORS: Dictionary = {
	TileType.DIRT:        Color(0.45, 0.28, 0.12, 0.60),
	TileType.ORE_COPPER:  Color(0.80, 0.50, 0.20, 0.60),
	TileType.ORE_IRON:    Color(0.65, 0.65, 0.72, 0.60),
	TileType.ORE_GOLD:    Color(1.00, 0.85, 0.10, 0.60),
	TileType.ORE_GEM:     Color(0.15, 0.85, 0.75, 0.60),
	TileType.EXPLOSIVE:   Color(0.90, 0.10, 0.10, 0.60),
	TileType.LAVA:        Color(1.00, 0.45, 0.00, 0.60),
}

# Each element is a Dictionary: { "tiles": Array[TileType], "x": float }
var columns: Array = []

func _ready() -> void:
	_init_columns()

func _init_columns() -> void:
	columns = []
	for i in range(VISIBLE_COLS):
		columns.append({
			"tiles": _generate_column(),
			"x": float(i * CELL_SIZE),
		})

func _generate_column() -> Array:
	var col: Array = []
	for _row in range(GRID_ROWS):
		col.append(_random_tile())
	return col

func _random_tile() -> TileType:
	var r := randf()
	if   r < 0.06: return TileType.EXPLOSIVE
	elif r < 0.10: return TileType.LAVA
	elif r < 0.22: return TileType.ORE_COPPER
	elif r < 0.30: return TileType.ORE_IRON
	elif r < 0.35: return TileType.ORE_GOLD
	elif r < 0.37: return TileType.ORE_GEM
	else:          return TileType.DIRT

func _process(delta: float) -> void:
	# Shift every column leftward
	for col_data in columns:
		col_data["x"] -= SCROLL_SPEED * delta

	# Find the current rightmost x so recycled columns land right of it
	var rightmost_x: float = -INF
	for col_data in columns:
		if col_data["x"] > rightmost_x:
			rightmost_x = col_data["x"]

	# Recycle any column that has fully left the screen on the left side
	for col_data in columns:
		if col_data["x"] + CELL_SIZE < 0.0:
			rightmost_x += float(CELL_SIZE)
			col_data["x"] = rightmost_x
			col_data["tiles"] = _generate_column()

	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# Dark earth background
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.08, 0.06, 0.04))

	for col_data in columns:
		var x: float = col_data["x"]
		var tiles: Array = col_data["tiles"]
		for row in range(GRID_ROWS):
			var tile: int = tiles[row]
			if tile != TileType.EMPTY:
				draw_rect(
					Rect2(x + 1.0, row * CELL_SIZE + 1.0, CELL_SIZE - 2.0, CELL_SIZE - 2.0),
					TILE_COLORS[tile]
				)
