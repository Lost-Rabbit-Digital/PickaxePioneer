class_name PlayerProbe
extends CharacterBody2D

# Player Probe Entity

@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var sprite: Sprite2D = $Sprite2D
@onready var drill_area: Area2D = $DrillArea
@onready var drill_visual: Polygon2D = $DrillVisual

@onready var engine_sound: AudioStreamPlayer2D = $EngineSound

var sample_rate = 44100.0
var pulse_hz = 40.0 # Base engine rumble frequency
var phase = 0.0

var is_drilling: bool = false
var drill_cooldown: float = 0.0
const DRILL_RATE: float = 0.3 # Time between drill hits

func _ready() -> void:
	add_to_group("player") # Ensure player is in group for loot detection
	health_component.died.connect(_on_died)
	health_component.health_changed.connect(_on_health_changed)
	_setup_engine_sound()
	_emit_initial_health()

func _emit_initial_health() -> void:
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)

func _setup_engine_sound() -> void:
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.1
	engine_sound.stream = stream
	engine_sound.play()

func _process(delta: float) -> void:
	_update_engine_sound()

func _update_engine_sound() -> void:
	var playback = engine_sound.get_stream_playback()
	if not playback:
		return

	var frames = playback.get_frames_available()
	if frames <= 0:
		return

	var speed_ratio = velocity_component.velocity.length() / velocity_component.max_speed
	var target_hz = 40.0 + (speed_ratio * 60.0) # 40Hz idle -> 100Hz max
	var volume = 0.2 + (speed_ratio * 0.3) # Louder when moving

	for i in range(frames):
		var increment = target_hz / sample_rate
		phase = fmod(phase + increment, 1.0)
		# Simple sawtooth-like wave for "engine" sound
		var sample_val = (phase * 2.0 - 1.0) * volume
		playback.push_frame(Vector2.ONE * sample_val)

func _physics_process(delta: float) -> void:
	var rotation_dir = 0.0

	# Tank Controls: Rotate Left/Right
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		rotation_dir -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		rotation_dir += 1.0

	rotation += velocity_component.turn(rotation_dir, delta)

	# Tank Controls: Forward/Backward along facing direction
	var forward = Vector2.UP.rotated(rotation)

	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		velocity_component.accelerate(forward, delta)
		$EngineParticles.emitting = true
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		velocity_component.accelerate(-forward * 0.5, delta) # Reverse at half speed
		$EngineParticles.emitting = false
	else:
		velocity_component.decelerate(delta)
		$EngineParticles.emitting = false

	velocity_component.move(self, delta)

	# Drill: Spacebar activates the drill
	if Input.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SPACE):
		is_drilling = true
		drill_visual.color = Color(0.8, 0.8, 0.2, 1.0) # Bright yellow when active
	else:
		is_drilling = false
		drill_visual.color = Color(0.5, 0.5, 0.5, 1.0) # Grey when inactive

	# Handle drill cooldown
	if drill_cooldown > 0:
		drill_cooldown -= delta

	# Check for drill hits
	if is_drilling and drill_cooldown <= 0:
		_check_drill_hits()

func _check_drill_hits() -> void:
	var overlapping_areas = drill_area.get_overlapping_areas()
	var overlapping_bodies = drill_area.get_overlapping_bodies()

	var hit_something = false

	for area in overlapping_areas:
		if area is HurtboxComponent:
			area.take_damage(GameManager.get_drill_damage())
			hit_something = true
		elif area.get_parent() is Mutant:
			area.get_parent().take_damage(GameManager.get_drill_damage())
			hit_something = true

	for body in overlapping_bodies:
		if body is Mutant:
			body.take_damage(GameManager.get_drill_damage())
			hit_something = true

	if hit_something:
		SoundManager.play_drill_sound()
		drill_cooldown = DRILL_RATE

func _on_health_changed(current: int, max_hp: int) -> void:
	EventBus.player_health_changed.emit(current, max_hp)

func _on_died() -> void:
	print("Player Died!")
	queue_free()
