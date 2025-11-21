class_name MutantSpawner
extends Node

@export var mutant_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-1500, -1000, 3000, 2000)
@export var mutant_count: int = 15

func _ready() -> void:
	for i in range(mutant_count):
		spawn_mutant()

func spawn_mutant() -> void:
	if not mutant_scene:
		return
		
	var mutant = mutant_scene.instantiate()
	var pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	mutant.position = pos
	add_child(mutant)
