class_name LootBase
extends Area2D

## Base class for collectible loot entities.
## Provides common magnet-pull, collection sound, and cleanup logic.
## Subclasses override _on_collect() for specific rewards.

@export var magnet_radius: float = 150.0
@export var magnet_speed: float = 300.0
@export var acceleration: float = 800.0

var velocity: Vector2 = Vector2.ZERO
var is_magnetized: bool = false
var target: Node2D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	velocity = Vector2(randf_range(-100, 100), randf_range(-100, 100))
	_loot_ready()


## Override in subclasses for additional setup.
func _loot_ready() -> void:
	pass


func _physics_process(delta: float) -> void:
	if not is_magnetized:
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			var player: Node2D = players[0]
			if global_position.distance_to(player.global_position) < magnet_radius:
				is_magnetized = true
				target = player

	if is_magnetized and target:
		var direction := global_position.direction_to(target.global_position)
		velocity = velocity.move_toward(direction * magnet_speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)

	position += velocity * delta


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		collect()


## Collect this loot — plays pickup sound, calls _on_collect(), and frees the node.
func collect() -> void:
	_on_collect()
	SoundManager.play_pickup_sound()
	queue_free()


## Override in subclasses to define what happens when collected (add currency, etc.).
func _on_collect() -> void:
	pass
