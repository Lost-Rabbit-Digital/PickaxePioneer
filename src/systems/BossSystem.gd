class_name BossSystem
extends RefCounted

## Boss encounter system (§4)
## Spawns bosses at milestone depth rows.  Each boss is a cluster of
## BOSS_SEGMENT / BOSS_CORE tiles placed into MiningLevel's grid.
## MiningLevel passes Callables for grid/collision/UI operations so this
## class has no direct Node dependency.  State needed for draw (boss_active,
## boss_type, boss_tile_positions, etc.) is exposed as public vars and read by
## MiningLevel._draw().

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const BOSS_MILESTONES: Array[int] = [32, 64, 96, 112]
const BOSS_DRAIN_MULT: float      = 1.5   # fuel drain multiplier while boss alive
const BOSS_SEGMENT_COUNT: int     = 12    # body segments for Centipede King
const BOSS_REWARD_BONUS: int      = 100   # flat mineral bonus on defeat

const BOSS_TYPE_NONE: int      = 0
const BOSS_TYPE_CENTIPEDE: int = 1
const BOSS_TYPE_SPIDER: int    = 2
const BOSS_TYPE_MOLE: int      = 3
const BOSS_TYPE_GOLEM: int     = 4

# Blind Mole tremor timings
const MOLE_TREMOR_INTERVAL: float   = 7.0
const MOLE_TREMOR_WARNING: float    = 1.8
const MOLE_TREMOR_RADIUS: int       = 10
const MOLE_TREMOR_FILL_CHANCE: float = 0.55

# Stone Golem ore phases
const GOLEM_PHASE_ORES: Array[String] = ["copper", "iron", "gold"]
const GOLEM_SEGMENTS_PER_PHASE: int   = 5

# TileType values needed internally (mirrors MiningLevel.TileType)
const _TILE_BOSS_SEGMENT: int = 23
const _TILE_BOSS_CORE: int    = 24
const _TILE_DIRT: int         = 1
const _TILE_DIRT_DARK: int    = 2
const _TILE_SURFACE: int      = 20
const _TILE_EXIT_STATION: int = 22

# ---------------------------------------------------------------------------
# Public state (read by MiningLevel for draw and game logic)
# ---------------------------------------------------------------------------

var boss_active: bool = false
var boss_type: int = BOSS_TYPE_NONE
var boss_tile_positions: Array[Vector2i] = []
var boss_pulse_time: float = 0.0

## Blind Mole draw state
var mole_tremor_warning_active: bool = false
var mole_tremor_warning_timer: float = 0.0

## Stone Golem draw state
var golem_phase: int = 0

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _boss_milestones_seen: Array[bool] = [false, false, false, false]
var _boss_spawn_row: int = -1
var _pending_hints: Array[String] = []
var _mole_tremor_timer: float = 0.0
var _mole_center: Vector2i = Vector2i(-1, -1)
var _golem_segments_this_phase: int = 0

# Grid layout constants injected at setup
var _grid_cols: int = 96
var _grid_rows: int = 128
var _surface_rows: int = 3

# Callables injected by MiningLevel at setup
var _grid: Array = []
var _set_collision: Callable   # func(col: int, row: int, solid: bool)
var _show_banner: Callable     # func(text: String, color: Color)
var _shake_camera: Callable    # func(intensity: float, duration: float)
var _erase_tile_state: Callable # func(pos: Vector2i)  — erases _tile_damage + _tile_hits


## Inject dependencies.  Call once in MiningLevel._ready() before any other use.
func setup(
		grid: Array,
		grid_cols: int,
		grid_rows: int,
		surface_rows: int,
		set_collision_fn: Callable,
		show_banner_fn: Callable,
		shake_camera_fn: Callable,
		erase_tile_state_fn: Callable) -> void:
	_grid = grid
	_grid_cols = grid_cols
	_grid_rows = grid_rows
	_surface_rows = surface_rows
	_set_collision = set_collision_fn
	_show_banner = show_banner_fn
	_shake_camera = shake_camera_fn
	_erase_tile_state = erase_tile_state_fn


# ---------------------------------------------------------------------------
# Per-frame update
# ---------------------------------------------------------------------------

## Call every frame while the game is running (even when menus are open).
func update(delta: float) -> void:
	if not boss_active:
		return
	boss_pulse_time += delta
	_update_blind_mole(delta)


# ---------------------------------------------------------------------------
# Milestone check (called by MiningLevel._update_depth)
# ---------------------------------------------------------------------------

## Check whether the player has reached a boss milestone depth.
## player_col: the player's current grid column (for spawn positioning).
func check_milestone(depth_row: int, player_col: int) -> void:
	if boss_active:
		return
	for i in range(BOSS_MILESTONES.size()):
		if not _boss_milestones_seen[i] and depth_row >= BOSS_MILESTONES[i]:
			_boss_milestones_seen[i] = true
			match i:
				0: _spawn_centipede_king(player_col)
				1: _spawn_cave_spider_matriarch(player_col)
				2: _spawn_blind_mole(player_col)
				3: _spawn_stone_golem(player_col)


# ---------------------------------------------------------------------------
# Mining interaction
# ---------------------------------------------------------------------------

## Returns false if the Golem is currently resisting the attack (requires
## the player to have last-mined the correct ore type for the current phase).
## tile_type: the tile being struck.  last_ore_group: smelt_system.last_ore_group.
func can_mine_boss_tile(tile_type: int, last_ore_group: String) -> bool:
	if not boss_active or boss_type != BOSS_TYPE_GOLEM:
		return true
	if tile_type != _TILE_BOSS_SEGMENT and tile_type != _TILE_BOSS_CORE:
		return true
	if golem_phase >= GOLEM_PHASE_ORES.size():
		return true   # all armor phases broken — core is fully exposed
	var required := GOLEM_PHASE_ORES[golem_phase]
	return last_ore_group == required


## Returns any hint strings queued by the most recent boss spawn and clears the queue.
## MiningLevel calls _queue_boss_hints() with the result (needs await, so stays there).
func get_pending_hints() -> Array[String]:
	var h: Array[String] = _pending_hints.duplicate()
	_pending_hints.clear()
	return h


## Called by MiningLevel after a BOSS_SEGMENT or BOSS_CORE tile is fully mined.
## Handles phase advancement (Golem) and defeat detection.
func on_tile_mined(col: int, row: int, tile_type: int) -> void:
	boss_tile_positions.erase(Vector2i(col, row))

	# Stone Golem: count segments to advance armor phases
	if boss_active and boss_type == BOSS_TYPE_GOLEM and tile_type == _TILE_BOSS_SEGMENT:
		_golem_segments_this_phase += 1
		if _golem_segments_this_phase >= GOLEM_SEGMENTS_PER_PHASE:
			_golem_segments_this_phase = 0
			golem_phase += 1
			if golem_phase < GOLEM_PHASE_ORES.size():
				var next_ore := GOLEM_PHASE_ORES[golem_phase].capitalize()
				_show_banner.call("ARMOR CRACKED!", Color(0.85, 0.70, 0.20))
				EventBus.ore_mined_popup.emit(0, "Now mine " + next_ore + "!")
				_shake_camera.call(8.0, 0.4)
			else:
				_show_banner.call("CORE EXPOSED!", Color(1.00, 0.40, 0.00))
				EventBus.ore_mined_popup.emit(0, "Strike the core!")
				_shake_camera.call(8.0, 0.4)

	if boss_tile_positions.is_empty() and boss_active:
		_on_boss_defeated()


# ---------------------------------------------------------------------------
# Spawn helpers
# ---------------------------------------------------------------------------

func _spawn_centipede_king(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[0]
	var positions: Array[Vector2i] = []
	var half := BOSS_SEGMENT_COUNT / 2

	for dc in range(-half, half + 1):
		var col: int = clampi(player_col + dc, 2, _grid_cols - 3)
		var tile_type := _TILE_BOSS_CORE if dc == 0 else _TILE_BOSS_SEGMENT
		_grid[col][boss_row] = tile_type
		_set_collision.call(col, boss_row, true)
		positions.append(Vector2i(col, boss_row))

	for dc in range(-half + 2, half - 1):
		var col: int = clampi(player_col + dc, 2, _grid_cols - 3)
		if _grid[col][boss_row + 1] != _TILE_SURFACE and _grid[col][boss_row + 1] != _TILE_EXIT_STATION:
			_grid[col][boss_row + 1] = _TILE_BOSS_SEGMENT
			_set_collision.call(col, boss_row + 1, true)
			positions.append(Vector2i(col, boss_row + 1))

	_activate(positions, BOSS_TYPE_CENTIPEDE, boss_row)
	_show_banner.call("CENTIPEDE KING AWAKENS!", Color(0.90, 0.10, 0.05))
	EventBus.ore_mined_popup.emit(0, "Boss! Mine all segments to defeat it!")
	_shake_camera.call(8.0, 0.4)
	_pending_hints = ["Click each glowing tile to chip away at it!", "Defeat the boss to restore fuel!"]


func _spawn_cave_spider_matriarch(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[1]
	var positions: Array[Vector2i] = []

	var offsets: Array = [
		Vector2i(0, 0),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-2, 0), Vector2i(2, 0),
		Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1),
	]

	for offset in offsets:
		var col: int = clampi(player_col + offset.x, 2, _grid_cols - 3)
		var row: int = clampi(boss_row + offset.y, _surface_rows + 1, _grid_rows - 2)
		var tile_type := _TILE_BOSS_CORE if offset == Vector2i(0, 0) else _TILE_BOSS_SEGMENT
		_grid[col][row] = tile_type
		_set_collision.call(col, row, true)
		positions.append(Vector2i(col, row))

	_activate(positions, BOSS_TYPE_SPIDER, boss_row)
	_show_banner.call("CAVE SPIDER MATRIARCH!", Color(0.60, 0.10, 0.80))
	EventBus.ore_mined_popup.emit(0, "Boss! Mine all body parts to defeat it!")
	_shake_camera.call(8.0, 0.4)
	_pending_hints = ["Click each glowing segment to chip away at it!", "Defeat the boss to restore fuel!"]


func _spawn_blind_mole(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[2]
	var positions: Array[Vector2i] = []

	var offsets: Array = [
		Vector2i(0, 0),
		Vector2i(-1, 0), Vector2i(1, 0),
		Vector2i(-2, 0), Vector2i(2, 0),
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, -1), Vector2i(1, -1),
		Vector2i(-1,  1), Vector2i(1,  1),
		Vector2i(-2, -1), Vector2i(2, -1),
		Vector2i(-2,  1), Vector2i(2,  1),
		Vector2i(0, -2), Vector2i(0,  2),
	]

	for offset in offsets:
		var col: int = clampi(player_col + offset.x, 2, _grid_cols - 3)
		var row: int = clampi(boss_row + offset.y, _surface_rows + 1, _grid_rows - 2)
		var tile_type := _TILE_BOSS_CORE if offset == Vector2i(0, 0) else _TILE_BOSS_SEGMENT
		_grid[col][row] = tile_type
		_set_collision.call(col, row, true)
		positions.append(Vector2i(col, row))

	_activate(positions, BOSS_TYPE_MOLE, boss_row)
	_mole_center = Vector2i(player_col, boss_row)
	_mole_tremor_timer = MOLE_TREMOR_INTERVAL

	_show_banner.call("THE BLIND MOLE STIRS!", Color(0.55, 0.35, 0.10))
	EventBus.ore_mined_popup.emit(0, "Boss! Mine all segments to defeat it!")
	_shake_camera.call(12.0, 0.6)
	_pending_hints = ["Watch for TREMOR warnings — get clear!", "Tremors refill mined tunnels around the boss!", "Defeat the boss to restore fuel!"]


func _spawn_stone_golem(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[3]
	var positions: Array[Vector2i] = []

	var offsets: Array = [
		Vector2i(0, 0),
		Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-2, 0), Vector2i(2, 0),
		Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
		Vector2i(-2, 1), Vector2i(2, 1),
		Vector2i(-1, 2), Vector2i(0, 2), Vector2i(1, 2),
		Vector2i(-1,-1), Vector2i(0,-1), Vector2i(1,-1),
	]

	for offset in offsets:
		var col: int = clampi(player_col + offset.x, 2, _grid_cols - 3)
		var row: int = clampi(boss_row + offset.y, _surface_rows + 1, _grid_rows - 2)
		var tile_type := _TILE_BOSS_CORE if offset == Vector2i(0, 0) else _TILE_BOSS_SEGMENT
		_grid[col][row] = tile_type
		_set_collision.call(col, row, true)
		positions.append(Vector2i(col, row))

	_activate(positions, BOSS_TYPE_GOLEM, boss_row)
	golem_phase = 0
	_golem_segments_this_phase = 0

	var required := GOLEM_PHASE_ORES[0].capitalize()
	_show_banner.call("STONE GOLEM AWAKENS!", Color(0.60, 0.55, 0.45))
	EventBus.ore_mined_popup.emit(0, "Armor boss! Mine nearby ore to unlock damage!")
	_shake_camera.call(14.0, 0.8)
	_pending_hints = ["Step 1: Mine " + required + " ore (not the boss!)", "Step 2: Then click the glowing boss tiles!", "Wrong ore type? It blocks all damage!"]


func _activate(positions: Array[Vector2i], type: int, spawn_row: int) -> void:
	boss_tile_positions = positions
	boss_active = true
	boss_type = type
	boss_pulse_time = 0.0
	_boss_spawn_row = spawn_row


# ---------------------------------------------------------------------------
# Defeat
# ---------------------------------------------------------------------------

func _on_boss_defeated() -> void:
	boss_active = false
	boss_tile_positions.clear()
	boss_type = BOSS_TYPE_NONE
	_mole_tremor_timer = 0.0
	mole_tremor_warning_active = false
	_mole_center = Vector2i(-1, -1)
	golem_phase = 0
	_golem_segments_this_phase = 0

	GameManager.add_currency(BOSS_REWARD_BONUS)
	EventBus.minerals_earned.emit(BOSS_REWARD_BONUS)
	EventBus.ore_mined_popup.emit(BOSS_REWARD_BONUS, "Boss defeated!")
	_show_banner.call("BOSS DEFEATED!", Color(0.30, 1.00, 0.40))
	GameManager.restore_fuel(50)
	EventBus.ore_mined_popup.emit(50, "Fuel restored!")
	_shake_camera.call(14.0, 0.6)


# ---------------------------------------------------------------------------
# Blind Mole tremor logic
# ---------------------------------------------------------------------------

func _update_blind_mole(delta: float) -> void:
	if boss_type != BOSS_TYPE_MOLE:
		return

	if mole_tremor_warning_active:
		mole_tremor_warning_timer -= delta
		if mole_tremor_warning_timer <= 0.0:
			mole_tremor_warning_active = false
			_execute_mole_tremor()
		return

	_mole_tremor_timer -= delta
	if _mole_tremor_timer <= 0.0:
		_mole_tremor_timer = MOLE_TREMOR_INTERVAL
		mole_tremor_warning_active = true
		mole_tremor_warning_timer = MOLE_TREMOR_WARNING
		EventBus.ore_mined_popup.emit(0, "TREMOR INCOMING!")
		_shake_camera.call(5.0, 0.3)


func _execute_mole_tremor() -> void:
	var cx := _mole_center.x
	var cy := _mole_center.y
	var r := MOLE_TREMOR_RADIUS
	var collapsed := 0

	for tc in range(maxi(0, cx - r), mini(_grid_cols, cx + r + 1)):
		for tr in range(maxi(_surface_rows + 1, cy - r), mini(_grid_rows - 1, cy + r + 1)):
			if _grid[tc][tr] != 0:   # not EMPTY
				continue
			var dist := Vector2(tc - cx, tr - cy).length()
			if dist > float(r):
				continue
			if randf() < MOLE_TREMOR_FILL_CHANCE:
				var new_tile := _TILE_DIRT_DARK if tr > _surface_rows + 8 else _TILE_DIRT
				_grid[tc][tr] = new_tile
				_set_collision.call(tc, tr, true)
				_erase_tile_state.call(Vector2i(tc, tr))
				collapsed += 1

	EventBus.ore_mined_popup.emit(0, "Tremor! " + str(collapsed) + " tiles collapsed!")
	_shake_camera.call(10.0, 0.5)


## Reset all state at the start of a new run.
func reset() -> void:
	boss_active = false
	boss_type = BOSS_TYPE_NONE
	boss_tile_positions.clear()
	boss_pulse_time = 0.0
	_boss_milestones_seen = [false, false, false, false]
	_boss_spawn_row = -1
	_mole_tremor_timer = 0.0
	mole_tremor_warning_active = false
	mole_tremor_warning_timer = 0.0
	_mole_center = Vector2i(-1, -1)
	golem_phase = 0
	_golem_segments_this_phase = 0
