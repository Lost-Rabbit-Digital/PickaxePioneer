extends Node2D

# MenuBackground
# Infinitely scrolling procedural mining level background for the main menu.
# Uses blocks_atlas.png and foliage_atlas.png — exactly matching MiningLevel's
# visual language — instead of individual block PNGs.
#
# Terrain generation mirrors MiningTerrainGenerator: surface grass row,
# tile patches, lava lakes, ore veins, cave rooms, and tunnels.
# Foliage decorations (surface plants, cave coral, stalactites, webs) are
# placed via foliage_atlas.png, matching MiningLevel._spawn_decorations().
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
const SURFACE_ROWS: int = 2     # Sky rows (EMPTY) above the grass layer
const AUTO_PAN_SPEED: float = 40.0  # Pixels per second during auto-pan
const IDLE_TIMEOUT: float = 3.0     # Seconds before auto-pan resumes after interaction

# Atlas tile size in pixels (matches blocks_atlas.png and foliage_atlas.png grid)
const ATLAS_TILE_SIZE: int = 64

# Cave and tunnel generation
const CAVE_COUNT: int = 6           # Cave pockets carved into the terrain
const CAVE_RADIUS_MIN: int = 1
const CAVE_RADIUS_MAX: int = 3
const TUNNEL_COUNT: int = 9         # Drunkard-walk tunnel passages
const TUNNEL_LENGTH_MIN: int = 8
const TUNNEL_LENGTH_MAX: int = 22

# Foliage placement chances — matching MiningTerrainGenerator constants
const FOLIAGE_ABOVE_GRASS_CHANCE: float = 0.22
const CORAL_FLOOR_CHANCE:         float = 0.12
const CORAL_CEILING_CHANCE:       float = 0.12
const WEB_CHANCE:                 float = 0.015

# Momentum / inertia tuning
const MOMENTUM_DAMPING: float = 0.97        # Velocity multiplier per 60-fps tick
const MOMENTUM_THRESHOLD: float = 0.5       # px/s – below this momentum is stopped
const DRAG_VEL_BLEND: float = 0.70          # How aggressively drag_velocity tracks motion

# Zoom tuning
const ZOOM_MIN: float = 0.5
const ZOOM_MAX: float = 3.0
const ZOOM_STEP: float = 0.15

# ---------------------------------------------------------------------------
# Tile types — integer values identical to MiningLevel.TileType so atlas
# coordinate lookup tables stay in sync with no translation needed.
# ---------------------------------------------------------------------------
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
	ENERGY_NODE      = 17,
	SURFACE_GRASS    = 21,  # Matches MiningLevel.TileType.SURFACE_GRASS
}

# Atlas coordinates in blocks_atlas.png (64 px tiles).
# Values are identical to MiningLevel.TILE_ATLAS_COORDS.
const TILE_ATLAS_COORDS: Dictionary = {
	TileType.DIRT:             Vector2i(1, 2),   # dirt.png
	TileType.DIRT_DARK:        Vector2i(9, 4),   # mud.png
	TileType.STONE:            Vector2i(7, 7),   # stone_generic.png
	TileType.STONE_DARK:       Vector2i(4, 3),   # gravel.png
	TileType.ORE_COPPER:       Vector2i(0, 8),   # stone_ore_copper.png
	TileType.ORE_COPPER_DEEP:  Vector2i(0, 8),
	TileType.ORE_IRON:         Vector2i(2, 8),   # stone_ore_iron.png
	TileType.ORE_IRON_DEEP:    Vector2i(2, 8),
	TileType.ORE_GOLD:         Vector2i(1, 8),   # stone_ore_gold.png
	TileType.ORE_GOLD_DEEP:    Vector2i(1, 8),
	TileType.ORE_GEM:          Vector2i(8, 7),   # stone_generic_ore_crystalline.png
	TileType.ORE_GEM_DEEP:     Vector2i(8, 7),
	TileType.EXPLOSIVE:        Vector2i(5, 8),
	TileType.EXPLOSIVE_ARMED:  Vector2i(5, 8),
	TileType.LAVA:             Vector2i(5, 6),   # sand_ugly_3.png
	TileType.LAVA_FLOW:        Vector2i(5, 6),
	TileType.ENERGY_NODE:      Vector2i(9, 3),   # limestone.png
	TileType.SURFACE_GRASS:    Vector2i(1, 3),   # grass_side.png
}

# Fallback solid colours used when the atlas texture fails to load.
const TILE_COLORS: Dictionary = {
	TileType.DIRT:          Color(0.45, 0.28, 0.12),
	TileType.DIRT_DARK:     Color(0.35, 0.20, 0.08),
	TileType.ORE_COPPER:    Color(0.80, 0.50, 0.20),
	TileType.ORE_IRON:      Color(0.65, 0.65, 0.72),
	TileType.ORE_GOLD:      Color(1.00, 0.85, 0.10),
	TileType.ORE_GEM:       Color(0.15, 0.85, 0.75),
	TileType.STONE:         Color(0.50, 0.50, 0.50),
	TileType.STONE_DARK:    Color(0.40, 0.40, 0.40),
	TileType.EXPLOSIVE:     Color(0.90, 0.10, 0.10),
	TileType.LAVA:          Color(1.00, 0.45, 0.00),
	TileType.LAVA_FLOW:     Color(0.80, 0.30, 0.00),
	TileType.ENERGY_NODE:   Color(0.20, 0.60, 1.00),
	TileType.SURFACE_GRASS: Color(0.45, 0.72, 0.30),
}

# ---------------------------------------------------------------------------
# Foliage atlas coordinates in foliage_atlas.png (64 px tiles, 10-wide grid).
# Values are identical to MiningLevel's FOLIAGE_* constants.
# ---------------------------------------------------------------------------
const FOLIAGE_SURFACE_PLANT_ATLAS_COORDS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(2, 0), Vector2i(3, 0),
	Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(8, 1), Vector2i(9, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(6, 2), Vector2i(8, 2), Vector2i(9, 2),
	Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(9, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4),
	Vector2i(9, 6),
]
const FOLIAGE_CAVE_PLANT_ATLAS_COORDS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0), Vector2i(8, 0), Vector2i(9, 0),
	Vector2i(0, 1), Vector2i(1, 1),
	Vector2i(7, 2),
	Vector2i(0, 3), Vector2i(1, 3),
]
const FOLIAGE_STALACTITE_ATLAS_COORD: Vector2i = Vector2i(5, 2)
const FOLIAGE_WEB_ATLAS_COORD: Vector2i = Vector2i(7, 4)

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------

var _blocks_atlas: Texture2D = null
var _foliage_atlas: Texture2D = null

# 2D tile grid (row-major): tile_grid[row][col] = TileType int
var tile_grid: Array = []

# Foliage overlay: Vector2i(col, row) -> Vector2i atlas_coord
var foliage_dict: Dictionary = {}

# Scroll / pan state
var scroll_offset: Vector2 = Vector2.ZERO
var auto_pan_velocity: Vector2 = Vector2.ZERO
var is_dragging: bool = false
var idle_timer: float = 0.0
var is_autopanning: bool = true
var momentum_velocity: Vector2 = Vector2.ZERO
var drag_velocity: Vector2 = Vector2.ZERO
var _mouse_delta_acc: Vector2 = Vector2.ZERO

var zoom_level: float = 1.0

# ---------------------------------------------------------------------------
# Initialisation
# ---------------------------------------------------------------------------

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_blocks_atlas  = load("res://assets/blocks/blocks_atlas.png") as Texture2D
	_foliage_atlas = load("res://assets/blocks/plants/foliage_atlas.png") as Texture2D
	_init_tile_grid()
	_pick_random_direction()

func _init_tile_grid() -> void:
	tile_grid = []
	# Build base grid: sky rows, grass row, then depth-scaled underground
	for row in range(GRID_ROWS):
		var row_arr: Array = []
		for col in range(GRID_COLS):
			if row < SURFACE_ROWS:
				row_arr.append(TileType.EMPTY)          # sky / open space
			elif row == SURFACE_ROWS:
				row_arr.append(TileType.SURFACE_GRASS)  # grass surface layer
			else:
				row_arr.append(_random_tile(row))
		tile_grid.append(row_arr)

	_generate_tile_patches()
	_generate_lava_lakes()
	_generate_ore_veins()
	_carve_caves()
	_carve_tunnels()
	_generate_foliage()

func _pick_random_direction() -> void:
	var angle: float = randf() * TAU
	auto_pan_velocity = Vector2(cos(angle), sin(angle)) * AUTO_PAN_SPEED

# ---------------------------------------------------------------------------
# Terrain generation — mirrors MiningTerrainGenerator at a smaller scale
# ---------------------------------------------------------------------------

func _random_tile(row: int) -> TileType:
	var depth := float(row - SURFACE_ROWS) / float(GRID_ROWS - SURFACE_ROWS)
	var r := randf()

	var explosive_bias := (0.04 + depth * 0.10) * 0.45
	if r < explosive_bias * (2.0 / 3.0): return TileType.EXPLOSIVE
	elif r < explosive_bias:              return TileType.EXPLOSIVE_ARMED
	elif r < explosive_bias + 0.015:      return TileType.ENERGY_NODE

	var stone_chance := 0.10 + depth * 0.50
	var r2 := randf()
	if   r2 < stone_chance * 0.6:  return TileType.STONE_DARK
	elif r2 < stone_chance:         return TileType.STONE
	elif r2 < stone_chance + 0.10:  return TileType.DIRT_DARK
	else:                            return TileType.DIRT

## Elliptical stone masses, dark-dirt transition bands, and explosive clusters —
## matching the patch-based geological layering in MiningTerrainGenerator.
func _generate_tile_patches() -> void:
	# Stone masses
	for _i in range(4):
		var pc := randi() % GRID_COLS
		var pr := SURFACE_ROWS + 2 + randi() % maxi(1, GRID_ROWS - SURFACE_ROWS - 4)
		var depth := float(pr - SURFACE_ROWS) / float(GRID_ROWS - SURFACE_ROWS)
		var half_w := 2 + randi() % 5
		var half_h := 1 + randi() % 3
		var tile: TileType = TileType.STONE_DARK if depth > 0.45 else TileType.STONE
		for dc in range(-half_w, half_w + 1):
			for dr in range(-half_h, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell <= 1.0:
					var nc := (pc + dc + GRID_COLS) % GRID_COLS
					var nr := pr + dr
					if nr >= SURFACE_ROWS + 1 and nr < GRID_ROWS - 1:
						if tile_grid[nr][nc] in [TileType.DIRT, TileType.DIRT_DARK]:
							tile_grid[nr][nc] = tile

	# Dark-dirt transition bands
	for _i in range(4):
		var pc := randi() % GRID_COLS
		var pr := SURFACE_ROWS + 2 + randi() % maxi(1, GRID_ROWS - SURFACE_ROWS - 6)
		var half_w := 3 + randi() % 7
		var half_h := 1 + randi() % 3
		for dc in range(-half_w, half_w + 1):
			for dr in range(-half_h, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell <= 1.0:
					var nc := (pc + dc + GRID_COLS) % GRID_COLS
					var nr := pr + dr
					if nr >= SURFACE_ROWS + 1 and nr < GRID_ROWS - 1:
						if tile_grid[nr][nc] == TileType.DIRT:
							tile_grid[nr][nc] = TileType.DIRT_DARK

	# Explosive clusters
	for _i in range(3):
		var pc := randi() % GRID_COLS
		var pr := SURFACE_ROWS + 4 + randi() % maxi(1, GRID_ROWS - SURFACE_ROWS - 6)
		var radius := 1 + randi() % 2
		for dc in range(-radius, radius + 1):
			for dr in range(-radius, radius + 1):
				if dc * dc + dr * dr <= radius * radius:
					var nc := (pc + dc + GRID_COLS) % GRID_COLS
					var nr := pr + dr
					if nr >= SURFACE_ROWS + 1 and nr < GRID_ROWS - 1:
						if tile_grid[nr][nc] in [TileType.DIRT, TileType.DIRT_DARK, TileType.STONE, TileType.STONE_DARK]:
							if randf() < 0.55:
								tile_grid[nr][nc] = TileType.EXPLOSIVE if randf() < 0.65 else TileType.EXPLOSIVE_ARMED

## Bowl-shaped lava lakes (flat open top, rounded bottom) — matching
## MiningTerrainGenerator._generate_lava_lakes() at a smaller scale.
func _generate_lava_lakes() -> void:
	for _i in range(2):
		var cc := 3 + randi() % (GRID_COLS - 6)
		var cr := SURFACE_ROWS + 5 + randi() % maxi(1, GRID_ROWS - SURFACE_ROWS - 8)
		var half_w := 1 + randi() % 3
		var half_h := 1 + randi() % 3
		for dc in range(-half_w, half_w + 1):
			for dr in range(0, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell <= 1.0:
					var nc := (cc + dc + GRID_COLS) % GRID_COLS
					var nr := cr + dr
					if nr >= SURFACE_ROWS + 1 and nr < GRID_ROWS - 1:
						var iw := maxi(1, half_w - 1)
						var ih := maxi(1, half_h - 1)
						var inner_ell := float(dc * dc) / float(iw * iw) + float(dr * dr) / float(ih * ih)
						tile_grid[nr][nc] = TileType.LAVA if inner_ell <= 1.0 else TileType.LAVA_FLOW

## Depth-scaled ore veins with meander — matching MiningTerrainGenerator ore veins
## at a smaller scale (shorter veins, fewer per type).
func _generate_ore_veins() -> void:
	var specs: Array = [
		{"ore": TileType.ORE_COPPER, "ore_deep": TileType.ORE_COPPER_DEEP, "count": 3, "row_min": SURFACE_ROWS + 1, "row_max": GRID_ROWS - 4},
		{"ore": TileType.ORE_IRON,   "ore_deep": TileType.ORE_IRON_DEEP,   "count": 3, "row_min": SURFACE_ROWS + 2, "row_max": GRID_ROWS - 3},
		{"ore": TileType.ORE_GOLD,   "ore_deep": TileType.ORE_GOLD_DEEP,   "count": 2, "row_min": SURFACE_ROWS + 4, "row_max": GRID_ROWS - 2},
		{"ore": TileType.ORE_GEM,    "ore_deep": TileType.ORE_GEM_DEEP,    "count": 2, "row_min": SURFACE_ROWS + 7, "row_max": GRID_ROWS - 1},
	]
	for spec in specs:
		for _i in range(spec["count"]):
			var length := 4 + randi() % 7
			var row_range := maxi(1, spec["row_max"] - spec["row_min"] - length)
			var start_row: int = int(spec["row_min"]) + randi() % row_range
			var center_col := 2 + randi() % (GRID_COLS - 4)
			for i in range(length):
				var row: int = start_row + i
				if row >= GRID_ROWS - 1:
					break
				var ore_tile: TileType = spec["ore_deep"] if i > length / 2 else spec["ore"]
				if randf() < 0.35:
					center_col = clampi(center_col + (randi() % 3) - 1, 1, GRID_COLS - 2)
				if tile_grid[row][center_col] in [TileType.DIRT, TileType.DIRT_DARK, TileType.STONE, TileType.STONE_DARK]:
					tile_grid[row][center_col] = ore_tile

## Irregular cave pockets.
func _carve_caves() -> void:
	for _i in range(CAVE_COUNT):
		var cx: int = randi() % GRID_COLS
		var cy: int = SURFACE_ROWS + 1 + randi() % maxi(1, GRID_ROWS - SURFACE_ROWS - 2)
		var radius: int = CAVE_RADIUS_MIN + randi() % (CAVE_RADIUS_MAX - CAVE_RADIUS_MIN + 1)
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var dist_sq := float(dx * dx + dy * dy)
				var max_sq  := float(radius * radius)
				if dist_sq <= max_sq * randf_range(0.55, 1.0):
					var r: int = ((cy + dy) % GRID_ROWS + GRID_ROWS) % GRID_ROWS
					var c: int = ((cx + dx) % GRID_COLS + GRID_COLS) % GRID_COLS
					if r > SURFACE_ROWS:
						tile_grid[r][c] = TileType.EMPTY

## Drunkard-walk tunnels with optional 2-tile width — matching the
## wide-tunnel logic in MiningTerrainGenerator._carve_tunnels().
func _carve_tunnels() -> void:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for _i in range(TUNNEL_COUNT):
		var cx: int = randi() % GRID_COLS
		var cy: int = SURFACE_ROWS + 1 + randi() % maxi(1, GRID_ROWS - SURFACE_ROWS - 2)
		var length: int = TUNNEL_LENGTH_MIN + randi() % (TUNNEL_LENGTH_MAX - TUNNEL_LENGTH_MIN + 1)
		var is_wide: bool = randf() < 0.35
		var dir: Vector2i = dirs[randi() % dirs.size()]
		for _step in range(length):
			if cy > SURFACE_ROWS and cy < GRID_ROWS - 1:
				tile_grid[cy][cx] = TileType.EMPTY
				if is_wide:
					var perp := Vector2i(-dir.y, dir.x)
					var wx := ((cx + perp.x) % GRID_COLS + GRID_COLS) % GRID_COLS
					var wy := cy + perp.y
					if wy > SURFACE_ROWS and wy < GRID_ROWS - 1:
						tile_grid[wy][wx] = TileType.EMPTY
			if randf() < 0.25:
				dir = dirs[randi() % dirs.size()]
			cx = ((cx + dir.x) % GRID_COLS + GRID_COLS) % GRID_COLS
			cy = ((cy + dir.y) % GRID_ROWS + GRID_ROWS) % GRID_ROWS
			if cy <= SURFACE_ROWS:
				cy = SURFACE_ROWS + 1

# ---------------------------------------------------------------------------
# Foliage placement — mirrors MiningTerrainGenerator.generate_decorations()
# ---------------------------------------------------------------------------

func _generate_foliage() -> void:
	foliage_dict.clear()

	# Surface plants — row immediately above the grass layer
	var above_row: int = SURFACE_ROWS - 1
	if above_row >= 0:
		for col in range(GRID_COLS):
			if tile_grid[SURFACE_ROWS][col] == TileType.SURFACE_GRASS and tile_grid[above_row][col] == TileType.EMPTY:
				if randf() < FOLIAGE_ABOVE_GRASS_CHANCE:
					var ac: Vector2i = FOLIAGE_SURFACE_PLANT_ATLAS_COORDS[randi() % FOLIAGE_SURFACE_PLANT_ATLAS_COORDS.size()]
					foliage_dict[Vector2i(col, above_row)] = ac

	# Underground decorations — floor coral, stalactites, spider webs
	for col in range(1, GRID_COLS - 1):
		for row in range(SURFACE_ROWS + 3, GRID_ROWS - 1):
			if tile_grid[row][col] != TileType.EMPTY:
				continue
			var has_solid_below: bool = _is_decoration_solid(tile_grid[row + 1][col])
			var has_solid_above: bool = _is_decoration_solid(tile_grid[row - 1][col])

			if has_solid_below and randf() < CORAL_FLOOR_CHANCE:
				var ac: Vector2i = FOLIAGE_CAVE_PLANT_ATLAS_COORDS[randi() % FOLIAGE_CAVE_PLANT_ATLAS_COORDS.size()]
				foliage_dict[Vector2i(col, row)] = ac
			elif has_solid_above and randf() < CORAL_CEILING_CHANCE:
				foliage_dict[Vector2i(col, row)] = FOLIAGE_STALACTITE_ATLAS_COORD
			elif randf() < WEB_CHANCE:
				foliage_dict[Vector2i(col, row)] = FOLIAGE_WEB_ATLAS_COORD

func _is_decoration_solid(tile: int) -> bool:
	return tile not in [TileType.EMPTY, TileType.LAVA, TileType.LAVA_FLOW, TileType.ENERGY_NODE]

# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------

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
		var world_delta: Vector2 = (event as InputEventMouseMotion).relative / zoom_level
		scroll_offset -= world_delta
		_mouse_delta_acc -= world_delta
		idle_timer = 0.0
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Per-frame update
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	if is_dragging:
		if delta > 0.0:
			var instant := _mouse_delta_acc / delta
			drag_velocity = drag_velocity.lerp(instant, DRAG_VEL_BLEND)
		_mouse_delta_acc = Vector2.ZERO

	elif momentum_velocity.length_squared() > MOMENTUM_THRESHOLD * MOMENTUM_THRESHOLD:
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
	var vp_center := get_viewport_rect().size * 0.5
	scroll_offset += vp_center * (1.0 / old_zoom - 1.0 / zoom_level)

func _wrap_scroll() -> void:
	var gw: float = float(GRID_COLS * CELL_SIZE)
	var gh: float = float(GRID_ROWS * CELL_SIZE)
	scroll_offset.x = fmod(scroll_offset.x, gw)
	scroll_offset.y = fmod(scroll_offset.y, gh)

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _draw() -> void:
	var vp_size := get_viewport_rect().size

	# Dark space background behind all tiles
	draw_rect(Rect2(Vector2.ZERO, vp_size), Color(0.08, 0.06, 0.04))

	var gw: float = float(GRID_COLS * CELL_SIZE)
	var gh: float = float(GRID_ROWS * CELL_SIZE)

	var effective_cell: float = float(CELL_SIZE) * zoom_level

	var off_x: float = fmod(scroll_offset.x, gw)
	var off_y: float = fmod(scroll_offset.y, gh)
	if off_x < 0.0: off_x += gw
	if off_y < 0.0: off_y += gh

	var start_col: int = int(off_x / CELL_SIZE)
	var start_row: int = int(off_y / CELL_SIZE)

	var pixel_off_x: float = fmod(off_x, float(CELL_SIZE)) * zoom_level
	var pixel_off_y: float = fmod(off_y, float(CELL_SIZE)) * zoom_level

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

			# Draw background tile (sky/dirt/stone layer behind foreground)
			_draw_bg_tile(_bg_atlas_for_row(tile_row), x, y, effective_cell)

			# Draw terrain tile
			var tile: int = tile_grid[tile_row][tile_col]
			if tile != TileType.EMPTY:
				_draw_tile(tile, x, y, effective_cell)

			# Draw foliage overlay on top of (or instead of) terrain
			var fkey := Vector2i(tile_col, tile_row)
			if foliage_dict.has(fkey):
				_draw_foliage_tile(foliage_dict[fkey], x, y, effective_cell)

## Draw a single terrain tile sampled from blocks_atlas.png.
func _draw_tile(tile: int, x: float, y: float, size: float) -> void:
	var tile_rect := Rect2(x, y, size, size)
	if _blocks_atlas and TILE_ATLAS_COORDS.has(tile):
		var ac: Vector2i = TILE_ATLAS_COORDS[tile]
		var src := Rect2(ac.x * ATLAS_TILE_SIZE, ac.y * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE)
		draw_texture_rect_region(_blocks_atlas, tile_rect, src)
	else:
		draw_rect(tile_rect, TILE_COLORS.get(tile, Color(0.5, 0.5, 0.5)))

## Return the background atlas coord for a given tile_row.
## Rows 0..(SURFACE_ROWS-1): sky atlas (6, 7).
## Rows SURFACE_ROWS..(SURFACE_ROWS+9): dirt atlas (1, 2).
## Rows (SURFACE_ROWS+10)..end: stone atlas (7, 7).
func _bg_atlas_for_row(tile_row: int) -> Vector2i:
	const BG_DIRT_DEPTH: int = 10
	if tile_row < SURFACE_ROWS:
		return Vector2i(6, 7)
	elif tile_row < SURFACE_ROWS + BG_DIRT_DEPTH:
		return Vector2i(1, 2)
	else:
		return Vector2i(7, 7)

## Draw a background tile from blocks_atlas.png at reduced brightness (matching
## the 0.344 modulate on BackgroundTileMapLayer in MiningLevel).
func _draw_bg_tile(atlas_coord: Vector2i, x: float, y: float, size: float) -> void:
	if not _blocks_atlas:
		return
	var tile_rect := Rect2(x, y, size, size)
	var src := Rect2(atlas_coord.x * ATLAS_TILE_SIZE, atlas_coord.y * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE)
	draw_texture_rect_region(_blocks_atlas, tile_rect, src, false, Color(0.344, 0.344, 0.344))

## Draw a single foliage tile sampled from foliage_atlas.png.
func _draw_foliage_tile(atlas_coord: Vector2i, x: float, y: float, size: float) -> void:
	if not _foliage_atlas:
		return
	var tile_rect := Rect2(x, y, size, size)
	var src := Rect2(atlas_coord.x * ATLAS_TILE_SIZE, atlas_coord.y * ATLAS_TILE_SIZE, ATLAS_TILE_SIZE, ATLAS_TILE_SIZE)
	draw_texture_rect_region(_foliage_atlas, tile_rect, src)
