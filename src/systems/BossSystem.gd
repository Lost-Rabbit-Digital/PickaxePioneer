class_name BossSystem
extends RefCounted

## Boss encounter system (§4)
## Spawns space bosses at milestone sector rows.  Each boss is a cluster of
## BOSS_SEGMENT / BOSS_CORE tiles placed into MiningLevel's grid.
## MiningLevel passes Callables for grid/collision/UI operations so this
## class has no direct Node dependency.  State needed for draw (boss_active,
## boss_type, boss_tile_positions, etc.) is exposed as public vars and read by
## MiningLevel._draw().

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const BOSS_MILESTONES: Array[int] = [32, 64, 96, 112, 128]
const BOSS_DRAIN_MULT: float      = 1.5   # energy drain multiplier while boss alive
const BOSS_SEGMENT_COUNT: int     = 12    # body segments for Giant Space Rat
const BOSS_REWARD_BONUS: int      = 100   # flat mineral bonus on defeat

const BOSS_TYPE_NONE: int      = 0
const BOSS_TYPE_GIANT_RAT: int = 1
const BOSS_TYPE_SPIDER: int    = 2
const BOSS_TYPE_MOLE: int      = 3
const BOSS_TYPE_GOLEM: int     = 4
const BOSS_TYPE_ANCIENT: int   = 5

# The Ancient Star Beast — three-phase final boss at row 128
const ANCIENT_VOID_PULSE_INTERVAL: float  = 6.0   # seconds between void pulses (phase 2)
const ANCIENT_VOID_PULSE_WARNING: float   = 1.5   # warning window before pulse fires
const ANCIENT_VOID_PULSE_RADIUS: int      = 7     # radius of void pulse collapse
const ANCIENT_VOID_FILL_CHANCE: float     = 0.40  # probability each empty tile collapses
const ANCIENT_CORE_RECHARGE_INTERVAL: float = 8.0 # core resets accumulated damage every 8s (phase 3)
const ANCIENT_DRAIN_MULT: float           = 2.0   # The Ancient Hound drains energy at 2× rate

# Blind Mole tremor timings
const MOLE_TREMOR_INTERVAL: float   = 7.0
const MOLE_TREMOR_WARNING: float    = 1.8
const MOLE_TREMOR_RADIUS: int       = 10
const MOLE_TREMOR_FILL_CHANCE: float = 0.55

# Stone Golem ore phases
const GOLEM_PHASE_ORES: Array[String] = ["copper", "iron", "gold"]
const GOLEM_SEGMENTS_PER_PHASE: int   = 5

# Giant Rat King — directional charge attack toward the player
const RAT_CHARGE_INTERVAL: float    = 5.0
const RAT_CHARGE_WARNING: float     = 1.5
const RAT_CHARGE_LENGTH: int        = 5
const RAT_CHARGE_FILL_CHANCE: float = 0.70

# Void Spider Matriarch — web trap around the player's position
const SPIDER_WEB_INTERVAL: float    = 7.0
const SPIDER_WEB_WARNING: float     = 1.5
const SPIDER_WEB_RADIUS: int        = 3
const SPIDER_WEB_FILL_CHANCE: float = 0.50

# Boss spawn chance per milestone (0.0–1.0); each depth milestone has this
# probability of actually spawning a boss, making encounters feel random.
const BOSS_SPAWN_CHANCE: float = 0.5

# TileType values needed internally (mirrors MiningLevel.TileType)
const _TILE_BOSS_SEGMENT: int = 23
const _TILE_BOSS_CORE: int    = 24
const _TILE_DIRT: int         = 1
const _TILE_DIRT_DARK: int    = 2
const _TILE_STONE: int        = 11
const _TILE_STONE_DARK: int   = 12
const _TILE_SURFACE: int      = 20
const _TILE_EXIT_STATION: int = 22

# Ore tile types for seeding around the Stone Golem
const _TILE_ORE_COPPER: int   = 3
const _TILE_ORE_IRON: int     = 5
const _TILE_ORE_GOLD: int     = 7

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

## Giant Rat charge draw state
var rat_charge_warning_active: bool = false
var rat_charge_warning_timer: float = 0.0
var rat_charge_target_pos: Vector2i = Vector2i(-1, -1)

## Void Spider web draw state
var spider_web_warning_active: bool = false
var spider_web_warning_timer: float = 0.0
var spider_web_target_pos: Vector2i = Vector2i(-1, -1)

## The Ancient Hound draw state
var ancient_phase: int = 0               # 0=outer shell, 1=inner ring, 2=core only
var ancient_void_warning_active: bool = false
var ancient_void_warning_timer: float = 0.0
var ancient_core_recharge_warning: bool = false

# ---------------------------------------------------------------------------
# Private state
# ---------------------------------------------------------------------------

var _boss_milestones_seen: Array[bool] = [false, false, false, false, false]
var _boss_spawn_row: int = -1
var _pending_hints: Array[String] = []
var _mole_tremor_timer: float = 0.0
var _mole_center: Vector2i = Vector2i(-1, -1)
var _golem_segments_this_phase: int = 0
var _ancient_center: Vector2i = Vector2i(-1, -1)
var _ancient_outer_positions: Array[Vector2i] = []
var _ancient_outer_count: int = 0
var _ancient_inner_count: int = 0
var _ancient_void_timer: float = 0.0
var _ancient_core_recharge_timer: float = 0.0
var _rat_center: Vector2i = Vector2i(-1, -1)
var _rat_charge_timer: float = 0.0
var _spider_center: Vector2i = Vector2i(-1, -1)
var _spider_web_timer: float = 0.0
var _player_col: int = -1
var _player_row: int = -1

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
## player_col / player_row are the player's current grid coordinates.
func update(delta: float, player_col: int = -1, player_row: int = -1) -> void:
	_player_col = player_col
	_player_row = player_row
	if not boss_active:
		return
	boss_pulse_time += delta
	_update_giant_rat(delta)
	_update_spider(delta)
	_update_blind_mole(delta)
	_update_ancient_one(delta)


## Returns the energy drain multiplier for the current boss (1.0 if no boss active).
func get_energy_drain_mult() -> float:
	if not boss_active:
		return 1.0
	if boss_type == BOSS_TYPE_ANCIENT:
		return ANCIENT_DRAIN_MULT
	return BOSS_DRAIN_MULT


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
			if randf() > BOSS_SPAWN_CHANCE:
				continue  # boss doesn't appear this run — random event feel
			match i:
				0: _spawn_giant_rat_king(player_col)
				1: _spawn_cave_spider_matriarch(player_col)
				2: _spawn_blind_mole(player_col)
				3: _spawn_stone_golem(player_col)
				4: _spawn_ancient_one(player_col)


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
## Handles phase advancement (Golem, Ancient One) and defeat detection.
func on_tile_mined(col: int, row: int, tile_type: int) -> void:
	var mined_pos := Vector2i(col, row)
	boss_tile_positions.erase(mined_pos)

	# Stone Golem: count segments to advance armor phases
	if boss_active and boss_type == BOSS_TYPE_GOLEM and tile_type == _TILE_BOSS_SEGMENT:
		_golem_segments_this_phase += 1
		if _golem_segments_this_phase >= GOLEM_SEGMENTS_PER_PHASE:
			_golem_segments_this_phase = 0
			golem_phase += 1
			if golem_phase < GOLEM_PHASE_ORES.size():
				var next_ore := GOLEM_PHASE_ORES[golem_phase].capitalize()
				_show_banner.call("ARMOR CRACKED!", Color(0.85, 0.70, 0.20))
				EventBus.boss_hint_popup.emit("Now mine " + next_ore + "!")
				_shake_camera.call(8.0, 0.4)
			else:
				_show_banner.call("CORE EXPOSED!", Color(1.00, 0.40, 0.00))
				EventBus.boss_hint_popup.emit("Strike the core!")
				_shake_camera.call(8.0, 0.4)

	# Ancient One: track shell phase transitions
	if boss_active and boss_type == BOSS_TYPE_ANCIENT and tile_type == _TILE_BOSS_SEGMENT:
		if mined_pos in _ancient_outer_positions:
			_ancient_outer_positions.erase(mined_pos)
			_ancient_outer_count -= 1
			if _ancient_outer_count <= 0 and ancient_phase == 0:
				ancient_phase = 1
				_ancient_void_timer = ANCIENT_VOID_PULSE_INTERVAL
				_show_banner.call("CRYSTALLINE FORM REVEALED!", Color(0.55, 0.10, 0.85))
				EventBus.boss_hint_popup.emit("Phase 2! Watch for void pulses!")
				_shake_camera.call(10.0, 0.6)
		else:
			_ancient_inner_count -= 1
			if _ancient_inner_count <= 0 and ancient_phase == 1:
				ancient_phase = 2
				ancient_void_warning_active = false
				_ancient_core_recharge_timer = ANCIENT_CORE_RECHARGE_INTERVAL
				_show_banner.call("THE STAR BEAST CORE EXPOSED!", Color(0.90, 0.70, 1.00))
				EventBus.boss_hint_popup.emit("Phase 3! Mine fast — it regenerates!")
				_shake_camera.call(12.0, 0.8)

	if boss_tile_positions.is_empty() and boss_active:
		_on_boss_defeated()


# ---------------------------------------------------------------------------
# Spawn helpers
# ---------------------------------------------------------------------------

func _spawn_giant_rat_king(player_col: int) -> void:
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

	_activate(positions, BOSS_TYPE_GIANT_RAT, boss_row)
	_rat_center = Vector2i(player_col, boss_row)
	_rat_charge_timer = RAT_CHARGE_INTERVAL
	_show_banner.call("GIANT SPACE RAT AWAKENS!", Color(0.90, 0.10, 0.05))
	EventBus.boss_hint_popup.emit("Boss! Watch for charge attacks!")
	_shake_camera.call(8.0, 0.4)
	_pending_hints = ["Watch for CHARGE warnings — dodge the debris!", "Click each glowing tile to chip away at it!", "Defeat the boss to restore fuel!"]


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
	_spider_center = Vector2i(player_col, boss_row)
	_spider_web_timer = SPIDER_WEB_INTERVAL
	_show_banner.call("VOID SPIDER MATRIARCH!", Color(0.60, 0.10, 0.80))
	EventBus.boss_hint_popup.emit("Boss! Beware of web traps!")
	_shake_camera.call(8.0, 0.4)
	_pending_hints = ["Watch for WEB warnings — move before you're trapped!", "Click each glowing segment to chip away at it!", "Defeat the boss to restore fuel!"]


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

	_show_banner.call("THE COSMIC MOLE STIRS!", Color(0.55, 0.35, 0.85))
	EventBus.boss_hint_popup.emit("Boss! Mine all segments to defeat it!")
	_shake_camera.call(12.0, 0.6)
	_pending_hints = ["Watch for TREMOR warnings — get clear!", "Tremors seal mined passages around the boss!", "Defeat the boss to restore fuel!"]


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

	# Seed guaranteed ore pockets so the player is never locked out
	_seed_golem_ores(player_col, boss_row, positions)

	var required := GOLEM_PHASE_ORES[0].capitalize()
	_show_banner.call("ASTEROID GOLEM AWAKENS!", Color(0.60, 0.55, 0.85))
	EventBus.boss_hint_popup.emit("Armored boss! Mine nearby ore to unlock damage!")
	_shake_camera.call(14.0, 0.8)
	_pending_hints = ["Step 1: Mine " + required + " ore (not the boss!)", "Step 2: Then click the glowing boss tiles!", "Wrong ore type? It blocks all damage!"]


func _seed_golem_ores(center_col: int, center_row: int, boss_positions: Array[Vector2i]) -> void:
	## Place guaranteed copper, iron, and gold ore near the golem so the player
	## always has access to each phase-required ore type regardless of depth RNG.
	var boss_set: Dictionary = {}
	for bp in boss_positions:
		boss_set[bp] = true

	var replaceable: Array[int] = [_TILE_DIRT, _TILE_DIRT_DARK, _TILE_STONE, _TILE_STONE_DARK]
	var phase_ores: Array[int] = [_TILE_ORE_COPPER, _TILE_ORE_IRON, _TILE_ORE_GOLD]

	# Collect candidate positions in a ring around the boss (distance 3–6 tiles)
	var candidates: Array[Vector2i] = []
	for dc in range(-7, 8):
		for dr in range(-5, 6):
			var dist := Vector2(dc, dr).length()
			if dist < 3.0 or dist > 6.5:
				continue
			var col := center_col + dc
			var row := center_row + dr
			if col < 1 or col >= _grid_cols - 1 or row <= _surface_rows or row >= _grid_rows - 1:
				continue
			var pos := Vector2i(col, row)
			if boss_set.has(pos):
				continue
			if _grid[col][row] in replaceable:
				candidates.append(pos)

	# Shuffle so ore placement feels natural
	candidates.shuffle()

	# Place 4 of each ore type from the candidate pool
	var idx := 0
	for ore_tile in phase_ores:
		var placed := 0
		while placed < 4 and idx < candidates.size():
			var pos: Vector2i = candidates[idx]
			_grid[pos.x][pos.y] = ore_tile
			idx += 1
			placed += 1


func _spawn_ancient_one(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[4]
	var positions: Array[Vector2i] = []
	var outer_pos: Array[Vector2i] = []

	# Outer shell — 12 segments forming a large elliptical ring (phase 1)
	var outer_offsets: Array = [
		Vector2i(-3, -2), Vector2i(-1, -3), Vector2i(1, -3), Vector2i(3, -2),
		Vector2i(4,  0),  Vector2i(3,  2),  Vector2i(1,  3), Vector2i(-1,  3),
		Vector2i(-3,  2), Vector2i(-4,  0), Vector2i(-2, -3), Vector2i(2, -3),
	]

	for offset in outer_offsets:
		var col: int = clampi(player_col + offset.x, 2, _grid_cols - 3)
		var row: int = clampi(boss_row + offset.y, _surface_rows + 1, _grid_rows - 2)
		_grid[col][row] = _TILE_BOSS_SEGMENT
		_set_collision.call(col, row, true)
		positions.append(Vector2i(col, row))
		outer_pos.append(Vector2i(col, row))

	# Inner ring — 8 segments forming a tighter ellipse (phase 2)
	var inner_offsets: Array = [
		Vector2i(-2, -1), Vector2i(-1, -2), Vector2i(1, -2), Vector2i(2, -1),
		Vector2i(2,  1),  Vector2i(1,  2),  Vector2i(-1,  2), Vector2i(-2,  1),
	]

	for offset in inner_offsets:
		var col: int = clampi(player_col + offset.x, 2, _grid_cols - 3)
		var row: int = clampi(boss_row + offset.y, _surface_rows + 1, _grid_rows - 2)
		_grid[col][row] = _TILE_BOSS_SEGMENT
		_set_collision.call(col, row, true)
		positions.append(Vector2i(col, row))

	# Core — centre tile (phase 3)
	var core_col: int = clampi(player_col, 2, _grid_cols - 3)
	var core_row: int = clampi(boss_row, _surface_rows + 1, _grid_rows - 2)
	_grid[core_col][core_row] = _TILE_BOSS_CORE
	_set_collision.call(core_col, core_row, true)
	positions.append(Vector2i(core_col, core_row))

	_activate(positions, BOSS_TYPE_ANCIENT, boss_row)
	_ancient_center = Vector2i(core_col, core_row)
	_ancient_outer_positions = outer_pos
	_ancient_outer_count = outer_offsets.size()
	_ancient_inner_count = inner_offsets.size()
	ancient_phase = 0
	_ancient_void_timer = 0.0
	ancient_void_warning_active = false
	ancient_core_recharge_warning = false

	_show_banner.call("THE ANCIENT STAR BEAST AWAKENS!", Color(0.15, 0.70, 0.90))
	EventBus.boss_hint_popup.emit("Final boss! Break the outer shell first!")
	_shake_camera.call(16.0, 1.0)
	_pending_hints = [
		"Phase 1: Mine the outer ring of segments!",
		"Phase 2: Void pulses will seal mined passages — keep moving!",
		"Phase 3: The core regenerates — strike fast!",
	]


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
	_rat_center = Vector2i(-1, -1)
	_rat_charge_timer = 0.0
	rat_charge_warning_active = false
	rat_charge_warning_timer = 0.0
	rat_charge_target_pos = Vector2i(-1, -1)
	_spider_center = Vector2i(-1, -1)
	_spider_web_timer = 0.0
	spider_web_warning_active = false
	spider_web_warning_timer = 0.0
	spider_web_target_pos = Vector2i(-1, -1)
	_mole_tremor_timer = 0.0
	mole_tremor_warning_active = false
	_mole_center = Vector2i(-1, -1)
	golem_phase = 0
	_golem_segments_this_phase = 0
	ancient_phase = 0
	ancient_void_warning_active = false
	ancient_core_recharge_warning = false
	_ancient_center = Vector2i(-1, -1)
	_ancient_outer_positions.clear()
	_ancient_outer_count = 0
	_ancient_inner_count = 0

	GameManager.bosses_defeated_total += 1
	GameManager.add_currency(BOSS_REWARD_BONUS)
	EventBus.minerals_earned.emit(BOSS_REWARD_BONUS)
	EventBus.ore_mined_popup.emit(BOSS_REWARD_BONUS, "Boss defeated!")
	_show_banner.call("BOSS DEFEATED!", Color(0.30, 1.00, 0.40))
	GameManager.restore_energy(50)
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
		EventBus.boss_hint_popup.emit("TREMOR INCOMING!")
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


# ---------------------------------------------------------------------------
# Giant Rat King charge logic
# ---------------------------------------------------------------------------

func _update_giant_rat(delta: float) -> void:
	if boss_type != BOSS_TYPE_GIANT_RAT:
		return

	if rat_charge_warning_active:
		rat_charge_warning_timer -= delta
		if rat_charge_warning_timer <= 0.0:
			rat_charge_warning_active = false
			_execute_rat_charge()
		return

	_rat_charge_timer -= delta
	if _rat_charge_timer <= 0.0:
		_rat_charge_timer = RAT_CHARGE_INTERVAL
		rat_charge_warning_active = true
		rat_charge_warning_timer = RAT_CHARGE_WARNING
		rat_charge_target_pos = Vector2i(_player_col, _player_row)
		EventBus.boss_hint_popup.emit("RAT KING CHARGES!")
		_shake_camera.call(5.0, 0.3)


func _execute_rat_charge() -> void:
	var cx := _rat_center.x
	var cy := _rat_center.y
	var tx := rat_charge_target_pos.x
	var ty := rat_charge_target_pos.y
	if tx < 0 or ty < 0:
		return

	var dir := Vector2(tx - cx, ty - cy).normalized()
	var filled := 0

	for step in range(1, RAT_CHARGE_LENGTH + 1):
		var col := cx + roundi(dir.x * step)
		var row := cy + roundi(dir.y * step)
		if col < 0 or col >= _grid_cols or row <= _surface_rows or row >= _grid_rows - 1:
			continue
		if _grid[col][row] != 0:   # not EMPTY
			continue
		if randf() < RAT_CHARGE_FILL_CHANCE:
			var new_tile := _TILE_DIRT_DARK if row > _surface_rows + 8 else _TILE_DIRT
			_grid[col][row] = new_tile
			_set_collision.call(col, row, true)
			_erase_tile_state.call(Vector2i(col, row))
			filled += 1

	if filled > 0:
		EventBus.ore_mined_popup.emit(0, "Rat charge! " + str(filled) + " tiles filled!")
	_shake_camera.call(8.0, 0.4)
	rat_charge_target_pos = Vector2i(-1, -1)


# ---------------------------------------------------------------------------
# Void Spider web-trap logic
# ---------------------------------------------------------------------------

func _update_spider(delta: float) -> void:
	if boss_type != BOSS_TYPE_SPIDER:
		return

	if spider_web_warning_active:
		spider_web_warning_timer -= delta
		if spider_web_warning_timer <= 0.0:
			spider_web_warning_active = false
			_execute_spider_web()
		return

	_spider_web_timer -= delta
	if _spider_web_timer <= 0.0:
		_spider_web_timer = SPIDER_WEB_INTERVAL
		spider_web_warning_active = true
		spider_web_warning_timer = SPIDER_WEB_WARNING
		spider_web_target_pos = Vector2i(_player_col, _player_row)
		EventBus.boss_hint_popup.emit("WEB INCOMING!")
		_shake_camera.call(4.0, 0.3)


func _execute_spider_web() -> void:
	var tx := spider_web_target_pos.x
	var ty := spider_web_target_pos.y
	if tx < 0 or ty < 0:
		return

	var r := SPIDER_WEB_RADIUS
	var webbed := 0

	for tc in range(maxi(0, tx - r), mini(_grid_cols, tx + r + 1)):
		for tr in range(maxi(_surface_rows + 1, ty - r), mini(_grid_rows - 1, ty + r + 1)):
			if _grid[tc][tr] != 0:   # not EMPTY
				continue
			var dist := Vector2(tc - tx, tr - ty).length()
			if dist > float(r):
				continue
			if randf() < SPIDER_WEB_FILL_CHANCE:
				var new_tile := _TILE_DIRT_DARK if tr > _surface_rows + 8 else _TILE_DIRT
				_grid[tc][tr] = new_tile
				_set_collision.call(tc, tr, true)
				_erase_tile_state.call(Vector2i(tc, tr))
				webbed += 1

	if webbed > 0:
		EventBus.ore_mined_popup.emit(0, "Webbed! " + str(webbed) + " tiles trapped!")
	_shake_camera.call(6.0, 0.4)
	spider_web_target_pos = Vector2i(-1, -1)


# ---------------------------------------------------------------------------
# The Ancient Hound phase logic
# ---------------------------------------------------------------------------

func _update_ancient_one(delta: float) -> void:
	if boss_type != BOSS_TYPE_ANCIENT:
		return

	# Phase 2: periodic void pulses that reseal mined tunnels near the boss
	if ancient_phase == 1:
		if ancient_void_warning_active:
			ancient_void_warning_timer -= delta
			if ancient_void_warning_timer <= 0.0:
				ancient_void_warning_active = false
				_execute_ancient_void_pulse()
		else:
			_ancient_void_timer -= delta
			if _ancient_void_timer <= 0.0:
				_ancient_void_timer = ANCIENT_VOID_PULSE_INTERVAL
				ancient_void_warning_active = true
				ancient_void_warning_timer = ANCIENT_VOID_PULSE_WARNING
				EventBus.boss_hint_popup.emit("VOID PULSE INCOMING!")
				_shake_camera.call(4.0, 0.3)

	# Phase 3: core periodically recharges (resets accumulated hit damage)
	elif ancient_phase == 2:
		_ancient_core_recharge_timer -= delta
		ancient_core_recharge_warning = _ancient_core_recharge_timer <= 2.0
		if _ancient_core_recharge_timer <= 0.0:
			_ancient_core_recharge_timer = ANCIENT_CORE_RECHARGE_INTERVAL
			ancient_core_recharge_warning = false
			_erase_tile_state.call(_ancient_center)
			EventBus.boss_hint_popup.emit("Star Beast regenerates!")
			_shake_camera.call(6.0, 0.4)


func _execute_ancient_void_pulse() -> void:
	var cx := _ancient_center.x
	var cy := _ancient_center.y
	var r := ANCIENT_VOID_PULSE_RADIUS
	var sealed := 0

	for tc in range(maxi(0, cx - r), mini(_grid_cols, cx + r + 1)):
		for tr in range(maxi(_surface_rows + 1, cy - r), mini(_grid_rows - 1, cy + r + 1)):
			if _grid[tc][tr] != 0:   # not EMPTY
				continue
			var dist := Vector2(tc - cx, tr - cy).length()
			if dist > float(r):
				continue
			if randf() < ANCIENT_VOID_FILL_CHANCE:
				_grid[tc][tr] = _TILE_DIRT_DARK
				_set_collision.call(tc, tr, true)
				_erase_tile_state.call(Vector2i(tc, tr))
				sealed += 1

	if sealed > 0:
		EventBus.ore_mined_popup.emit(0, "Void Pulse! " + str(sealed) + " tiles sealed!")
	_shake_camera.call(8.0, 0.5)


## Reset all state at the start of a new run.
func reset() -> void:
	boss_active = false
	boss_type = BOSS_TYPE_NONE
	boss_tile_positions.clear()
	boss_pulse_time = 0.0
	_boss_milestones_seen = [false, false, false, false, false]
	_boss_spawn_row = -1
	_rat_center = Vector2i(-1, -1)
	_rat_charge_timer = 0.0
	rat_charge_warning_active = false
	rat_charge_warning_timer = 0.0
	rat_charge_target_pos = Vector2i(-1, -1)
	_spider_center = Vector2i(-1, -1)
	_spider_web_timer = 0.0
	spider_web_warning_active = false
	spider_web_warning_timer = 0.0
	spider_web_target_pos = Vector2i(-1, -1)
	_mole_tremor_timer = 0.0
	mole_tremor_warning_active = false
	mole_tremor_warning_timer = 0.0
	_mole_center = Vector2i(-1, -1)
	golem_phase = 0
	_golem_segments_this_phase = 0
	ancient_phase = 0
	ancient_void_warning_active = false
	ancient_void_warning_timer = 0.0
	ancient_core_recharge_warning = false
	_ancient_center = Vector2i(-1, -1)
	_ancient_outer_positions.clear()
	_ancient_outer_count = 0
	_ancient_inner_count = 0
	_ancient_void_timer = 0.0
	_ancient_core_recharge_timer = 0.0
