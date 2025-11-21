class_name ScrapLoot
extends Area2D

# Scrap Loot Entity

@export var magnet_radius: float = 150.0
@export var magnet_speed: float = 300.0
@export var acceleration: float = 800.0
@export var scrap_value: int = 1

var velocity: Vector2 = Vector2.ZERO
var is_magnetized: bool = false
var target: Node2D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Random initial velocity for "pop" effect
	velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100))

func _physics_process(delta: float) -> void:
	# Check for player if not already magnetized
	if not is_magnetized:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player = players[0]
			if global_position.distance_to(player.global_position) < magnet_radius:
				is_magnetized = true
				target = player
	
	if is_magnetized and target:
		var direction = global_position.direction_to(target.global_position)
		velocity = velocity.move_toward(direction * magnet_speed, acceleration * delta)
	else:
		# Friction
		velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	
	position += velocity * delta

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()

func collect() -> void:
	GameManager.add_currency(scrap_value)
	SoundManager.play_pickup_sound()
	# TODO: Particles
	queue_free()
