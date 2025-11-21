class_name PlayerProbe
extends CharacterBody2D

# Player Probe Entity

@onready var velocity_component: VelocityComponent = $VelocityComponent
@onready var health_component: HealthComponent = $HealthComponent
@onready var mining_tool: MiningToolComponent = $MiningToolComponent
@onready var sprite: Sprite2D = $Sprite2D

@onready var muzzle: Marker2D = $Muzzle
@onready var engine_sound: AudioStreamPlayer2D = $EngineSound

var sample_rate = 44100.0
var pulse_hz = 40.0 # Base engine rumble frequency
var phase = 0.0

func _ready() -> void:
	add_to_group("player") # Ensure player is in group for loot detection
	health_component.died.connect(_on_died)
	_setup_engine_sound()

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
	var input_vector = Vector2.ZERO
	var rotation_dir = 0.0
	
	# Thrust: Up Arrow or W (Removed ui_accept/Space)
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		# Thrust forward based on rotation
		var direction = Vector2.UP.rotated(rotation)
		velocity_component.accelerate(direction, delta)
		$EngineParticles.emitting = true
	else:
		velocity_component.decelerate(delta)
		$EngineParticles.emitting = false
		
	# Rotate Left: Left Arrow or A
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		rotation_dir -= 1.0
	# Rotate Right: Right Arrow or D
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		rotation_dir += 1.0
	
	rotation += velocity_component.turn(rotation_dir, delta)
	velocity_component.move(self, delta)
	
	# Shooting: Spacebar (ui_select)
	if Input.is_action_pressed("ui_select") or Input.is_key_pressed(KEY_SPACE):
		var fire_dir = Vector2.UP.rotated(rotation)
		mining_tool.fire(muzzle.global_position, fire_dir)

func _on_died() -> void:
	print("Player Died!")
	queue_free()
