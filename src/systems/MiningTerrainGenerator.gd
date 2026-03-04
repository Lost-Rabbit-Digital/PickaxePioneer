class_name MiningTerrainGenerator
extends RefCounted

# ---------------------------------------------------------------------------
# Tile-type integer constants — must stay in sync with MiningLevel.TileType.
# ---------------------------------------------------------------------------
# Dedicated RNG — seeded once per generate() call so the same seed always
# produces the same terrain on any machine (critical for multiplayer sync).
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

const T_EMPTY            = 0
const T_DIRT             = 1
const T_DIRT_DARK        = 2
const T_ORE_COPPER       = 3
const T_ORE_COPPER_DEEP  = 4
const T_ORE_IRON         = 5
const T_ORE_IRON_DEEP    = 6
const T_ORE_GOLD         = 7
const T_ORE_GOLD_DEEP    = 8
const T_ORE_GEM          = 9
const T_ORE_GEM_DEEP     = 10
const T_STONE            = 11
const T_STONE_DARK       = 12
const T_EXPLOSIVE        = 13
const T_EXPLOSIVE_ARMED  = 14
const T_LAVA             = 15
const T_LAVA_FLOW        = 16
const T_ENERGY_NODE      = 17
const T_ENERGY_NODE_FULL = 18
const T_REENERGY_STATION = 19
const T_SURFACE          = 20
const T_SURFACE_GRASS    = 21
const T_EXIT_STATION     = 22
const T_UPGRADE_STATION  = 25
const T_SMELTERY_STATION = 26
const T_CAT_TAVERN       = 28

# Vein generation parameter
const VEIN_MEANDER_CHANCE: float = 0.35

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Fills `grid` with the initial tile layout, then generates ore veins, cave
## rooms, and connecting tunnels.  `grid` must already be an empty Array —
## this function will resize it to [cols][rows].
##
## `seed_value`       = deterministic seed; identical seeds produce identical terrain.
## `depth_zone_rows`  = MiningLevel.DEPTH_ZONE_ROWS (used for vein zone bounds)
func generate(
		grid: Array,
		cols: int,
		rows: int,
		surface_rows: int,
		exit_cols: int,
		depth_zone_rows: Array,
		allowed_ore_types: Array,
		allowed_hazard_types: Array,
		seed_value: int = 0) -> void:
	_rng.seed = seed_value
	_cols = cols
	_rows = rows
	_surface_rows = surface_rows
	_exit_cols = exit_cols
	_depth_zone_rows = depth_zone_rows
	_allowed_ore = allowed_ore_types
	_allowed_hazard = allowed_hazard_types
	_grid = grid

	_generate_grid()
	_generate_tile_patches()
	_generate_lava_lakes()
	_generate_ore_veins()
	_generate_cave_rooms()
	_carve_tunnels()

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _grid: Array
var _cols: int
var _rows: int
var _surface_rows: int
var _exit_cols: int
var _depth_zone_rows: Array
var _allowed_ore: Array
var _allowed_hazard: Array

# ---------------------------------------------------------------------------
# Grid initialisation
# ---------------------------------------------------------------------------

func _generate_grid() -> void:
	_grid.clear()
	for col in range(_cols):
		var column: Array = []
		for row in range(_rows):
			if row < _surface_rows:
				column.append(T_SURFACE)
			else:
				column.append(_random_tile(col, row))
		_grid.append(column)

	var reenergy_col := _cols / 2
	_grid[reenergy_col][_surface_rows - 1]     = T_REENERGY_STATION
	_grid[reenergy_col - 5][_surface_rows - 1] = T_UPGRADE_STATION
	_grid[reenergy_col + 5][_surface_rows - 1] = T_SMELTERY_STATION

	# Underground Cat Tavern — first sub-zone (~17 rows below surface)
	var tavern_col := clampi(reenergy_col + 10, 5, _cols - 6)
	_grid[tavern_col][_surface_rows + 17] = T_CAT_TAVERN

	_grid[_cols - 1][_surface_rows - 1] = T_EXIT_STATION

	for col in range(_cols - _exit_cols):
		_grid[col][_surface_rows]     = T_SURFACE_GRASS
	for col in range(_cols - _exit_cols):
		_grid[col][_surface_rows + 1] = T_DIRT
	for col in range(_cols - _exit_cols):
		_grid[col][_surface_rows + 2] = T_DIRT

func _random_tile(_col: int, row: int) -> int:
	var r := _rng.randf()
	var depth := float(row - _surface_rows) / float(_rows - _surface_rows)

	var explosive_ok := _allowed_hazard.is_empty() or _allowed_hazard.has("Explosives")
	var lava_ok      := _allowed_hazard.is_empty() or _allowed_hazard.has("Lava")

	var base_hazard    := 0.08 + depth * 0.20
	var explosive_bias := base_hazard * 0.45 if explosive_ok else 0.0
	# Lava reduced here — _generate_lava_lakes() handles grouped lava pools
	var lava_bias      := base_hazard * 0.10 if lava_ok      else 0.0
	var total_hazard   := explosive_bias + lava_bias

	if   r < explosive_bias * (2.0 / 3.0):       return T_EXPLOSIVE
	elif r < explosive_bias:                       return T_EXPLOSIVE_ARMED
	elif r < explosive_bias + lava_bias * 0.5:    return T_LAVA
	elif r < total_hazard:                         return T_LAVA_FLOW
	elif r < total_hazard + 0.02:                 return T_ENERGY_NODE
	elif r < total_hazard + 0.03:                 return T_ENERGY_NODE_FULL

	var stone_chance := 0.10 + depth * 0.50
	var r2 := _rng.randf()
	if   r2 < stone_chance * 0.6:   return T_STONE_DARK
	elif r2 < stone_chance:          return T_STONE
	elif r2 < stone_chance + 0.10:   return T_DIRT_DARK
	else:                             return T_DIRT

# ---------------------------------------------------------------------------
# Cave rooms
# ---------------------------------------------------------------------------

func _generate_cave_rooms() -> void:
	var num_rooms := _rng.randi_range(12, 18)
	for _i in range(num_rooms):
		var room_col  := _rng.randi_range(5, _cols - 8)
		var room_row  := _rng.randi_range(_surface_rows + 6, _rows - 8)
		# 25% chance of a large chamber
		var is_large  := _rng.randf() < 0.25
		var half_w    := _rng.randi_range(5, 11) if is_large else _rng.randi_range(3, 7)
		var half_h    := _rng.randi_range(3, 6)  if is_large else _rng.randi_range(2, 4)

		# Carve the interior
		for dc in range(-half_w, half_w + 1):
			for dr in range(-half_h, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell <= 0.85:
					var nc := room_col + dc
					var nr := room_row + dr
					if nc >= 1 and nc < _cols - 1 and nr >= _surface_rows + 1 and nr < _rows - 1:
						_grid[nc][nr] = T_EMPTY

		# Ore pockets around the edge
		var depth := float(room_row - _surface_rows) / float(_rows - _surface_rows)
		for dc in range(-half_w - 1, half_w + 2):
			for dr in range(-half_h - 1, half_h + 2):
				var ell := float(dc * dc) / float(half_w * half_w) + float(dr * dr) / float(half_h * half_h)
				if ell > 0.85 and ell <= 1.35:
					var nc := room_col + dc
					var nr := room_row + dr
					if nc >= 1 and nc < _cols - 1 and nr >= _surface_rows + 1 and nr < _rows - 1:
						if _rng.randf() < 0.20:
							var ore_tile := _depth_scaled_ore(depth)
							if ore_tile != T_EMPTY:
								_grid[nc][nr] = ore_tile

# ---------------------------------------------------------------------------
# Drunkard-walk tunnels
# ---------------------------------------------------------------------------

func _carve_tunnels() -> void:
	const TCOUNT   := 22
	const TLEN_MIN := 10
	const TLEN_MAX := 58
	var dirs: Array[Vector2i] = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	for _i in range(TCOUNT):
		var cx      := _rng.randi_range(3, _cols - 4)
		var cy      := _rng.randi_range(_surface_rows + 4, _rows - 5)
		var length  := _rng.randi_range(TLEN_MIN, TLEN_MAX)
		# 35% of tunnels are wide (2-tile) corridors
		var is_wide := _rng.randf() < 0.35
		var dir: Vector2i = dirs[_rng.randi() % dirs.size()]
		for _step in range(length):
			if cx >= 1 and cx < _cols - 1 and cy >= _surface_rows + 1 and cy < _rows - 1:
				_grid[cx][cy] = T_EMPTY
				var perp := Vector2i(-dir.y, dir.x)
				if is_wide:
					# Always carve the parallel tile for wide tunnels
					var wx := cx + perp.x
					var wy := cy + perp.y
					if wx >= 1 and wx < _cols - 1 and wy >= _surface_rows + 1 and wy < _rows - 1:
						_grid[wx][wy] = T_EMPTY
				elif _rng.randf() < 0.28:
					# Narrow tunnels: occasional side nub in either perpendicular direction
					var side := perp if _rng.randf() < 0.5 else Vector2i(-perp.x, -perp.y)
					var sx := cx + side.x
					var sy := cy + side.y
					if sx >= 1 and sx < _cols - 1 and sy >= _surface_rows + 1 and sy < _rows - 1:
						_grid[sx][sy] = T_EMPTY
			if _rng.randf() < 0.30:
				dir = dirs[_rng.randi() % dirs.size()]
			cx = clampi(cx + dir.x, 1, _cols - 2)
			cy = clampi(cy + dir.y, _surface_rows + 1, _rows - 2)

# ---------------------------------------------------------------------------
# Tile groupings — clustered patches of similar terrain
# ---------------------------------------------------------------------------

## After the baseline grid is filled, seed elliptical blobs that collect
## similar tile types together: stone masses, dark-dirt transition bands,
## and dense explosive clusters.  This makes the underground feel layered
## and geologically coherent rather than uniformly random.
func _generate_tile_patches() -> void:
	# --- Stone masses ---
	# Replace scattered dirt tiles with stone in elliptical blobs, biased
	# toward darker stone at greater depth.
	var num_stone := _rng.randi_range(10, 16)
	for _i in range(num_stone):
		var pc    := _rng.randi_range(3, _cols - 4)
		var pr    := _rng.randi_range(_surface_rows + 8, _rows - 6)
		var depth := float(pr - _surface_rows) / float(_rows - _surface_rows)
		var half_w := _rng.randi_range(3, 9)
		var half_h := _rng.randi_range(2, 5)
		var tile   := T_STONE_DARK if depth > 0.45 else T_STONE
		for dc in range(-half_w, half_w + 1):
			for dr in range(-half_h, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) \
						 + float(dr * dr) / float(half_h * half_h)
				if ell <= 1.0:
					var nc := pc + dc
					var nr := pr + dr
					if nc >= 1 and nc < _cols - 1 and nr >= _surface_rows + 2 and nr < _rows - 1:
						if _grid[nc][nr] in [T_DIRT, T_DIRT_DARK]:
							_grid[nc][nr] = tile

	# --- Dark-dirt transition bands ---
	# Irregular blobs of dark dirt create transition zones between shallow
	# and deep regions, breaking up the uniform dirt layer.
	var num_dark := _rng.randi_range(8, 14)
	for _i in range(num_dark):
		var pc    := _rng.randi_range(3, _cols - 4)
		var pr    := _rng.randi_range(_surface_rows + 3, _rows - 12)
		var half_w := _rng.randi_range(4, 12)
		var half_h := _rng.randi_range(2, 5)
		for dc in range(-half_w, half_w + 1):
			for dr in range(-half_h, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) \
						 + float(dr * dr) / float(half_h * half_h)
				if ell <= 1.0:
					var nc := pc + dc
					var nr := pr + dr
					if nc >= 1 and nc < _cols - 1 and nr >= _surface_rows + 2 and nr < _rows - 1:
						if _grid[nc][nr] == T_DIRT:
							_grid[nc][nr] = T_DIRT_DARK

	# --- Explosive clusters ---
	# Dense pockets of explosives feel like old mining charges left behind
	# or unstable mineral pockets rather than random individual tiles.
	var explosive_ok := _allowed_hazard.is_empty() or _allowed_hazard.has("Explosives")
	if explosive_ok:
		var num_clusters := _rng.randi_range(5, 9)
		for _i in range(num_clusters):
			var pc     := _rng.randi_range(3, _cols - 4)
			var pr     := _rng.randi_range(_surface_rows + 10, _rows - 6)
			var radius := _rng.randi_range(2, 4)
			for dc in range(-radius, radius + 1):
				for dr in range(-radius, radius + 1):
					if dc * dc + dr * dr <= radius * radius:
						var nc := pc + dc
						var nr := pr + dr
						if nc >= 1 and nc < _cols - 1 and nr >= _surface_rows + 2 and nr < _rows - 1:
							if _grid[nc][nr] in [T_DIRT, T_DIRT_DARK, T_STONE, T_STONE_DARK]:
								if _rng.randf() < 0.55:
									_grid[nc][nr] = T_EXPLOSIVE if _rng.randf() < 0.65 else T_EXPLOSIVE_ARMED

# ---------------------------------------------------------------------------
# Lava lakes — bowl-shaped (semi-ellipse, open top) lava pools
# ---------------------------------------------------------------------------

## Generates lava pools shaped like a lake or bowl: flat open top, curved
## bottom.  The semi-ellipse extends *downward* from the centre row so the
## rounded side faces down — like a container of lava resting in the rock.
## The outer shell uses T_LAVA_FLOW and the dense interior uses T_LAVA.
func _generate_lava_lakes() -> void:
	var lava_ok := _allowed_hazard.is_empty() or _allowed_hazard.has("Lava")
	if not lava_ok:
		return

	var num_lakes := _rng.randi_range(5, 9)
	for _i in range(num_lakes):
		var center_col := _rng.randi_range(8, _cols - 9)
		# Keep lakes away from the very top and bottom of the mine
		var center_row := _rng.randi_range(_surface_rows + 18, _rows - 14)
		var half_w     := _rng.randi_range(2, 6)
		var half_h     := _rng.randi_range(2, 6)

		# dr = 0 is the flat surface (top) of the lake; dr > 0 descends into the bowl.
		# This produces the "circle on the bottom" semi-circle shape.
		for dc in range(-half_w, half_w + 1):
			for dr in range(0, half_h + 1):
				var ell := float(dc * dc) / float(half_w * half_w) \
						 + float(dr * dr) / float(half_h * half_h)
				if ell <= 1.0:
					var nc := center_col + dc
					var nr := center_row + dr
					if nc >= 1 and nc < _cols - 1 and nr >= _surface_rows + 2 and nr < _rows - 1:
						# Outer shell → lava flow; inner core → lava
						var iw  := maxi(1, half_w - 1)
						var ih  := maxi(1, half_h - 1)
						var inner_ell := float(dc * dc) / float(iw * iw) \
									  + float(dr * dr) / float(ih * ih)
						_grid[nc][nr] = T_LAVA if inner_ell <= 1.0 else T_LAVA_FLOW

# ---------------------------------------------------------------------------
# Hydrothermal ore vein generation
# ---------------------------------------------------------------------------

func _generate_ore_veins() -> void:
	var specs := [
		{
			"ore": T_ORE_COPPER, "ore_deep": T_ORE_COPPER_DEEP,
			"cap": -1, "cap_len": [0, 0],
			"zone":   [_surface_rows + 2, _depth_zone_rows[2]],
			"count":  [4, 7], "length": [14, 26], "width": [1, 2],
			"key": "Copper",
		},
		{
			"ore": T_ORE_IRON, "ore_deep": T_ORE_IRON_DEEP,
			"cap": T_ORE_COPPER_DEEP, "cap_len": [7, 14],
			"zone":   [_depth_zone_rows[1], _depth_zone_rows[3]],
			"count":  [4, 6], "length": [18, 32], "width": [1, 2],
			"key": "Iron",
		},
		{
			"ore": T_ORE_GOLD, "ore_deep": T_ORE_GOLD_DEEP,
			"cap": T_ORE_IRON_DEEP, "cap_len": [8, 16],
			"zone":   [_depth_zone_rows[2], _depth_zone_rows[4]],
			"count":  [3, 5], "length": [18, 32], "width": [1, 2],
			"key": "Gold",
		},
		{
			"ore": T_ORE_GEM, "ore_deep": T_ORE_GEM_DEEP,
			"cap": T_ORE_GOLD_DEEP, "cap_len": [10, 20],
			"zone":   [_depth_zone_rows[3], _rows - 2],
			"count":  [2, 4], "length": [14, 24], "width": [1, 2],
			"key": "Gem",
		},
	]

	for spec in specs:
		if not _allowed_ore.is_empty() and not _allowed_ore.has(spec["key"]):
			continue
		var count := _rng.randi_range(spec["count"][0], spec["count"][1])
		for _i in range(count):
			_place_ore_vein(spec)

func _place_ore_vein(spec: Dictionary) -> void:
	var zone_start: int = spec["zone"][0]
	var zone_end:   int = spec["zone"][1]
	var length:     int = _rng.randi_range(spec["length"][0], spec["length"][1])
	var width:      int = _rng.randi_range(spec["width"][0],  spec["width"][1])

	var max_start  := maxi(zone_start, zone_end - length)
	var start_row  := _rng.randi_range(zone_start, max_start)
	var center_col := _rng.randi_range(3, _cols - 4)

	var cap_len: int = 0
	if spec["cap"] != -1:
		cap_len = _rng.randi_range(spec["cap_len"][0], spec["cap_len"][1])
		cap_len = mini(cap_len, length - 4)

	for i in range(length):
		var row := start_row + i
		if row < _surface_rows + 1 or row >= _rows - 1:
			continue

		var ore_tile: int
		if i < cap_len:
			ore_tile = spec["cap"]
		else:
			var primary_t := float(i - cap_len) / float(maxi(1, length - cap_len))
			ore_tile = spec["ore_deep"] if primary_t > 0.5 else spec["ore"]

		if _rng.randf() < VEIN_MEANDER_CHANCE:
			center_col += _rng.randi_range(-1, 1)
			center_col = clampi(center_col, 2, _cols - 3)

		for w in range(width):
			var place_col := center_col - width / 2 + w
			if place_col < 1 or place_col >= _cols - 1:
				continue
			var current: int = _grid[place_col][row]
			if current in [T_DIRT, T_DIRT_DARK, T_STONE, T_STONE_DARK]:
				_grid[place_col][row] = ore_tile

# ---------------------------------------------------------------------------
# Decoration placement — call after generate() to get decoration positions.
# Returns a Dictionary with keys:
#   "plants"         : Array[Vector2i]  — surface grass tiles to decorate
#   "coral_floor"    : Array[Vector2i]  — cave floor tiles for coral
#   "coral_ceiling"  : Array[Vector2i]  — cave ceiling tiles for coral (flipped)
#   "webs"           : Array[Vector2i]  — cave positions for spider webs
# ---------------------------------------------------------------------------

const CORAL_FLOOR_CHANCE:        float = 0.12
const CORAL_CEILING_CHANCE:      float = 0.12
const WEB_CHANCE:                float = 0.015
const FOLIAGE_ABOVE_GRASS_CHANCE: float = 0.22

func generate_decorations() -> Dictionary:
	var foliage_above_grass: Array[Vector2i] = []
	var coral_floor:         Array[Vector2i] = []
	var coral_ceiling:       Array[Vector2i] = []
	var webs:                Array[Vector2i] = []

	# Foliage above grass — placed in the sky row immediately above the grass layer.
	# Only spawns where the column above is open sky (T_SURFACE) to avoid overlap with
	# station tiles whose footprint extends into the surface rows.
	var above_row: int = _surface_rows - 1
	if above_row >= 0:
		for col in range(_cols):
			if _grid[col][_surface_rows] == T_SURFACE_GRASS and _grid[col][above_row] == T_SURFACE:
				if _rng.randf() < FOLIAGE_ABOVE_GRASS_CHANCE:
					foliage_above_grass.append(Vector2i(col, above_row))

	# Underground decorations — scan all empty cells below the surface
	for col in range(1, _cols - 1):
		for row in range(_surface_rows + 4, _rows - 1):
			if _grid[col][row] != T_EMPTY:
				continue
			var has_solid_below:  bool = _is_decoration_solid(_grid[col][row + 1])
			var has_solid_above:  bool = _is_decoration_solid(_grid[col][row - 1])

			if has_solid_below and _rng.randf() < CORAL_FLOOR_CHANCE:
				coral_floor.append(Vector2i(col, row))
			elif has_solid_above and _rng.randf() < CORAL_CEILING_CHANCE:
				coral_ceiling.append(Vector2i(col, row))
			elif _rng.randf() < WEB_CHANCE:
				webs.append(Vector2i(col, row))

	return {
		"foliage_above_grass": foliage_above_grass,
		"coral_floor":         coral_floor,
		"coral_ceiling":       coral_ceiling,
		"webs":                webs,
	}

func _is_decoration_solid(tile: int) -> bool:
	return tile not in [T_EMPTY, T_LAVA, T_LAVA_FLOW, T_ENERGY_NODE, T_ENERGY_NODE_FULL]

# ---------------------------------------------------------------------------
# Depth-scaled ore helper (used by cave room edge seeding)
# ---------------------------------------------------------------------------

func _depth_scaled_ore(depth: float) -> int:
	var tiers: Array = []
	if depth > 0.65:
		if _allowed_ore.is_empty() or _allowed_ore.has("Gem"):    tiers.append(T_ORE_GEM_DEEP)
		if _allowed_ore.is_empty() or _allowed_ore.has("Gold"):   tiers.append(T_ORE_GOLD_DEEP)
		if _allowed_ore.is_empty() or _allowed_ore.has("Iron"):   tiers.append(T_ORE_IRON_DEEP)
	elif depth > 0.35:
		if _allowed_ore.is_empty() or _allowed_ore.has("Gold"):   tiers.append(T_ORE_GOLD)
		if _allowed_ore.is_empty() or _allowed_ore.has("Iron"):   tiers.append(T_ORE_IRON_DEEP)
		if _allowed_ore.is_empty() or _allowed_ore.has("Copper"): tiers.append(T_ORE_COPPER_DEEP)
	else:
		if _allowed_ore.is_empty() or _allowed_ore.has("Iron"):   tiers.append(T_ORE_IRON)
		if _allowed_ore.is_empty() or _allowed_ore.has("Copper"): tiers.append(T_ORE_COPPER_DEEP)
		if _allowed_ore.is_empty() or _allowed_ore.has("Copper"): tiers.append(T_ORE_COPPER)
	if tiers.is_empty():
		return T_EMPTY
	return tiers[_rng.randi() % tiers.size()]
