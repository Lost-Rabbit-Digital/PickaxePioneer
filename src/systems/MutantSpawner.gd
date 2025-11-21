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
	
	# Randomize properties
	var color = Color(randf(), randf(), randf())
	# Bias towards red/green/purple for "mutant" look
	if randf() > 0.5:
		color = Color(randf_range(0.5, 1.0), randf_range(0.0, 0.5), randf_range(0.0, 0.5)) # Reddish
	else:
		color = Color(randf_range(0.0, 0.5), randf_range(0.5, 1.0), randf_range(0.0, 0.5)) # Greenish
		
	var speed_mult = randf_range(0.8, 1.5)
	var move_type = 0 # WANDER
	if randf() > 0.7: # 30% chance to be a chaser
		move_type = 1 # CHASE
		color = Color(1.0, 0.2, 0.2) # Chasers are bright red
		speed_mult = 0.8 # And faster (actually slower now per request)
		
	mutant.setup(color, speed_mult, move_type)
	
	add_child(mutant)
