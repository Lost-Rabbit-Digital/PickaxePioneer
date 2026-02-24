extends Node2D

# MenuBackground
# Infinitely scrolling procedural mining level background for the main menu.
# Tile generation mirrors MiningLevel so the visual language is consistent.

const CELL_SIZE: int = 64
const GRID_ROWS: int = 12        # 12 * 64 = 768, covers 720-high viewport
const SCROLL_SPEED: float = 40.0 # Pixels per second (50% of original 80)
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
	TileType.DIRT:        Color(0.45, 0.28, 0.12),  # Brown
	TileType.ORE_COPPER:  Color(0.80, 0.50, 0.20),  # Copper orange
	TileType.ORE_IRON:    Color(0.65, 0.65, 0.72),  # Iron silver
	TileType.ORE_GOLD:    Color(1.00, 0.85, 0.10),  # Gold yellow
	TileType.ORE_GEM:     Color(0.15, 0.85, 0.75),  # Gem cyan
	TileType.EXPLOSIVE:   Color(0.90, 0.10, 0.10),  # Explosive red
	TileType.LAVA:        Color(1.00, 0.45, 0.00),  # Lava orange
}

# SVG textures for ore node overlays (matches MiningLevel rendering)
var scrap_pile_texture: Texture2D
var scrap_chunk_texture: Texture2D

# Each element is a Dictionary: { "tiles": Array[TileType], "x": float }
var columns: Array = []
var scroll_y: float = 0.0  # Vertical scroll offset in pixels

func _ready() -> void:
	scrap_pile_texture = load("res://assets/scrap_pile.svg")
	scrap_chunk_texture = load("res://assets/scrap_chunk.svg")
	_init_columns()

func _init_columns() -> void:
	columns = []
	# Start one column to the left for a left-side buffer
	for i in range(VISIBLE_COLS):
		columns.append({
			"tiles": _generate_column(),
			"x": float((i - 1) * CELL_SIZE),
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
	# Shift every column rightward (scroll right) and advance vertical offset (scroll down)
	for col_data in columns:
		col_data["x"] += SCROLL_SPEED * delta

	var grid_height: float = float(GRID_ROWS * CELL_SIZE)
	scroll_y = fmod(scroll_y + SCROLL_SPEED * delta, grid_height)

	# Find the current leftmost x so recycled columns land left of it
	var leftmost_x: float = INF
	for col_data in columns:
		if col_data["x"] < leftmost_x:
			leftmost_x = col_data["x"]

	# Recycle any column whose left edge has fully exited the right side
	var vp_width: float = get_viewport_rect().size.x
	for col_data in columns:
		if col_data["x"] >= vp_width:
			leftmost_x -= float(CELL_SIZE)
			col_data["x"] = leftmost_x
			col_data["tiles"] = _generate_column()

	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# Dark earth background
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.08, 0.06, 0.04))

	# Compute which tile row is at the top and the sub-tile pixel offset
	var tile_start_idx: int = int(scroll_y / CELL_SIZE)
	var pixel_offset: float = fmod(scroll_y, CELL_SIZE)

	for col_data in columns:
		var x: float = col_data["x"]
		# Skip columns outside horizontal viewport
		if x + CELL_SIZE < 0.0 or x >= vp_size.x:
			continue
		var tiles: Array = col_data["tiles"]
		# Draw GRID_ROWS + 1 rows to cover the partial tile at the top edge
		for screen_row in range(GRID_ROWS + 1):
			var y: float = screen_row * CELL_SIZE - pixel_offset
			if y >= vp_size.y:
				break
			var tile_idx: int = (tile_start_idx + screen_row) % GRID_ROWS
			var tile: int = tiles[tile_idx]
			if tile == TileType.EMPTY:
				continue
			_draw_tile(tile, x, y)

func _draw_tile(tile: int, x: float, y: float) -> void:
	draw_rect(
		Rect2(x + 1.0, y + 1.0, CELL_SIZE - 2.0, CELL_SIZE - 2.0),
		TILE_COLORS[tile]
	)
	# Overlay SVG icon for ore nodes (matches MiningLevel rendering)
	var svg_rect := Rect2(x + 6.0, y + 6.0, CELL_SIZE - 12.0, CELL_SIZE - 12.0)
	match tile:
		TileType.ORE_COPPER, TileType.ORE_IRON:
			if scrap_pile_texture:
				draw_texture_rect(scrap_pile_texture, svg_rect, false)
		TileType.ORE_GOLD, TileType.ORE_GEM:
			if scrap_chunk_texture:
				draw_texture_rect(scrap_chunk_texture, svg_rect, false)
