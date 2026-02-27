class_name MapNode
extends Area2D

# Represents a location on the Overworld

enum NodeType {
	EMPTY,
	MINE,       # was ASTEROID — ordinal kept at 1 so existing .tscn data is unchanged
	STATION,
	SETTLEMENT  # overworld rest-stop / trader node
}

@export var location_name: String = "Unknown"
@export var node_type: NodeType = NodeType.EMPTY
@export var scene_path: String = ""
@export var description: String = ""
@export var difficulty: int = 1
@export var ore_types: Array = []
@export var hazard_types: Array = []

signal node_clicked(node: MapNode)

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	input_event.connect(_on_input_event)
	_update_visuals()

func _update_visuals() -> void:
	label.text = location_name

	match node_type:
		NodeType.MINE:
			# Use the ant spritesheet as the mine icon (same asset as the player)
			sprite.texture = preload("res://assets/creatures/red_ant_spritesheet.png")
			sprite.scale = Vector2(2.5, 2.5)
			sprite.modulate = Color(1.0, 0.75, 0.20)  # warm gold tint for mines
		NodeType.STATION:
			sprite.modulate = Color.CYAN
		NodeType.SETTLEMENT:
			sprite.modulate = Color(0.85, 0.60, 1.0)  # soft purple for settlements
		NodeType.EMPTY:
			sprite.modulate = Color.WHITE

var neighbors: Array[MapNode] = []

func highlight(active: bool) -> void:
	if active:
		sprite.scale = Vector2(3.0, 3.0) if node_type == NodeType.MINE else Vector2(1.2, 1.2)
		label.modulate = Color.YELLOW
	else:
		sprite.scale = Vector2(2.5, 2.5) if node_type == NodeType.MINE else Vector2(1.0, 1.0)
		label.modulate = Color.WHITE

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		node_clicked.emit(self)
