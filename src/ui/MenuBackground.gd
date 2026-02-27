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
	DIRT_DARK  = 2,
	ORE_COPPER = 3,
	ORE_IRON   = 4,
	ORE_GOLD   = 5,
	ORE_GEM    = 6,
	STONE      = 7,
	STONE_DARK = 8,
	EXPLOSIVE  = 9,
	LAVA       = 10,
}

const TILE_COLORS: Dictionary = {
	TileType.DIRT:       Color(0.45, 0.28, 0.12),  # Brown
	TileType.DIRT_DARK:  Color(0.35, 0.20, 0.08),  # Dark brown
	TileType.ORE_COPPER: Color(0.80, 0.50, 0.20),  # Copper orange
	TileType.ORE_IRON:   Color(0.65, 0.65, 0.72),  # Iron silver
	TileType.ORE_GOLD:   Color(1.00, 0.85, 0.10),  # Gold yellow
	TileType.ORE_GEM:    Color(0.15, 0.85, 0.75),  # Gem cyan
	TileType.STONE:      Color(0.50, 0.50, 0.50),  # Gray
	TileType.STONE_DARK: Color(0.40, 0.40, 0.40),  # Dark gray
	TileType.EXPLOSIVE:  Color(0.90, 0.10, 0.10),  # Explosive red
	TileType.LAVA:       Color(1.00, 0.45, 0.00),  # Lava orange
}

# Block textures matching MiningLevel's TILE_TEXTURE_PATHS
const TILE_TEXTURE_PATHS: Dictionary = {
	TileType.DIRT:       "res://assets/blocks/dirt.png",
	TileType.DIRT_DARK:  "res://assets/blocks/mud.png",
	TileType.ORE_COPPER: "res://assets/blocks/stone_generic_ore_nuggets.png",
	TileType.ORE_IRON:   "res://assets/blocks/gabbro.png",
	TileType.ORE_GOLD:   "res://assets/blocks/sandstone.png",
	TileType.ORE_GEM:    "res://assets/blocks/amethyst.png",
	TileType.STONE:      "res://assets/blocks/stone_generic.png",
	TileType.STONE_DARK: "res://assets/blocks/gravel.png",
	TileType.EXPLOSIVE:  "res://assets/blocks/eucalyptus_log_top.png",
	TileType.LAVA:       "res://assets/blocks/sand_ugly_3.png",
}

var tile_textures: Dictionary = {}

# Each element is a Dictionary: { "tiles": Array[TileType], "x": float }
var columns: Array = []
var scroll_y: float = 0.0  # Vertical scroll offset in pixels

func _ready() -> void:
	_load_tile_textures()
	_init_columns()

func _load_tile_textures() -> void:
	for tile_type in TILE_TEXTURE_PATHS:
		var path: String = TILE_TEXTURE_PATHS[tile_type]
		var tex := load(path) as Texture2D
		if tex:
			tile_textures[tile_type] = tex

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
	elif r < 0.50: return TileType.STONE_DARK
	elif r < 0.58: return TileType.STONE
	elif r < 0.68: return TileType.DIRT_DARK
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
	var tile_rect := Rect2(x, y, CELL_SIZE, CELL_SIZE)
	var tex: Texture2D = tile_textures.get(tile)
	if tex:
		draw_texture_rect(tex, tile_rect, false)
	else:
		draw_rect(tile_rect, TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5)))
