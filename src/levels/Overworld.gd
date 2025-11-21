class_name Overworld
extends Node2D

# Overworld Map

@onready var caravan: Caravan = $Caravan

func _ready() -> void:
	# Start overworld music
	var music = load("res://assets/overworld.mp3")
	MusicManager.play_music(music)
	
	# Connect all map nodes
	for child in get_children():
		if child is MapNode:
			child.node_clicked.connect(_on_node_clicked)

func _on_node_clicked(node: MapNode) -> void:
	caravan.move_to(node.position)
	
	# Wait for arrival (simplified for prototype)
	await get_tree().create_timer(1.0).timeout
	
	if node.node_type == MapNode.NodeType.ASTEROID or node.node_type == MapNode.NodeType.STATION:
		GameManager.load_mining_level(node.scene_path)
