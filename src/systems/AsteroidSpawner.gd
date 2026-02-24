class_name AsteroidSpawner
extends Node

# Spawns asteroids randomly

@export var asteroid_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-500, -500, 1000, 1000)
@export var max_asteroids: int = 10

func _ready() -> void:
	# Initial spawn
	for i in range(max_asteroids):
		spawn_asteroid()
	
	# Periodic spawn check could go here

func spawn_asteroid() -> void:
	if not asteroid_scene:
		return
		
	var asteroid = asteroid_scene.instantiate()
	var pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	asteroid.position = pos
	asteroid.add_to_group("asteroids")
	
	# Add to scene
	add_child(asteroid)
