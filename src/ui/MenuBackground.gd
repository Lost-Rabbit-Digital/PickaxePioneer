extends Node2D

# MenuBackground
# Infinitely scrolling procedural mining level background for the main menu.
# Tile generation mirrors MiningLevel so the visual language is consistent.
#
# Interaction:
#   - Click and drag anywhere on the background to pan manually.
#   - Scroll wheel zooms in/out of the terrain (clamped to ZOOM_MIN/ZOOM_MAX).
#   - Releasing a drag carries momentum that decays gradually.
#   - After IDLE_TIMEOUT seconds of no interaction the background picks a new
#     random direction and resumes slow auto-panning.

const CELL_SIZE: int = 64
const GRID_ROWS: int = 20       # 20 * 64 = 1280 px – seamless vertical wrap
const GRID_COLS: int = 40       # 40 * 64 = 2560 px – seamless horizontal wrap
const AUTO_PAN_SPEED: float = 40.0  # Pixels per second during auto-pan
const IDLE_TIMEOUT: float = 3.0     # Seconds before auto-pan resumes after interaction

# Cave and tunnel generation
const CAVE_COUNT: int = 7           # Number of cave pockets carved into the terrain
const CAVE_RADIUS_MIN: int = 1      # Minimum cave radius in tiles
const CAVE_RADIUS_MAX: int = 3      # Maximum cave radius in tiles
const TUNNEL_COUNT: int = 9         # Number of drunkard-walk tunnel passages
const TUNNEL_LENGTH_MIN: int = 8    # Minimum tunnel length in steps
const TUNNEL_LENGTH_MAX: int = 22   # Maximum tunnel length in steps

# Momentum / inertia tuning
const MOMENTUM_DAMPING: float = 0.97        # Velocity multiplier per 60-fps tick (frame-rate independent)
const MOMENTUM_THRESHOLD: float = 0.5       # px/s – below this speed momentum is considered stopped
const DRAG_VEL_BLEND: float = 0.70          # How aggressively drag_velocity tracks instantaneous motion

# Zoom tuning
const ZOOM_MIN: float = 0.5                 # Furthest zoom out (half tile size)
const ZOOM_MAX: float = 3.0                 # Closest zoom in (3× tile size)
const ZOOM_STEP: float = 0.15              # Zoom amount per scroll-wheel notch

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

# Momentum / inertia state
var momentum_velocity: Vector2 = Vector2.ZERO   # Current throw velocity
var drag_velocity: Vector2 = Vector2.ZERO        # Rolling velocity estimate during drag
var _mouse_delta_acc: Vector2 = Vector2.ZERO     # Mouse motion accumulated this frame

# Zoom state
var zoom_level: float = 1.0                     # Current zoom multiplier (clamped to ZOOM_MIN/ZOOM_MAX)

func _ready() -> void:
	# Nearest-neighbour filtering keeps pixel-art tiles crisp
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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
	_carve_caves()
	_carve_tunnels()

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

# Carve irregular cave pockets by setting cells to EMPTY within a randomised radius.
func _carve_caves() -> void:
	for _i in range(CAVE_COUNT):
		var cx: int = randi() % GRID_COLS
		var cy: int = randi() % GRID_ROWS
		var radius: int = CAVE_RADIUS_MIN + randi() % (CAVE_RADIUS_MAX - CAVE_RADIUS_MIN + 1)
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				# Irregular cave edges: each cell uses its own random threshold
				var dist_sq := float(dx * dx + dy * dy)
				var max_sq := float(radius * radius)
				if dist_sq <= max_sq * randf_range(0.55, 1.0):
					var r: int = ((cy + dy) % GRID_ROWS + GRID_ROWS) % GRID_ROWS
					var c: int = ((cx + dx) % GRID_COLS + GRID_COLS) % GRID_COLS
					tile_grid[r][c] = TileType.EMPTY

# Carve winding tunnel passages using a drunkard's walk.
func _carve_tunnels() -> void:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for _i in range(TUNNEL_COUNT):
		var cx: int = randi() % GRID_COLS
		var cy: int = randi() % GRID_ROWS
		var length: int = TUNNEL_LENGTH_MIN + randi() % (TUNNEL_LENGTH_MAX - TUNNEL_LENGTH_MIN + 1)
		var dir: Vector2i = dirs[randi() % dirs.size()]
		for _step in range(length):
			tile_grid[cy][cx] = TileType.EMPTY
			# 25 % chance to turn, giving natural bends
			if randf() < 0.25:
				dir = dirs[randi() % dirs.size()]
			cx = ((cx + dir.x) % GRID_COLS + GRID_COLS) % GRID_COLS
			cy = ((cy + dir.y) % GRID_ROWS + GRID_ROWS) % GRID_ROWS

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					is_dragging = true
					is_autopanning = false
					momentum_velocity = Vector2.ZERO
					drag_velocity = Vector2.ZERO
					_mouse_delta_acc = Vector2.ZERO
					idle_timer = 0.0
					get_viewport().set_input_as_handled()
				else:
					is_dragging = false
					# Transfer the drag velocity as throw momentum
					momentum_velocity = drag_velocity
					drag_velocity = Vector2.ZERO
					_mouse_delta_acc = Vector2.ZERO
					idle_timer = 0.0
					get_viewport().set_input_as_handled()

			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_apply_zoom(ZOOM_STEP)
					is_autopanning = false
					idle_timer = 0.0
					get_viewport().set_input_as_handled()

			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_apply_zoom(-ZOOM_STEP)
					is_autopanning = false
					idle_timer = 0.0
					get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		# Drag right → world scrolls left. Divide by zoom so dragging feels
		# consistent: one screen-pixel of drag always moves the same apparent amount.
		var world_delta: Vector2 = (event as InputEventMouseMotion).relative / zoom_level
		scroll_offset -= world_delta
		_mouse_delta_acc -= world_delta
		idle_timer = 0.0
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if is_dragging:
		# Continuously estimate drag velocity so releasing feels natural
		if delta > 0.0:
			var instant := _mouse_delta_acc / delta
			drag_velocity = drag_velocity.lerp(instant, DRAG_VEL_BLEND)
		_mouse_delta_acc = Vector2.ZERO

	elif momentum_velocity.length_squared() > MOMENTUM_THRESHOLD * MOMENTUM_THRESHOLD:
		# Coast with throw momentum; damp it each frame (frame-rate independent)
		scroll_offset += momentum_velocity * delta
		momentum_velocity *= pow(MOMENTUM_DAMPING, delta * 60.0)
		_wrap_scroll()

	elif is_autopanning:
		scroll_offset += auto_pan_velocity * delta
		_wrap_scroll()

	else:
		idle_timer += delta
		if idle_timer >= IDLE_TIMEOUT:
			_pick_random_direction()
			is_autopanning = true
			idle_timer = 0.0

	queue_redraw()

func _apply_zoom(delta_zoom: float) -> void:
	var old_zoom := zoom_level
	zoom_level = clamp(zoom_level + delta_zoom, ZOOM_MIN, ZOOM_MAX)
	# Keep the viewport centre anchored in world space when zooming
	var vp_center := get_viewport_rect().size * 0.5
	scroll_offset += vp_center * (1.0 / old_zoom - 1.0 / zoom_level)

func _wrap_scroll() -> void:
	var gw: float = float(GRID_COLS * CELL_SIZE)
	var gh: float = float(GRID_ROWS * CELL_SIZE)
	scroll_offset.x = fmod(scroll_offset.x, gw)
	scroll_offset.y = fmod(scroll_offset.y, gh)

func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# Dark earth background
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.08, 0.06, 0.04))

	var gw: float = float(GRID_COLS * CELL_SIZE)
	var gh: float = float(GRID_ROWS * CELL_SIZE)

	# Effective tile size in screen pixels after applying zoom
	var effective_cell: float = float(CELL_SIZE) * zoom_level

	# Normalise offset to [0, gw) × [0, gh) so modulo indexing works correctly
	var off_x: float = fmod(scroll_offset.x, gw)
	var off_y: float = fmod(scroll_offset.y, gh)
	if off_x < 0.0: off_x += gw
	if off_y < 0.0: off_y += gh

	# Grid cell sitting at the top-left corner of the screen
	var start_col: int = int(off_x / CELL_SIZE)
	var start_row: int = int(off_y / CELL_SIZE)

	# Sub-cell pixel offset scaled to screen space
	var pixel_off_x: float = fmod(off_x, float(CELL_SIZE)) * zoom_level
	var pixel_off_y: float = fmod(off_y, float(CELL_SIZE)) * zoom_level

	# +2: one partial tile at each edge
	var cols_to_draw: int = int(vp_size.x / effective_cell) + 2
	var rows_to_draw: int = int(vp_size.y / effective_cell) + 2

	for screen_row in range(rows_to_draw):
		var y: float = screen_row * effective_cell - pixel_off_y
		if y >= vp_size.y:
			break
		var tile_row: int = (start_row + screen_row) % GRID_ROWS
		for screen_col in range(cols_to_draw):
			var x: float = screen_col * effective_cell - pixel_off_x
			if x >= vp_size.x:
				break
			var tile_col: int = (start_col + screen_col) % GRID_COLS
			var tile: int = tile_grid[tile_row][tile_col]
			if tile == TileType.EMPTY:
				continue
			_draw_tile(tile, x, y, effective_cell)

func _draw_tile(tile: int, x: float, y: float, size: float) -> void:
	var tile_rect := Rect2(x, y, size, size)
	var tex: Texture2D = tile_textures.get(tile)
	if tex:
		draw_texture_rect(tex, tile_rect, false)
	else:
		draw_rect(tile_rect, TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5)))
