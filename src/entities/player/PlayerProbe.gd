class_name PlayerProbe
extends CharacterBody2D

# Terraria-style CharacterBody2D player for the mining level.
# Handles gravity, horizontal movement, jumping, and cursor-based mining.
# MiningLevel provides the grid API for mining and hazard interactions.
# Jetpack removed — player must plan routes and place ladders (F key) to climb.

const CELL_SIZE: int = 64

# Movement tuning
var move_speed: float = 280.0
var jump_velocity: float = -420.0
var gravity: float = 980.0

# Ladder climbing speed — will be computed from GameManager upgrade level
var ladder_climb_speed: float = 420.0

# Mining — will be computed from GameManager upgrade level
var mine_range: float = 4.5  # Range in tiles
var _mining: bool = false
var _mine_target: Vector2i = Vector2i(-1, -1)
var _mine_timer: float = 0.0
const MINE_INTERVAL: float = 0.21  # Seconds between mining hits (0.12 * 1.75 — 75% slower)

# Reference set by MiningLevel after instantiation
var mining_level: Node = null

# Whether the player is currently touching a ladder tile (set by MiningLevel each frame)
var on_ladder: bool = false
# True when the player is actively gripping the ladder (W or Up held — not Space)
var _gripping_ladder: bool = false
# True when the player is descending a ladder (S or Down held)
var _descending_ladder: bool = false

# Fall damage tracking
var _fall_start_y: float = 0.0
var _is_falling: bool = false
const FALL_DAMAGE_THRESHOLD: int = 12 * CELL_SIZE  # 3 tiles in pixels (192px)

@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_prompt: Label = $PromptLayer/InteractPrompt
@onready var _ice_follower: AnimatedSprite2D = $ElementalFollowers/IceElemental
@onready var _leaf_follower: AnimatedSprite2D = $ElementalFollowers/LeafElemental
@onready var sleep_label: RichTextLabel = $AnimatedSprite2D/SleepLabel

# Facing direction
var _facing_left: bool = true

# Idle to sleep transition
var _idle_timer: float = 0.0
const IDLE_TO_SLEEP_TIME: float = 5.0  # Seconds before transitioning to sleep

# Sprint — hold Shift for 1.5× speed, costs extra energy
const SPRINT_MULT: float = 1.5
const SPRINT_ENERGY_RATE: float = 2.0     # Energy units consumed per second while sprinting (halved)
var _sprinting: bool = false
var _sprint_energy_accum: float = 0.0

# Spider web slowdown — applied by MiningLevel when player touches a web
const WEB_SLOW_MULT: float = 0.5          # Move at half speed while slowed
const WEB_SLOW_DURATION: float = 2.0      # Seconds the slowdown lasts after web contact
var _web_slow_timer: float = 0.0

# Double jump
var _double_jumped: bool = false

# --- Particle system (walking dust + landing poof) ---
const PARTICLE_FEET_Y: float = 26.0        # Offset below player center to feet
const PARTICLE_MAX: int = 80               # Max simultaneous particles

const DUST_INTERVAL: float = 0.08          # Seconds between dust emits while walking
const DUST_LIFETIME: float = 0.35
const DUST_SIZE: float = 4.0

const POOF_COUNT: int = 14
const POOF_LIFETIME: float = 0.45
const POOF_SIZE_MIN: float = 5.0
const POOF_SIZE_MAX: float = 9.0
const POOF_VEL_THRESHOLD: float = 100.0   # Min fall speed (px/s) to trigger poof

var _particles: Array = []
var _dust_timer: float = 0.0
var _particle_layer: Node2D

# Follower trail system
const TRAIL_HISTORY_MAX: int = 30
const ICE_TRAIL_FRAMES: int = 8    # Ice follows 8 steps behind
const LEAF_TRAIL_FRAMES: int = 14  # Leaf follows 14 steps behind
const FOLLOWER_Y_OFFSET: float = -20.0  # Float above ground

var _trail_history: Array = []

func _ready() -> void:
	add_to_group("player")
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	move_speed = GameManager.get_max_speed()
	ladder_climb_speed = GameManager.get_ladder_climb_speed()
	mine_range = GameManager.get_mining_reach()
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)
	sprite.play(&"idle")
	sprite.modulate = GameManager.cat_color
	_init_followers()
	_particle_layer = Node2D.new()
	_particle_layer.z_index = 1
	add_child(_particle_layer)
	_particle_layer.draw.connect(_draw_particles_on_layer)

	# Multiplayer: set authority based on peer assignment (0 = not yet assigned / single player)
	# MiningLevel sets multiplayer_authority after instantiating the second player.

func _init_followers() -> void:
	_ice_follower.visible = GameManager.equipped_ice
	_leaf_follower.visible = GameManager.equipped_leaf
	if GameManager.equipped_ice:
		_ice_follower.play(&"idle")
	if GameManager.equipped_leaf:
		_leaf_follower.play(&"idle")

func update_follower_visibility() -> void:
	_ice_follower.visible = GameManager.equipped_ice
	_leaf_follower.visible = GameManager.equipped_leaf
	if GameManager.equipped_ice and not _ice_follower.is_playing():
		_ice_follower.play(&"idle")
	if GameManager.equipped_leaf and not _leaf_follower.is_playing():
		_leaf_follower.play(&"idle")

## RPC called each frame by the authoritative peer to keep the visual in sync.
@rpc("any_peer", "call_remote", "unreliable_ordered")
func rpc_sync_transform(pos: Vector2, facing_left: bool, anim: StringName) -> void:
	global_position = pos
	sprite.flip_h = facing_left
	if sprite.animation != anim:
		sprite.play(anim)
	sleep_label.visible = (anim == &"sleep")

func _physics_process(delta: float) -> void:
	# Non-authority instances are driven solely by rpc_sync_transform — no local simulation.
	if NetworkManager.is_multiplayer_session and not is_multiplayer_authority():
		return

	if not mining_level or mining_level._game_over or mining_level.any_ui_open() or (mining_level.get("_spawning") == true):
		return

	var pre_floor := is_on_floor()

	# Track fall start position
	if pre_floor and not _gripping_ladder and not _descending_ladder:
		# Player is on floor and not using ladder, reset fall tracking
		_is_falling = false
	elif not pre_floor and not _is_falling:
		# Player just left the ground, start tracking fall
		_is_falling = true
		_fall_start_y = global_position.y

	# Grip/climb: W or Up held.  Descend: S or Down held.  Neither: freefall.
	_gripping_ladder   = on_ladder and (Input.is_key_pressed(KEY_W)   or Input.is_key_pressed(KEY_UP))
	_descending_ladder = on_ladder and (Input.is_key_pressed(KEY_S)   or Input.is_key_pressed(KEY_DOWN))

	# Gravity — suppressed when on a ladder; player holds position unless actively climbing.
	if _gripping_ladder:
		velocity.y = -ladder_climb_speed  # Climb up
	elif _descending_ladder:
		velocity.y = ladder_climb_speed   # Controlled descent
	elif on_ladder:
		velocity.y = 0  # Hold still on ladder — no input, no gravity
	elif not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	# Web slowdown timer
	if _web_slow_timer > 0.0:
		_web_slow_timer -= delta

	# Sprint — Shift held, burns energy, boosts horizontal speed
	_sprinting = Input.is_action_pressed("sprint") and GameManager.current_energy > 0
	var web_mult := WEB_SLOW_MULT if _web_slow_timer > 0.0 else 1.0
	var effective_speed := move_speed * (SPRINT_MULT if _sprinting else 1.0) * web_mult

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * effective_speed

	# Sprint energy drain (only while actually moving and underground).
	# Guests route the cost through the host via RPC so it is deducted from the
	# authoritative shared pool rather than their local (overwritten) copy.
	if _sprinting and abs(direction) > 0.1 and get_depth_row() > 0:
		_sprint_energy_accum += SPRINT_ENERGY_RATE * delta
		if _sprint_energy_accum >= 1.0:
			var to_consume := int(_sprint_energy_accum)
			_sprint_energy_accum -= to_consume
			if NetworkManager.is_multiplayer_session and not NetworkManager.is_host and mining_level:
				mining_level.rpc_consume_energy_from_guest.rpc_id(1, to_consume)
			else:
				GameManager.consume_energy(to_consume)
	else:
		_sprint_energy_accum = 0.0

	# Flip sprite
	if direction > 0:
		_facing_left = false
		sprite.flip_h = false
	elif direction < 0:
		_facing_left = true
		sprite.flip_h = true

	# Reset double jump when grounded or on a ladder
	if is_on_floor() or on_ladder:
		_double_jumped = false

	# Jump from floor or release from ladder — Space jumps/launches in both cases.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			SoundManager.play_jump_sound()
		elif on_ladder:
			velocity.y = jump_velocity  # Jump releases the player from the ladder
			SoundManager.play_jump_sound()
		elif not _double_jumped:
			velocity.y = jump_velocity  # Double jump
			_double_jumped = true
			_spawn_poof()
			SoundManager.play_jump_sound()

	var pre_vel_y := velocity.y
	move_and_slide()

	_update_particles(delta, pre_floor, pre_vel_y)
	_particle_layer.queue_redraw()

	# Check hazard contact after moving
	_check_hazard_contact()

	# Cursor mining
	_handle_mining(delta)

	# Update animation based on current state
	_update_animation(delta)

	# Update follower trail and animations
	_update_followers()

	# Broadcast transform to the remote peer each frame (unreliable — slight lag is fine)
	if NetworkManager.is_multiplayer_session:
		rpc_sync_transform.rpc(global_position, _facing_left, sprite.animation)

func _update_animation(delta: float) -> void:
	var anim: StringName

	sleep_label.visible = false
	if _mining and is_on_floor():
		anim = &"paw"
		_idle_timer = 0.0
	elif _gripping_ladder or _descending_ladder:
		anim = &"movement"
		_idle_timer = 0.0
	elif not is_on_floor():
		anim = &"jump"
		_idle_timer = 0.0
	elif abs(velocity.x) > 0.1:
		anim = &"movement"
		_idle_timer = 0.0
	else:
		# Player is idle - track idle time
		_idle_timer += delta
		if _idle_timer >= IDLE_TO_SLEEP_TIME:
			sleep_label.visible = true
			anim = &"sleep"
		else:
			anim = &"idle"

	if sprite.animation != anim:
		sprite.play(anim)

func _handle_mining(delta: float) -> void:
	if GameManager.selected_hotbar_slot != 0:
		_mining = false
		return
	if Input.is_action_pressed("mine"):
		var mouse_world := get_global_mouse_position()
		var grid_pos := Vector2i(
			floori(mouse_world.x / CELL_SIZE),
			floori(mouse_world.y / CELL_SIZE)
		)

		# Check range: world-space distance from player position to tile centre.
		# This is more forgiving than tile-index distance because it accounts for
		# where the player actually stands within their tile.
		var tile_center := Vector2(grid_pos.x + 0.5, grid_pos.y + 0.5) * CELL_SIZE
		var dist := global_position.distance_to(tile_center) / CELL_SIZE
		if dist > mine_range + 0.5:
			_mining = false
			return

		if not mining_level.has_line_of_sight(global_position, grid_pos):
			_mining = false
			return

		if grid_pos != _mine_target:
			_mine_target = grid_pos
			_mine_timer = MINE_INTERVAL  # Pre-fill so first hit fires immediately

		_mine_timer += delta
		if _mine_timer >= MINE_INTERVAL:
			_mine_timer -= MINE_INTERVAL
			if mining_level:
				if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
					# Guest: send mine request to host for server-side validation
					mining_level.rpc_request_mine.rpc_id(1, grid_pos)
				else:
					mining_level.try_mine_at(grid_pos)
		_mining = true
	else:
		_mining = false

func _check_hazard_contact() -> void:
	if not mining_level:
		return
	# Check all cells the player overlaps
	var player_rect := Rect2(global_position - Vector2(CELL_SIZE * 0.4, CELL_SIZE * 0.4), Vector2(CELL_SIZE * 0.8, CELL_SIZE * 0.8))
	var min_col := maxi(0, floori(player_rect.position.x / CELL_SIZE))
	var max_col := mini(mining_level.GRID_COLS - 1, floori(player_rect.end.x / CELL_SIZE))
	var min_row := maxi(0, floori(player_rect.position.y / CELL_SIZE))
	var max_row := mini(mining_level.GRID_ROWS - 1, floori(player_rect.end.y / CELL_SIZE))

	for col in range(min_col, max_col + 1):
		for row in range(min_row, max_row + 1):
			mining_level.check_player_hazard(col, row, self)

func get_grid_pos() -> Vector2i:
	return Vector2i(
		floori(global_position.x / CELL_SIZE),
		floori(global_position.y / CELL_SIZE)
	)

func get_depth_row() -> int:
	var row := floori(global_position.y / CELL_SIZE)
	return maxi(0, row - mining_level.SURFACE_ROWS) if mining_level else 0

func is_sleeping() -> bool:
	return sprite.animation == &"sleep"

# Prompt helpers
func show_prompt(text: String) -> void:
	interact_prompt.text = text
	interact_prompt.visible = true

func hide_prompt() -> void:
	interact_prompt.visible = false

func set_prompt_position(screen_pos: Vector2) -> void:
	var sz := interact_prompt.size
	if sz.x < 1.0:
		sz = Vector2(320.0, 32.0)
	interact_prompt.position = Vector2(screen_pos.x - sz.x * 0.5, screen_pos.y - sz.y - 4.0)

# Spider web — called by MiningLevel when player contacts a web
func apply_web_slow() -> void:
	_web_slow_timer = WEB_SLOW_DURATION

# Health
func take_damage(amount: float) -> void:
	health_component.damage(amount)

func heal(amount: int) -> void:
	health_component.heal(amount)

func is_at_max_health() -> bool:
	return health_component.current_health >= float(health_component.max_health)

func _on_health_changed(current: float, max_hp: int) -> void:
	EventBus.player_health_changed.emit(current, max_hp)

func _on_died() -> void:
	SoundManager.play_death_sound()
	EventBus.player_died.emit()

func _update_particles(delta: float, was_on_floor: bool, vel_y_before_slide: float) -> void:
	# Landing poof — trigger on first frame touching floor after a real fall
	if is_on_floor() and not was_on_floor and vel_y_before_slide > POOF_VEL_THRESHOLD:
		_spawn_poof()
		SoundManager.play_land_sound()
		_apply_fall_damage()

	# Walking dust — emit small squares at feet while moving on the ground
	if is_on_floor() and abs(velocity.x) > 20.0 and not _gripping_ladder:
		_dust_timer += delta
		if _dust_timer >= DUST_INTERVAL and _particles.size() < PARTICLE_MAX:
			_dust_timer = 0.0
			_spawn_dust()
	else:
		_dust_timer = 0.0

	# Advance and prune particles
	var i := _particles.size() - 1
	while i >= 0:
		var p: Dictionary = _particles[i]
		p["life"] -= delta
		if p["life"] <= 0.0:
			_particles.remove_at(i)
		else:
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.80  # Air drag slows particles
		i -= 1

func _spawn_dust() -> void:
	_particles.append({
		"pos": global_position + Vector2(randf_range(-10.0, 10.0), PARTICLE_FEET_Y),
		"vel": Vector2(randf_range(-25.0, 25.0), randf_range(-45.0, -15.0)),
		"life": DUST_LIFETIME,
		"max_life": DUST_LIFETIME,
		"size": DUST_SIZE,
	})

func _spawn_poof() -> void:
	var count := mini(POOF_COUNT, PARTICLE_MAX - _particles.size())
	for _i in count:
		var angle := randf_range(-PI, 0.0)  # Upward hemisphere
		var speed := randf_range(50.0, 140.0)
		_particles.append({
			"pos": global_position + Vector2(randf_range(-18.0, 18.0), PARTICLE_FEET_Y),
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": POOF_LIFETIME,
			"max_life": POOF_LIFETIME,
			"size": randf_range(POOF_SIZE_MIN, POOF_SIZE_MAX),
		})

func _apply_fall_damage() -> void:
	if _is_falling:
		var fall_distance := global_position.y - _fall_start_y
		if fall_distance > FALL_DAMAGE_THRESHOLD:
			var damage := health_component.max_health / 2
			health_component.damage(damage)
			var cam := get_viewport().get_camera_2d()
			if cam is CameraShake:
				cam.add_trauma(0.85)
		_is_falling = false

func _update_followers() -> void:
	# Record player world position for trail
	_trail_history.push_back(global_position)
	if _trail_history.size() > TRAIL_HISTORY_MAX:
		_trail_history.pop_front()

	var is_moving: bool = abs(velocity.x) > 10.0
	var follower_anim: StringName = &"move" if is_moving else &"idle"

	if _ice_follower.visible:
		var idx := maxi(0, _trail_history.size() - 1 - ICE_TRAIL_FRAMES)
		var trail_pos: Vector2 = _trail_history[idx] + Vector2(0.0, FOLLOWER_Y_OFFSET)
		_ice_follower.global_position = trail_pos
		_ice_follower.flip_h = sprite.flip_h
		if _ice_follower.animation != follower_anim:
			_ice_follower.play(follower_anim)

	if _leaf_follower.visible:
		var idx := maxi(0, _trail_history.size() - 1 - LEAF_TRAIL_FRAMES)
		var trail_pos: Vector2 = _trail_history[idx] + Vector2(0.0, FOLLOWER_Y_OFFSET)
		_leaf_follower.global_position = trail_pos
		_leaf_follower.flip_h = sprite.flip_h
		if _leaf_follower.animation != follower_anim:
			_leaf_follower.play(follower_anim)

func _draw_particles_on_layer() -> void:
	for p: Dictionary in _particles:
		var lpos := _particle_layer.to_local(p["pos"])
		var alpha: float = p["life"] / p["max_life"]
		var sz: float = p["size"]
		_particle_layer.draw_rect(Rect2(lpos.x - sz * 0.5, lpos.y - sz * 0.5, sz, sz), Color(1.0, 1.0, 1.0, alpha))
