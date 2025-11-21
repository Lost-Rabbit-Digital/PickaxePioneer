extends Node2D

@export var quest_npc_scene: PackedScene = preload("res://src/entities/npcs/QuestNPC.tscn")
@export var npc_spawn_chance: float = 0.5

func _ready() -> void:
	# Start mining music
	var music = load("res://assets/mine.mp3")
	MusicManager.play_music(music)
	
	# Clear any previous quest
	QuestManager.clear_quest()
	
	# Spawn quest NPC with 50% chance
	if randf() < npc_spawn_chance:
		_spawn_quest_npc()

func _spawn_quest_npc() -> void:
	var npc = quest_npc_scene.instantiate()
	var spawn_area = Rect2(-1400, -900, 2800, 1800)
	var pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	npc.global_position = pos
	add_child(npc)
