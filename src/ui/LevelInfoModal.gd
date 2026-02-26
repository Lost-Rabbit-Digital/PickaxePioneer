class_name LevelInfoModal
extends CanvasLayer

# Shown on the overworld before the player enters a node.
# Displays location name, type, description, difficulty, and ore types.

signal confirmed(node: MapNode)
signal cancelled

@onready var title_label: Label = $Control/Panel/MarginContainer/VBox/TitleLabel
@onready var type_label: Label = $Control/Panel/MarginContainer/VBox/TypeLabel
@onready var description_label: Label = $Control/Panel/MarginContainer/VBox/DescriptionLabel
@onready var difficulty_label: Label = $Control/Panel/MarginContainer/VBox/DifficultyLabel
@onready var ore_types_label: Label = $Control/Panel/MarginContainer/VBox/OreTypesLabel
@onready var enter_button: Button = $Control/Panel/MarginContainer/VBox/ButtonsBox/EnterButton
@onready var cancel_button: Button = $Control/Panel/MarginContainer/VBox/ButtonsBox/CancelButton

var _current_node: MapNode = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enter_button.pressed.connect(_on_enter_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	hide()

func show_for_node(node: MapNode) -> void:
	_current_node = node
	title_label.text = node.location_name
	description_label.text = node.description if node.description != "" else _default_description(node)

	match node.node_type:
		MapNode.NodeType.STATION:
			type_label.text = "[ Colony ]"
			type_label.modulate = Color(0.4, 0.8, 1.0)
			difficulty_label.visible = false
			ore_types_label.visible = false
			enter_button.text = "Visit Colony"
		MapNode.NodeType.ASTEROID:
			type_label.text = "[ Mine ]"
			type_label.modulate = Color(1.0, 0.8, 0.3)
			difficulty_label.visible = true
			ore_types_label.visible = node.ore_types.size() > 0
			enter_button.text = "Begin Mining"
		_:
			type_label.text = "[ Unknown ]"
			type_label.modulate = Color(1.0, 1.0, 1.0)
			difficulty_label.visible = false
			ore_types_label.visible = false
			enter_button.text = "Enter Location"

	if difficulty_label.visible:
		var diff_str = ""
		for i in node.difficulty:
			diff_str += "⛏ "
		difficulty_label.text = "Difficulty:  " + diff_str.strip_edges()

	if ore_types_label.visible:
		ore_types_label.text = "Ores: " + ", ".join(PackedStringArray(node.ore_types))

	show()

func _default_description(node: MapNode) -> String:
	match node.node_type:
		MapNode.NodeType.STATION:
			return "Your home colony. Visit the shop to spend minerals on upgrades."
		MapNode.NodeType.ASTEROID:
			return "A promising mining site. Dig deep to uncover rare ores."
	return "An unexplored location."

func _on_enter_pressed() -> void:
	hide()
	confirmed.emit(_current_node)

func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
	elif event.is_action_pressed("ui_accept"):
		_on_enter_pressed()
