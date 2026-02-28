class_name PlayerProbe
extends CharacterBody2D

# Terraria-style CharacterBody2D player for the mining level.
# Handles gravity, horizontal movement, jumping, and cursor-based mining.
# MiningLevel provides the grid API for mining and hazard interactions.

const CELL_SIZE: int = 64

# Movement tuning
var move_speed: float = 280.0
var jump_velocity: float = -420.0
var gravity: float = 980.0

# Mining
var mine_range: float = 4.5  # Range in tiles
var _mining: bool = false
var _mine_target: Vector2i = Vector2i(-1, -1)
var _mine_timer: float = 0.0
const MINE_INTERVAL: float = 0.12  # Seconds between mining hits

# Reference set by MiningLevel after instantiation
var mining_level: Node = null

@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var interact_prompt: Label = $PromptLayer/InteractPrompt

# Facing direction
var _facing_left: bool = true

# Jetpack
var has_jetpack: bool = true
const JETPACK_THRUST: float = -220.0     # Upward velocity applied each frame while thrusting
const JETPACK_ENERGY_RATE: float = 5.0     # Energy units consumed per second while thrusting
var _jetpack_active: bool = false
var _jetpack_energy_accum: float = 0.0

# Sprint — hold Shift for 1.5× speed, costs extra energy
const SPRINT_MULT: float = 1.5
const SPRINT_ENERGY_RATE: float = 4.0     # Energy units consumed per second while sprinting
var _sprinting: bool = false
var _sprint_energy_accum: float = 0.0

@onready var jetpack_sprite: Sprite2D = $JetpackSprite

func _ready() -> void:
	add_to_group("player")
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	move_speed = GameManager.get_max_speed()
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)
	sprite.play(&"idle")

func _physics_process(delta: float) -> void:
	if not mining_level or mining_level._game_over or mining_level._hub_visible or mining_level._energy_shop_visible or mining_level._trader_shop_visible:
		return

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		if velocity.y > 0:
			velocity.y = 0

	# Sprint — Shift held, burns energy, boosts horizontal speed
	_sprinting = Input.is_action_pressed("sprint") and GameManager.current_energy > 0
	var effective_speed := move_speed * (SPRINT_MULT if _sprinting else 1.0)

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	velocity.x = direction * effective_speed

	# Sprint energy drain (only while actually moving)
	if _sprinting and abs(direction) > 0.1:
		_sprint_energy_accum += SPRINT_ENERGY_RATE * delta
		if _sprint_energy_accum >= 1.0:
			var to_consume := int(_sprint_energy_accum)
			_sprint_energy_accum -= to_consume
			GameManager.consume_energy(to_consume)
	else:
		_sprint_energy_accum = 0.0

	# Flip sprite
	if direction < 0:
		_facing_left = true
		sprite.flip_h = false
	elif direction > 0:
		_facing_left = false
		sprite.flip_h = true

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Jetpack thrust — hold jump while airborne to fly upward, consumes energy
	# Sprint also boosts vertical thrust by 20% when airborne
	_jetpack_active = false
	if has_jetpack and not is_on_floor() and Input.is_action_pressed("jump") and GameManager.current_energy > 0:
		velocity.y = JETPACK_THRUST * (1.2 if _sprinting else 1.0)
		_jetpack_active = true
		_jetpack_energy_accum += JETPACK_ENERGY_RATE * delta
		if _jetpack_energy_accum >= 1.0:
			var to_consume := int(_jetpack_energy_accum)
			_jetpack_energy_accum -= to_consume
			GameManager.consume_energy(to_consume)

	# Sync jetpack sprite with player facing and active state
	jetpack_sprite.flip_h = sprite.flip_h
	jetpack_sprite.modulate = Color(1.0, 0.5, 0.1) if _jetpack_active else Color(1, 1, 1, 1)

	move_and_slide()

	# Check hazard contact after moving
	_check_hazard_contact()

	# Cursor mining
	_handle_mining(delta)

	# Update animation based on current state
	_update_animation()

func _update_animation() -> void:
	var anim: StringName

	if _mining and is_on_floor():
		anim = &"paw"
	elif not is_on_floor():
		anim = &"jump"
	elif abs(velocity.x) > 0.1:
		anim = &"movement"
	else:
		anim = &"idle"

	if sprite.animation != anim:
		sprite.play(anim)

func _handle_mining(delta: float) -> void:
	# No mining while flying with the jetpack
	if has_jetpack and not is_on_floor():
		_mining = false
		return

	if Input.is_action_pressed("mine"):
		var mouse_world := get_global_mouse_position()
		var grid_pos := Vector2i(
			floori(mouse_world.x / CELL_SIZE),
			floori(mouse_world.y / CELL_SIZE)
		)

		# Check range (distance from player center to target tile center)
		var player_tile := Vector2i(
			floori(global_position.x / CELL_SIZE),
			floori(global_position.y / CELL_SIZE)
		)
		var dist := Vector2(grid_pos - player_tile).length()
		if dist > mine_range:
			_mining = false
			return

		if grid_pos != _mine_target:
			_mine_target = grid_pos
			_mine_timer = MINE_INTERVAL  # Pre-fill so first hit fires immediately

		_mine_timer += delta
		if _mine_timer >= MINE_INTERVAL:
			_mine_timer -= MINE_INTERVAL
			if mining_level:
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
			mining_level.check_player_hazard(col, row)

func get_grid_pos() -> Vector2i:
	return Vector2i(
		floori(global_position.x / CELL_SIZE),
		floori(global_position.y / CELL_SIZE)
	)

func get_depth_row() -> int:
	var row := floori(global_position.y / CELL_SIZE)
	return maxi(0, row - mining_level.SURFACE_ROWS) if mining_level else 0

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

# Health
func take_damage(amount: int) -> void:
	health_component.damage(amount)

func heal(amount: int) -> void:
	health_component.heal(amount)

func is_at_max_health() -> bool:
	return health_component.current_health >= health_component.max_health

func _on_health_changed(current: int, max_hp: int) -> void:
	EventBus.player_health_changed.emit(current, max_hp)

func _on_died() -> void:
	EventBus.player_died.emit()
