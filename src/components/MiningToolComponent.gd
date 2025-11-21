class_name MiningToolComponent
extends Node

# Component to handle shooting

@export var projectile_scene: PackedScene
@export var fire_rate: float = 0.5
@export var projectile_speed: float = 600.0
@export var projectile_lifetime: float = 2.0

var can_fire: bool = true
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = fire_rate
	timer.one_shot = true
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

func fire(spawn_position: Vector2, direction: Vector2) -> void:
	if not can_fire or not projectile_scene:
		return
	
	SoundManager.play_laser_sound()
	
	var projectile = projectile_scene.instantiate()
	projectile.position = spawn_position
	projectile.direction = direction
	projectile.speed = projectile_speed
	projectile.lifetime = projectile_lifetime
	
	# Add to the main scene (or a specific container if we had one)
	get_tree().root.add_child(projectile)
	
	can_fire = false
	timer.start()

func _on_timer_timeout() -> void:
	can_fire = true
