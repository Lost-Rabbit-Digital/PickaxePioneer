extends Node2D

# MenuBackground
# Infinitely scrolling procedural mining level background for the main menu.
# Tile generation mirrors MiningLevel so the visual language is consistent.
#
# Interaction:
#   - Click and drag anywhere on the background to pan manually.
#   - After IDLE_TIMEOUT seconds of no interaction the background picks a new
#     random direction and resumes slow auto-panning.

const CELL_SIZE: int = 64
const GRID_ROWS: int = 20       # 20 * 64 = 1280 px – seamless vertical wrap
const GRID_COLS: int = 40       # 40 * 64 = 2560 px – seamless horizontal wrap
const AUTO_PAN_SPEED: float = 40.0  # Pixels per second during auto-pan
const IDLE_TIMEOUT: float = 3.0     # Seconds before auto-pan resumes after interaction

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

# 2D tile grid: tile_grid[row][col] = TileType
var tile_grid: Array = []

# Current scroll position in pixels (any value; wraps during rendering)
var scroll_offset: Vector2 = Vector2.ZERO

# Auto-pan direction × speed (pixels per second)
var auto_pan_velocity: Vector2 = Vector2.ZERO

# Drag state
var is_dragging: bool = false

# Idle tracking
var idle_timer: float = 0.0
var is_autopanning: bool = true

func _ready() -> void:
	_load_tile_textures()
	_init_tile_grid()
	_pick_random_direction()

func _load_tile_textures() -> void:
	for tile_type in TILE_TEXTURE_PATHS:
		var path: String = TILE_TEXTURE_PATHS[tile_type]
		var tex := load(path) as Texture2D
		if tex:
			tile_textures[tile_type] = tex

func _init_tile_grid() -> void:
	tile_grid = []
	for _row in range(GRID_ROWS):
		var row_arr: Array = []
		for _col in range(GRID_COLS):
			row_arr.append(_random_tile())
		tile_grid.append(row_arr)

func _pick_random_direction() -> void:
	var angle: float = randf() * TAU
	auto_pan_velocity = Vector2(cos(angle), sin(angle)) * AUTO_PAN_SPEED

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			is_autopanning = false
			idle_timer = 0.0
			get_viewport().set_input_as_handled()
		else:
			is_dragging = false
			idle_timer = 0.0  # Begin countdown to resume auto-pan
	elif event is InputEventMouseMotion and is_dragging:
		# Drag right → world scrolls left (subtract relative motion)
		scroll_offset -= event.relative
		idle_timer = 0.0
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_autopanning:
		scroll_offset += auto_pan_velocity * delta
		# Wrap to avoid unbounded float growth
		var gw: float = float(GRID_COLS * CELL_SIZE)
		var gh: float = float(GRID_ROWS * CELL_SIZE)
		scroll_offset.x = fmod(scroll_offset.x, gw)
		scroll_offset.y = fmod(scroll_offset.y, gh)
	else:
		idle_timer += delta
		if idle_timer >= IDLE_TIMEOUT:
			_pick_random_direction()
			is_autopanning = true
			idle_timer = 0.0

	queue_redraw()

func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# Dark earth background
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.08, 0.06, 0.04))

	var gw: float = float(GRID_COLS * CELL_SIZE)
	var gh: float = float(GRID_ROWS * CELL_SIZE)

	# Normalise offset to [0, gw) × [0, gh) so modulo indexing works correctly
	var off_x: float = fmod(scroll_offset.x, gw)
	var off_y: float = fmod(scroll_offset.y, gh)
	if off_x < 0.0: off_x += gw
	if off_y < 0.0: off_y += gh

	# Grid cell sitting at the top-left corner of the screen
	var start_col: int = int(off_x / CELL_SIZE)
	var start_row: int = int(off_y / CELL_SIZE)

	# Sub-cell pixel offset (how far into the top-left tile we are)
	var pixel_off_x: float = fmod(off_x, float(CELL_SIZE))
	var pixel_off_y: float = fmod(off_y, float(CELL_SIZE))

	# +2: one partial tile at each edge
	var cols_to_draw: int = int(vp_size.x / CELL_SIZE) + 2
	var rows_to_draw: int = int(vp_size.y / CELL_SIZE) + 2

	for screen_row in range(rows_to_draw):
		var y: float = screen_row * CELL_SIZE - pixel_off_y
		if y >= vp_size.y:
			break
		var tile_row: int = (start_row + screen_row) % GRID_ROWS
		for screen_col in range(cols_to_draw):
			var x: float = screen_col * CELL_SIZE - pixel_off_x
			if x >= vp_size.x:
				break
			var tile_col: int = (start_col + screen_col) % GRID_COLS
			var tile: int = tile_grid[tile_row][tile_col]
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
