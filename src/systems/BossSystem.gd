class_name BossSystem
extends RefCounted

## Boss encounter system (§4)
## Spawns space bosses at milestone sector rows.  Each boss is a cluster of
## free-floating segments that orbit around a center point, following the player.
## MiningLevel passes Callables for grid/collision/UI operations so this
## class has no direct Node dependency.  State needed for draw (boss_active,
## boss_type, boss_segments, etc.) is exposed as public vars and read by
## BossRenderer.

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const BOSS_MILESTONES: Array[int] = [32, 64, 96, 112, 128]
const BOSS_DRAIN_MULT: float      = 0.75   # energy drain multiplier while boss alive (halved)
const BOSS_REWARD_BONUS: int      = 100   # flat mineral bonus on defeat

const BOSS_TYPE_NONE: int      = 0
const BOSS_TYPE_GIANT_RAT: int = 1
const BOSS_TYPE_SPIDER: int    = 2
const BOSS_TYPE_MOLE: int      = 3
const BOSS_TYPE_GOLEM: int     = 4
const BOSS_TYPE_ANCIENT: int   = 5

# The Ancient Star Beast — three-phase final boss at row 128
const ANCIENT_VOID_PULSE_INTERVAL: float  = 6.0
const ANCIENT_VOID_PULSE_WARNING: float   = 1.5
const ANCIENT_VOID_PULSE_RADIUS: int      = 7
const ANCIENT_VOID_FILL_CHANCE: float     = 0.40
const ANCIENT_CORE_RECHARGE_INTERVAL: float = 8.0
const ANCIENT_DRAIN_MULT: float           = 2.0

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

# Giant Rat King — free-floating segment constants
const RAT_SEGMENT_HP: int           = 3
const RAT_CORE_HP: int              = 5
const RAT_ORBIT_RADIUS_OUTER: float = 160.0
const RAT_ORBIT_RADIUS_INNER: float = 90.0
const RAT_FOLLOW_SPEED: float       = 35.0
const RAT_ORBIT_SPEED: float        = 0.8
const RAT_HIT_RADIUS: float         = 36.0
const RAT_SEGMENT_COUNT: int        = 12

# Void Spider Matriarch — free-floating segment constants
const SPIDER_SEGMENT_HP: int          = 3
const SPIDER_CORE_HP: int             = 6
const SPIDER_ORBIT_RADIUS: float      = 150.0
const SPIDER_FOLLOW_SPEED: float      = 25.0
const SPIDER_HIT_RADIUS: float        = 36.0

# Blind Mole — free-floating segment constants
const MOLE_SEGMENT_HP: int            = 4
const MOLE_CORE_HP: int               = 7
const MOLE_CLAW_HP: int               = 5
const MOLE_ORBIT_RADIUS_OUTER: float  = 160.0
const MOLE_ORBIT_RADIUS_INNER: float  = 80.0
const MOLE_FOLLOW_SPEED: float        = 30.0
const MOLE_ORBIT_SPEED: float         = 0.5
const MOLE_HIT_RADIUS: float          = 36.0
const MOLE_BURROW_INTERVAL: float     = 10.0
const MOLE_BURROW_DURATION: float     = 2.5

# Stone Golem — free-floating segment constants
const GOLEM_SEGMENT_HP: int           = 3
const GOLEM_CORE_HP: int              = 8
const GOLEM_ORBIT_RADIUS_OUTER: float = 170.0
const GOLEM_ORBIT_RADIUS_MID: float   = 120.0
const GOLEM_ORBIT_RADIUS_INNER: float = 75.0
const GOLEM_FOLLOW_SPEED: float       = 15.0
const GOLEM_ORBIT_SPEED: float        = 0.4
const GOLEM_HIT_RADIUS: float         = 36.0

# Ancient Star Beast — free-floating segment constants
const ANCIENT_SEGMENT_HP: int            = 3
const ANCIENT_CORE_HP: int               = 10
const ANCIENT_ORBIT_RADIUS_OUTER: float  = 210.0
const ANCIENT_ORBIT_RADIUS_INNER: float  = 130.0
const ANCIENT_FOLLOW_SPEED_P1: float     = 20.0
const ANCIENT_FOLLOW_SPEED_P2: float     = 35.0
const ANCIENT_ORBIT_SPEED_OUTER: float   = 0.5
const ANCIENT_ORBIT_SPEED_INNER: float   = 0.8
const ANCIENT_HIT_RADIUS: float          = 36.0
const ANCIENT_JITTER_MIN: float          = 1.5
const ANCIENT_JITTER_MAX: float          = 3.0
const ANCIENT_JITTER_RANGE: float        = 80.0

# Boss despawn — if the player descends this many rows past spawn, boss despawns
const BOSS_DESPAWN_ROWS: int = 20

# Void Spider Matriarch — web trap around the player's position
const SPIDER_WEB_INTERVAL: float    = 7.0
const SPIDER_WEB_WARNING: float     = 1.5
const SPIDER_WEB_RADIUS: int        = 3
const SPIDER_WEB_FILL_CHANCE: float = 0.50

# Boss spawn chance per milestone (0.0–1.0)
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

## Free-floating boss segment state (read by BossRenderer)
## Each entry: {pos: Vector2, hp: int, max_hp: int, is_core: bool, angle: float, orbit_r: float}
## Additional per-boss fields: base_orbit_r/base_angle_offset (spider),
## is_claw (mole), armor_phase (golem), ring (ancient)
var boss_segments: Array = []
var boss_center_pos: Vector2 = Vector2.ZERO

## Blind Mole draw state
var mole_tremor_warning_active: bool = false
var mole_tremor_warning_timer: float = 0.0
var mole_burrowed: bool = false

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

## The Ancient Star Beast draw state
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
var _mole_burrow_timer: float = 0.0
var _mole_burrow_phase_timer: float = 0.0
var _ancient_center: Vector2i = Vector2i(-1, -1)
var _ancient_void_timer: float = 0.0
var _ancient_core_recharge_timer: float = 0.0
var _ancient_jitter_timer: float = 0.0
var _rat_center: Vector2i = Vector2i(-1, -1)
var _rat_charge_timer: float = 0.0
var _spider_center: Vector2i = Vector2i(-1, -1)
var _spider_web_timer: float = 0.0
var _spider_facing_angle: float = 0.0
var _player_col: int = -1
var _player_row: int = -1

# Grid layout constants injected at setup
var _grid_cols: int = 96
var _grid_rows: int = 128
var _surface_rows: int = 3
var _cell_size: int = 64

# Callables injected by MiningLevel at setup
var _grid: Array = []
var _set_collision: Callable   # func(col: int, row: int, solid: bool)
var _show_banner: Callable     # func(text: String, color: Color)
var _shake_camera: Callable    # func(intensity: float, duration: float)
var _erase_tile_state: Callable # func(pos: Vector2i)  — erases _tile_damage + _tile_hits
var _update_visual: Callable   # func(col: int, row: int) — syncs TileMapLayer visual


## Inject dependencies.  Call once in MiningLevel._ready() before any other use.
func setup(
		grid: Array,
		grid_cols: int,
		grid_rows: int,
		surface_rows: int,
		cell_size: int,
		set_collision_fn: Callable,
		show_banner_fn: Callable,
		shake_camera_fn: Callable,
		erase_tile_state_fn: Callable,
		update_visual_fn: Callable = Callable()) -> void:
	_grid = grid
	_grid_cols = grid_cols
	_grid_rows = grid_rows
	_surface_rows = surface_rows
	_cell_size = cell_size
	_set_collision = set_collision_fn
	_show_banner = show_banner_fn
	_shake_camera = shake_camera_fn
	_erase_tile_state = erase_tile_state_fn
	_update_visual = update_visual_fn


## Write a tile value to the grid and notify the visual TileMapLayer.
func _set_grid(col: int, row: int, tile: int) -> void:
	_grid[col][row] = tile
	if _update_visual.is_valid():
		_update_visual.call(col, row)


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

	# Despawn if the player has descended far past the boss spawn depth
	if _boss_spawn_row > 0 and _player_row > _boss_spawn_row + BOSS_DESPAWN_ROWS:
		_on_boss_despawned()
		return

	_update_giant_rat(delta)
	_update_spider(delta)
	_update_blind_mole(delta)
	_update_golem(delta)
	_update_ancient_one(delta)


## Returns the energy drain multiplier for the current boss (1.0 if no boss active).
func get_energy_drain_mult() -> float:
	if not boss_active:
		return 1.0
	var reduction: float = GameManager.get_boss_drain_reduction()
	if boss_type == BOSS_TYPE_ANCIENT:
		return maxf(0.5, ANCIENT_DRAIN_MULT - reduction)
	return maxf(0.25, BOSS_DRAIN_MULT - reduction)


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
## With free-floating bosses this is rarely called; kept for safety.
func on_tile_mined(col: int, row: int, _tile_type: int) -> void:
	var mined_pos := Vector2i(col, row)
	boss_tile_positions.erase(mined_pos)
	if boss_tile_positions.is_empty() and boss_segments.is_empty() and boss_active:
		_on_boss_defeated()


## Attempt to hit a free-floating boss segment at the given world position.
## Returns a Dictionary with hit info ({pos, destroyed, is_core, minerals})
## or {"blocked": true, "message": ...} if the hit was phase-gated,
## or an empty Dictionary if no segment was hit.
func try_hit_boss_segment(click_world: Vector2, last_ore_group: String = "") -> Dictionary:
	if not boss_active or boss_segments.is_empty():
		return {}

	# Mole is underground — unhittable
	if boss_type == BOSS_TYPE_MOLE and mole_burrowed:
		return {}

	# Per-boss hit radius
	var hit_radius: float
	match boss_type:
		BOSS_TYPE_GIANT_RAT: hit_radius = RAT_HIT_RADIUS
		BOSS_TYPE_SPIDER: hit_radius = SPIDER_HIT_RADIUS
		BOSS_TYPE_MOLE: hit_radius = MOLE_HIT_RADIUS
		BOSS_TYPE_GOLEM: hit_radius = GOLEM_HIT_RADIUS
		BOSS_TYPE_ANCIENT: hit_radius = ANCIENT_HIT_RADIUS
		_: return {}

	# Find the closest segment within hit radius
	var best_idx := -1
	var best_dist := hit_radius + 1.0
	for i in boss_segments.size():
		var seg: Dictionary = boss_segments[i]
		var d := click_world.distance_to(seg.pos)
		if d < hit_radius and d < best_dist:
			best_dist = d
			best_idx = i

	if best_idx < 0:
		return {}

	var seg: Dictionary = boss_segments[best_idx]

	# Golem phase gating — armor must be broken in copper → iron → gold order
	if boss_type == BOSS_TYPE_GOLEM:
		if seg.is_core:
			if golem_phase < GOLEM_PHASE_ORES.size():
				return {"blocked": true, "message": "Armor intact! Mine surrounding segments!"}
		else:
			var armor_p: int = seg.get("armor_phase", 0)
			if armor_p != golem_phase:
				return {"blocked": true, "message": "Wrong armor layer!"}
			if golem_phase < GOLEM_PHASE_ORES.size():
				var required := GOLEM_PHASE_ORES[golem_phase]
				if last_ore_group != required:
					return {"blocked": true, "message": "Mine " + required.capitalize() + " ore first!"}

	# Ancient phase gating — outer shell → inner ring → core
	if boss_type == BOSS_TYPE_ANCIENT:
		if seg.is_core:
			if ancient_phase < 2:
				return {"blocked": true, "message": "Break the shell first!"}
		else:
			var ring: int = seg.get("ring", 0)
			if ring != ancient_phase:
				if ancient_phase == 0:
					return {"blocked": true, "message": "Break the outer shell first!"}
				else:
					return {"blocked": true, "message": "Break the crystal ring first!"}

	seg.hp -= 1
	var destroyed: bool = seg.hp <= 0

	# Per-boss mineral reward
	var minerals := 10
	match boss_type:
		BOSS_TYPE_GIANT_RAT: minerals = 75 if seg.is_core else 10
		BOSS_TYPE_SPIDER: minerals = 80 if seg.is_core else 12
		BOSS_TYPE_MOLE: minerals = 90 if seg.is_core else 15
		BOSS_TYPE_GOLEM: minerals = 100 if seg.is_core else 15
		BOSS_TYPE_ANCIENT: minerals = 150 if seg.is_core else 20

	var result := {
		"pos": seg.pos,
		"destroyed": destroyed,
		"is_core": seg.is_core,
		"minerals": minerals,
	}

	if destroyed:
		boss_segments.remove_at(best_idx)
		_shake_camera.call(4.0, 0.2)

		# Golem: check phase advancement
		if boss_type == BOSS_TYPE_GOLEM and not seg.is_core:
			var phase_remaining := 0
			for s in boss_segments:
				if not s.is_core and s.get("armor_phase", -1) == golem_phase:
					phase_remaining += 1
			if phase_remaining <= 0:
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

		# Ancient: check phase transitions
		if boss_type == BOSS_TYPE_ANCIENT and not seg.is_core:
			var ring: int = seg.get("ring", 0)
			var ring_remaining := 0
			for s in boss_segments:
				if not s.is_core and s.get("ring", 0) == ring:
					ring_remaining += 1
			if ring_remaining <= 0:
				if ring == 0 and ancient_phase == 0:
					ancient_phase = 1
					_ancient_void_timer = ANCIENT_VOID_PULSE_INTERVAL
					_show_banner.call("CRYSTALLINE FORM REVEALED!", Color(0.55, 0.10, 0.85))
					EventBus.boss_hint_popup.emit("Phase 2! Watch for void pulses!")
					_shake_camera.call(10.0, 0.6)
				elif ring == 1 and ancient_phase == 1:
					ancient_phase = 2
					ancient_void_warning_active = false
					_ancient_core_recharge_timer = ANCIENT_CORE_RECHARGE_INTERVAL
					_ancient_jitter_timer = randf_range(ANCIENT_JITTER_MIN, ANCIENT_JITTER_MAX)
					_show_banner.call("THE STAR BEAST CORE EXPOSED!", Color(0.90, 0.70, 1.00))
					EventBus.boss_hint_popup.emit("Phase 3! Mine fast — it regenerates!")
					_shake_camera.call(12.0, 0.8)

		if boss_segments.is_empty():
			_on_boss_defeated()

	return result


# ---------------------------------------------------------------------------
# Spawn helpers
# ---------------------------------------------------------------------------

func _spawn_giant_rat_king(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[0]
	var cs := _cell_size

	boss_center_pos = Vector2(player_col * cs + cs * 0.5, boss_row * cs + cs * 0.5)
	boss_segments.clear()

	# Core — stays near the center
	boss_segments.append({
		"pos": boss_center_pos,
		"hp": RAT_CORE_HP,
		"max_hp": RAT_CORE_HP,
		"is_core": true,
		"angle": 0.0,
		"orbit_r": 0.0,
	})

	# Outer ring — 6 segments
	for i in 6:
		var a := float(i) / 6.0 * TAU
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * RAT_ORBIT_RADIUS_OUTER,
			"hp": RAT_SEGMENT_HP,
			"max_hp": RAT_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": RAT_ORBIT_RADIUS_OUTER,
		})

	# Inner ring — 6 segments (offset phase)
	for i in 6:
		var a := float(i) / 6.0 * TAU + TAU / 12.0
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * RAT_ORBIT_RADIUS_INNER,
			"hp": RAT_SEGMENT_HP,
			"max_hp": RAT_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": RAT_ORBIT_RADIUS_INNER,
		})

	_activate([], BOSS_TYPE_GIANT_RAT, boss_row)
	_rat_center = Vector2i(player_col, boss_row)
	_rat_charge_timer = RAT_CHARGE_INTERVAL
	_show_banner.call("GIANT SPACE RAT AWAKENS!", Color(0.90, 0.10, 0.05))
	EventBus.boss_hint_popup.emit("Boss! Watch for charge attacks!")
	_shake_camera.call(8.0, 0.4)
	_pending_hints = ["Watch for CHARGE warnings — dodge the debris!", "Click on the floating segments to destroy them!", "Defeat the boss to restore energy!"]


func _spawn_cave_spider_matriarch(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[1]
	var cs := _cell_size

	boss_center_pos = Vector2(player_col * cs + cs * 0.5, boss_row * cs + cs * 0.5)
	boss_segments.clear()

	# Core — spider body
	boss_segments.append({
		"pos": boss_center_pos,
		"hp": SPIDER_CORE_HP,
		"max_hp": SPIDER_CORE_HP,
		"is_core": true,
		"angle": 0.0,
		"orbit_r": 0.0,
	})

	# 8 legs evenly distributed — spider faces the player and turns as a group
	_spider_facing_angle = 0.0
	for i in 8:
		var base_offset := float(i) / 8.0 * TAU
		var a := base_offset
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * SPIDER_ORBIT_RADIUS,
			"hp": SPIDER_SEGMENT_HP,
			"max_hp": SPIDER_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": SPIDER_ORBIT_RADIUS,
			"base_orbit_r": SPIDER_ORBIT_RADIUS,
			"base_angle_offset": base_offset,
		})

	_activate([], BOSS_TYPE_SPIDER, boss_row)
	_spider_center = Vector2i(player_col, boss_row)
	_spider_web_timer = SPIDER_WEB_INTERVAL
	_show_banner.call("VOID SPIDER MATRIARCH!", Color(0.60, 0.10, 0.80))
	EventBus.boss_hint_popup.emit("Boss! Beware of web traps!")
	_shake_camera.call(8.0, 0.4)
	_pending_hints = ["Watch for WEB warnings — legs close in before the trap!", "Click the floating legs to chip away!", "Defeat the boss to restore energy!"]


func _spawn_blind_mole(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[2]
	var cs := _cell_size

	boss_center_pos = Vector2(player_col * cs + cs * 0.5, boss_row * cs + cs * 0.5)
	boss_segments.clear()

	# Core — mole body
	boss_segments.append({
		"pos": boss_center_pos,
		"hp": MOLE_CORE_HP,
		"max_hp": MOLE_CORE_HP,
		"is_core": true,
		"angle": 0.0,
		"orbit_r": 0.0,
		"is_claw": false,
	})

	# 4 claws — inner ring, tougher than body segments
	for i in 4:
		var a := float(i) / 4.0 * TAU
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * MOLE_ORBIT_RADIUS_INNER,
			"hp": MOLE_CLAW_HP,
			"max_hp": MOLE_CLAW_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": MOLE_ORBIT_RADIUS_INNER,
			"is_claw": true,
		})

	# 8 body segments — outer ring
	for i in 8:
		var a := float(i) / 8.0 * TAU + TAU / 16.0  # offset from claws
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * MOLE_ORBIT_RADIUS_OUTER,
			"hp": MOLE_SEGMENT_HP,
			"max_hp": MOLE_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": MOLE_ORBIT_RADIUS_OUTER,
			"is_claw": false,
		})

	_activate([], BOSS_TYPE_MOLE, boss_row)
	_mole_center = Vector2i(player_col, boss_row)
	_mole_tremor_timer = MOLE_TREMOR_INTERVAL
	_mole_burrow_timer = MOLE_BURROW_INTERVAL
	mole_burrowed = false

	_show_banner.call("THE COSMIC MOLE STIRS!", Color(0.55, 0.35, 0.85))
	EventBus.boss_hint_popup.emit("Boss! Watch out — it burrows!")
	_shake_camera.call(12.0, 0.6)
	_pending_hints = ["Watch for TREMOR warnings — get clear!", "The mole BURROWS underground and resurfaces near you!", "Click claws and body segments to defeat it!"]


func _spawn_stone_golem(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[3]
	var cs := _cell_size

	boss_center_pos = Vector2(player_col * cs + cs * 0.5, boss_row * cs + cs * 0.5)
	boss_segments.clear()

	# Core — invulnerable until all armor phases broken
	boss_segments.append({
		"pos": boss_center_pos,
		"hp": GOLEM_CORE_HP,
		"max_hp": GOLEM_CORE_HP,
		"is_core": true,
		"angle": 0.0,
		"orbit_r": 0.0,
	})

	# Phase 0 (copper armor) — 5 segments, outer ring
	for i in 5:
		var a := float(i) / 5.0 * TAU
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * GOLEM_ORBIT_RADIUS_OUTER,
			"hp": GOLEM_SEGMENT_HP,
			"max_hp": GOLEM_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": GOLEM_ORBIT_RADIUS_OUTER,
			"armor_phase": 0,
		})

	# Phase 1 (iron armor) — 5 segments, middle ring
	for i in 5:
		var a := float(i) / 5.0 * TAU + TAU / 10.0
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * GOLEM_ORBIT_RADIUS_MID,
			"hp": GOLEM_SEGMENT_HP,
			"max_hp": GOLEM_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": GOLEM_ORBIT_RADIUS_MID,
			"armor_phase": 1,
		})

	# Phase 2 (gold armor) — 5 segments, inner ring
	for i in 5:
		var a := float(i) / 5.0 * TAU + TAU / 5.0
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * GOLEM_ORBIT_RADIUS_INNER,
			"hp": GOLEM_SEGMENT_HP,
			"max_hp": GOLEM_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": GOLEM_ORBIT_RADIUS_INNER,
			"armor_phase": 2,
		})

	_activate([], BOSS_TYPE_GOLEM, boss_row)
	golem_phase = 0

	# Seed guaranteed ore pockets so the player is never locked out
	_seed_golem_ores(player_col, boss_row, [])

	var required := GOLEM_PHASE_ORES[0].capitalize()
	_show_banner.call("ASTEROID GOLEM AWAKENS!", Color(0.60, 0.55, 0.85))
	EventBus.boss_hint_popup.emit("Armored boss! Mine nearby ore to unlock damage!")
	_shake_camera.call(14.0, 0.8)
	_pending_hints = ["Step 1: Mine " + required + " ore (not the boss!)", "Step 2: Then click the glowing boss segments!", "Wrong ore type? It blocks all damage!"]


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
			_set_grid(pos.x, pos.y, ore_tile)
			idx += 1
			placed += 1


func _spawn_ancient_one(player_col: int) -> void:
	var boss_row := BOSS_MILESTONES[4]
	var cs := _cell_size

	boss_center_pos = Vector2(player_col * cs + cs * 0.5, boss_row * cs + cs * 0.5)
	boss_segments.clear()

	# Core
	boss_segments.append({
		"pos": boss_center_pos,
		"hp": ANCIENT_CORE_HP,
		"max_hp": ANCIENT_CORE_HP,
		"is_core": true,
		"angle": 0.0,
		"orbit_r": 0.0,
	})

	# 12 outer shell segments — wide ring (phase 0)
	for i in 12:
		var a := float(i) / 12.0 * TAU
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * ANCIENT_ORBIT_RADIUS_OUTER,
			"hp": ANCIENT_SEGMENT_HP,
			"max_hp": ANCIENT_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": ANCIENT_ORBIT_RADIUS_OUTER,
			"ring": 0,
		})

	# 8 inner crystal segments — tighter ring (phase 1)
	for i in 8:
		var a := float(i) / 8.0 * TAU + TAU / 16.0
		boss_segments.append({
			"pos": boss_center_pos + Vector2(cos(a), sin(a)) * ANCIENT_ORBIT_RADIUS_INNER,
			"hp": ANCIENT_SEGMENT_HP,
			"max_hp": ANCIENT_SEGMENT_HP,
			"is_core": false,
			"angle": a,
			"orbit_r": ANCIENT_ORBIT_RADIUS_INNER,
			"ring": 1,
		})

	_activate([], BOSS_TYPE_ANCIENT, boss_row)
	_ancient_center = Vector2i(player_col, boss_row)
	ancient_phase = 0
	_ancient_void_timer = 0.0
	ancient_void_warning_active = false
	ancient_core_recharge_warning = false
	_ancient_jitter_timer = 0.0

	_show_banner.call("THE ANCIENT STAR BEAST AWAKENS!", Color(0.15, 0.70, 0.90))
	EventBus.boss_hint_popup.emit("Final boss! Break the outer shell first!")
	_shake_camera.call(16.0, 1.0)
	_pending_hints = [
		"Phase 1: Click the outer ring segments!",
		"Phase 2: Void pulses seal passages — keep moving!",
		"Phase 3: The core regenerates and moves erratically!",
	]


func _activate(positions: Array[Vector2i], type: int, spawn_row: int) -> void:
	# Deduplicate positions — clamping near grid edges can produce repeats
	var seen: Dictionary = {}
	var unique: Array[Vector2i] = []
	for p in positions:
		if not seen.has(p):
			seen[p] = true
			unique.append(p)
	boss_tile_positions = unique
	boss_active = true
	boss_type = type
	boss_pulse_time = 0.0
	_boss_spawn_row = spawn_row
	SoundManager.play_boss_stinger_sound()


# ---------------------------------------------------------------------------
# Defeat
# ---------------------------------------------------------------------------

func _clear_boss_state() -> void:
	boss_active = false
	boss_tile_positions.clear()
	boss_type = BOSS_TYPE_NONE
	boss_segments.clear()
	boss_center_pos = Vector2.ZERO
	# Rat
	_rat_center = Vector2i(-1, -1)
	_rat_charge_timer = 0.0
	rat_charge_warning_active = false
	rat_charge_warning_timer = 0.0
	rat_charge_target_pos = Vector2i(-1, -1)
	# Spider
	_spider_center = Vector2i(-1, -1)
	_spider_web_timer = 0.0
	spider_web_warning_active = false
	spider_web_warning_timer = 0.0
	spider_web_target_pos = Vector2i(-1, -1)
	_spider_facing_angle = 0.0
	# Mole
	_mole_tremor_timer = 0.0
	mole_tremor_warning_active = false
	_mole_center = Vector2i(-1, -1)
	mole_burrowed = false
	_mole_burrow_timer = 0.0
	_mole_burrow_phase_timer = 0.0
	# Golem
	golem_phase = 0
	# Ancient
	ancient_phase = 0
	ancient_void_warning_active = false
	ancient_core_recharge_warning = false
	_ancient_center = Vector2i(-1, -1)
	_ancient_void_timer = 0.0
	_ancient_core_recharge_timer = 0.0
	_ancient_jitter_timer = 0.0


func _on_boss_defeated() -> void:
	_clear_boss_state()
	GameManager.bosses_defeated_total += 1
	GameManager.add_currency(BOSS_REWARD_BONUS)
	EventBus.minerals_earned.emit(BOSS_REWARD_BONUS)
	EventBus.ore_mined_popup.emit(BOSS_REWARD_BONUS, "Boss defeated!")
	SoundManager.play_boss_defeated_sound()
	_show_banner.call("BOSS DEFEATED!", Color(0.30, 1.00, 0.40))
	GameManager.restore_energy(50)
	EventBus.ore_mined_popup.emit(50, "Energy restored!")
	# Award XP for defeating a boss
	GameManager.add_xp(500)
	_shake_camera.call(14.0, 0.6)


func _on_boss_despawned() -> void:
	# Remove any remaining grid-based boss tiles (safety — floating bosses don't use these)
	for bp in boss_tile_positions:
		if _is_valid_pos(bp):
			_set_grid(bp.x, bp.y, 0)  # EMPTY
			_set_collision.call(bp.x, bp.y, false)
			_erase_tile_state.call(bp)
	_clear_boss_state()
	_show_banner.call("Boss retreats...", Color(0.70, 0.70, 0.70))
	EventBus.boss_hint_popup.emit("The boss has retreated — keep mining!")


func _is_valid_pos(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < _grid_cols and pos.y >= 0 and pos.y < _grid_rows


# ---------------------------------------------------------------------------
# Blind Mole tremor + burrow logic
# ---------------------------------------------------------------------------

func _update_blind_mole(delta: float) -> void:
	if boss_type != BOSS_TYPE_MOLE:
		return

	var cs := _cell_size

	# Burrow mechanic — dive underground, then surface near the player
	if mole_burrowed:
		_mole_burrow_phase_timer -= delta
		if _mole_burrow_phase_timer <= 0.0:
			mole_burrowed = false
			if _player_col >= 0 and _player_row >= 0:
				var player_px := Vector2(_player_col * cs + cs * 0.5, _player_row * cs + cs * 0.5)
				var offset := Vector2(randf_range(-120, 120), randf_range(-80, 80))
				boss_center_pos = player_px + offset
			# Snap all segments to new orbital positions
			for seg in boss_segments:
				if seg.is_core:
					seg.pos = boss_center_pos
				else:
					seg.pos = boss_center_pos + Vector2(cos(seg.angle), sin(seg.angle)) * seg.orbit_r
			_mole_center = Vector2i(roundi(boss_center_pos.x / cs), roundi(boss_center_pos.y / cs))
			_show_banner.call("MOLE SURFACES!", Color(0.55, 0.35, 0.85))
			_shake_camera.call(10.0, 0.5)
			EventBus.boss_hint_popup.emit("The mole has surfaced!")
		return  # Don't process other logic while burrowed

	# Move center toward player
	if _player_col >= 0 and _player_row >= 0:
		var player_px := Vector2(_player_col * cs + cs * 0.5, _player_row * cs + cs * 0.5)
		var dir := player_px - boss_center_pos
		var dist := dir.length()
		if dist > 4.0:
			boss_center_pos += dir.normalized() * minf(MOLE_FOLLOW_SPEED * delta, dist)

	# Update segment orbital positions
	for seg in boss_segments:
		if seg.is_core:
			seg.pos = boss_center_pos + Vector2(sin(boss_pulse_time * 1.8) * 5.0, 0.0)
		else:
			var speed_mult := 0.7 if seg.get("is_claw", false) else 1.0
			seg.angle += MOLE_ORBIT_SPEED * delta * speed_mult
			seg.pos = boss_center_pos + Vector2(cos(seg.angle), sin(seg.angle)) * seg.orbit_r

	_mole_center = Vector2i(roundi(boss_center_pos.x / cs), roundi(boss_center_pos.y / cs))

	# Burrow timer
	_mole_burrow_timer -= delta
	if _mole_burrow_timer <= 0.0:
		_mole_burrow_timer = MOLE_BURROW_INTERVAL
		mole_burrowed = true
		_mole_burrow_phase_timer = MOLE_BURROW_DURATION
		EventBus.boss_hint_popup.emit("MOLE BURROWS UNDERGROUND!")
		SoundManager.play_boss_warning_sound()
		_shake_camera.call(6.0, 0.3)

	# Tremor timer
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
		SoundManager.play_boss_warning_sound()
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
				_set_grid(tc, tr, new_tile)
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

	var cs := _cell_size

	# Move center toward the player position (slowly)
	if _player_col >= 0 and _player_row >= 0:
		var player_px := Vector2(_player_col * cs + cs * 0.5, _player_row * cs + cs * 0.5)
		var dir := (player_px - boss_center_pos)
		var dist := dir.length()
		if dist > 4.0:
			boss_center_pos += dir.normalized() * minf(RAT_FOLLOW_SPEED * delta, dist)

	# Update segment orbital positions
	for seg in boss_segments:
		if seg.is_core:
			seg.pos = boss_center_pos + Vector2(0, sin(boss_pulse_time * 2.5) * 4.0)
		else:
			seg.angle += RAT_ORBIT_SPEED * delta * (0.7 if seg.orbit_r > 120.0 else 1.3)
			seg.pos = boss_center_pos + Vector2(cos(seg.angle), sin(seg.angle)) * seg.orbit_r

	# Update grid-coord center for charge direction
	_rat_center = Vector2i(roundi(boss_center_pos.x / cs), roundi(boss_center_pos.y / cs))

	# Charge attack timer
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
		SoundManager.play_boss_warning_sound()
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
			_set_grid(col, row, new_tile)
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

	var cs := _cell_size

	# Move center toward player slowly — spiders lurk
	if _player_col >= 0 and _player_row >= 0:
		var player_px := Vector2(_player_col * cs + cs * 0.5, _player_row * cs + cs * 0.5)
		var dir := player_px - boss_center_pos
		var dist := dir.length()
		if dist > 4.0:
			boss_center_pos += dir.normalized() * minf(SPIDER_FOLLOW_SPEED * delta, dist)

		# Rotate the whole spider to face the player
		var target_angle := dir.angle()
		var angle_diff := wrapf(target_angle - _spider_facing_angle, -PI, PI)
		_spider_facing_angle += angle_diff * 2.0 * delta

	# Update segment positions — legs maintain fixed angular offsets from facing
	for seg in boss_segments:
		if seg.is_core:
			seg.pos = boss_center_pos + Vector2(0, sin(boss_pulse_time * 2.0) * 3.0)
		else:
			# Leg direction based on spider's facing angle + this leg's offset
			var leg_angle: float = _spider_facing_angle + seg.get("base_angle_offset", 0.0)

			# Leg retraction during web warning — legs close in like a trap
			var target_r: float = seg.get("base_orbit_r", SPIDER_ORBIT_RADIUS)
			if spider_web_warning_active:
				target_r *= 0.3
			seg.orbit_r = lerpf(seg.orbit_r, target_r, 3.0 * delta)

			# Breathing effect — legs pulse in and out
			var breathe := sin(boss_pulse_time * 1.5) * 12.0
			var r: float = seg.orbit_r + breathe

			seg.angle = leg_angle
			seg.pos = boss_center_pos + Vector2(cos(leg_angle), sin(leg_angle)) * r

	_spider_center = Vector2i(roundi(boss_center_pos.x / cs), roundi(boss_center_pos.y / cs))

	# Web attack timer
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
		SoundManager.play_boss_warning_sound()
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
				_set_grid(tc, tr, new_tile)
				_set_collision.call(tc, tr, true)
				_erase_tile_state.call(Vector2i(tc, tr))
				webbed += 1

	if webbed > 0:
		EventBus.ore_mined_popup.emit(0, "Webbed! " + str(webbed) + " tiles trapped!")
	_shake_camera.call(6.0, 0.4)
	spider_web_target_pos = Vector2i(-1, -1)


# ---------------------------------------------------------------------------
# Stone Golem orbital logic
# ---------------------------------------------------------------------------

func _update_golem(delta: float) -> void:
	if boss_type != BOSS_TYPE_GOLEM:
		return

	var cs := _cell_size

	# Move center toward player very slowly — golems are ponderous
	if _player_col >= 0 and _player_row >= 0:
		var player_px := Vector2(_player_col * cs + cs * 0.5, _player_row * cs + cs * 0.5)
		var dir := player_px - boss_center_pos
		var dist := dir.length()
		if dist > 4.0:
			boss_center_pos += dir.normalized() * minf(GOLEM_FOLLOW_SPEED * delta, dist)

	# Update segment orbital positions
	for seg in boss_segments:
		if seg.is_core:
			seg.pos = boss_center_pos + Vector2(0, sin(boss_pulse_time * 1.5) * 3.0)
		else:
			seg.angle += GOLEM_ORBIT_SPEED * delta
			seg.pos = boss_center_pos + Vector2(cos(seg.angle), sin(seg.angle)) * seg.orbit_r


# ---------------------------------------------------------------------------
# The Ancient Star Beast phase logic
# ---------------------------------------------------------------------------

func _update_ancient_one(delta: float) -> void:
	if boss_type != BOSS_TYPE_ANCIENT:
		return

	var cs := _cell_size

	# Move center — speed escalates with phase
	if _player_col >= 0 and _player_row >= 0:
		var player_px := Vector2(_player_col * cs + cs * 0.5, _player_row * cs + cs * 0.5)
		var follow_speed: float
		match ancient_phase:
			0: follow_speed = ANCIENT_FOLLOW_SPEED_P1
			1: follow_speed = ANCIENT_FOLLOW_SPEED_P2
			_: follow_speed = ANCIENT_FOLLOW_SPEED_P2

		var dir := player_px - boss_center_pos
		var dist := dir.length()
		if dist > 4.0:
			boss_center_pos += dir.normalized() * minf(follow_speed * delta, dist)

	# Phase 3: erratic jitter — short random teleports
	if ancient_phase == 2:
		_ancient_jitter_timer -= delta
		if _ancient_jitter_timer <= 0.0:
			_ancient_jitter_timer = randf_range(ANCIENT_JITTER_MIN, ANCIENT_JITTER_MAX)
			var jitter := Vector2(randf_range(-ANCIENT_JITTER_RANGE, ANCIENT_JITTER_RANGE),
								  randf_range(-ANCIENT_JITTER_RANGE * 0.5, ANCIENT_JITTER_RANGE * 0.5))
			boss_center_pos += jitter
			_shake_camera.call(3.0, 0.15)

	# Update segment orbital positions
	for seg in boss_segments:
		if seg.is_core:
			seg.pos = boss_center_pos + Vector2(0, sin(boss_pulse_time * 2.0) * 5.0)
		else:
			var ring: int = seg.get("ring", 0)
			var speed := ANCIENT_ORBIT_SPEED_OUTER if ring == 0 else ANCIENT_ORBIT_SPEED_INNER
			var direction := 1.0 if ring == 0 else -1.0  # inner ring counter-rotates
			seg.angle += speed * direction * delta
			seg.pos = boss_center_pos + Vector2(cos(seg.angle), sin(seg.angle)) * seg.orbit_r

	_ancient_center = Vector2i(roundi(boss_center_pos.x / cs), roundi(boss_center_pos.y / cs))

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
				SoundManager.play_boss_warning_sound()
				_shake_camera.call(4.0, 0.3)

	# Phase 3: core periodically recharges HP
	elif ancient_phase == 2:
		_ancient_core_recharge_timer -= delta
		ancient_core_recharge_warning = _ancient_core_recharge_timer <= 2.0
		if _ancient_core_recharge_timer <= 0.0:
			_ancient_core_recharge_timer = ANCIENT_CORE_RECHARGE_INTERVAL
			ancient_core_recharge_warning = false
			# Reset core segment HP instead of grid tile state
			for seg in boss_segments:
				if seg.is_core:
					seg.hp = ANCIENT_CORE_HP
					break
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
				_set_grid(tc, tr, _TILE_DIRT_DARK)
				_set_collision.call(tc, tr, true)
				_erase_tile_state.call(Vector2i(tc, tr))
				sealed += 1

	if sealed > 0:
		EventBus.ore_mined_popup.emit(0, "Void Pulse! " + str(sealed) + " tiles sealed!")
	_shake_camera.call(8.0, 0.5)


## Reset all state at the start of a new run.
func reset() -> void:
	_clear_boss_state()
	boss_pulse_time = 0.0
	_boss_milestones_seen = [false, false, false, false, false]
	_boss_spawn_row = -1
	mole_tremor_warning_timer = 0.0
	spider_web_warning_timer = 0.0
	ancient_void_warning_timer = 0.0
	_ancient_void_timer = 0.0
	_ancient_core_recharge_timer = 0.0
	_mole_burrow_timer = 0.0
	_mole_burrow_phase_timer = 0.0
	_ancient_jitter_timer = 0.0
