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
			sprite.texture = preload("res://assets/asteroid.svg")
			sprite.scale = Vector2(0.5, 0.5) # Adjust scale if needed
		NodeType.STATION:
			sprite.modulate = Color.CYAN
		NodeType.EMPTY:
			sprite.modulate = Color.WHITE

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		node_clicked.emit(self)
