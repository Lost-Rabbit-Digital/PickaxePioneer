extends Node2D

@export var mineral_scene: PackedScene = preload("res://mineral.tscn")
@export var spawn_interval = 1.0
@export var spawn_radius = 1000.0

var player: CharacterBody2D

func _ready():
	player = get_tree().get_first_node_in_group("player")
	$Timer.wait_time = spawn_interval
	$Timer.start()

func _on_timer_timeout():
	if player:
		var spawn_position = player.global_position + Vector2.RIGHT.rotated(randf() * 2 * PI) * spawn_radius
		var mineral = mineral_scene.instantiate()
		mineral.global_position = spawn_position
		add_child(mineral)
