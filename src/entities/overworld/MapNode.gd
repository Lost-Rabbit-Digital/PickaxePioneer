class_name MapNode
extends Area2D

# Represents a location on the Overworld

enum NodeType {
	EMPTY,
	ASTEROID,
	STATION
}

@export var location_name: String = "Unknown"
@export var node_type: NodeType = NodeType.EMPTY
@export var scene_path: String = ""
@export var description: String = ""
@export var difficulty: int = 1
@export var ore_types: Array = []

signal node_clicked(node: MapNode)

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	input_event.connect(_on_input_event)
	_update_visuals()

func _update_visuals() -> void:
	label.text = location_name
	
	match node_type:
		NodeType.ASTEROID:
			sprite.texture = preload("res://assets/social_icons/godot_icon_normal.png")
			sprite.scale = Vector2(0.5, 0.5) # Adjust scale if needed
		NodeType.STATION:
			sprite.modulate = Color.CYAN
		NodeType.EMPTY:
			sprite.modulate = Color.WHITE

var neighbors: Array[MapNode] = []

func highlight(active: bool) -> void:
	if active:
		sprite.scale = Vector2(1.2, 1.2)
		label.modulate = Color.YELLOW
	else:
		sprite.scale = Vector2(1.0, 1.0)
		if node_type == NodeType.ASTEROID:
			sprite.scale = Vector2(0.5, 0.5)
		label.modulate = Color.WHITE

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		node_clicked.emit(self)
