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
@onready var hazards_label: Label = $Control/Panel/MarginContainer/VBox/HazardsLabel
@onready var enter_button: Button = $Control/Panel/MarginContainer/VBox/ButtonsBox/EnterButton
@onready var hsep2: HSeparator = $Control/Panel/MarginContainer/VBox/HSep2

var _current_node: MapNode = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enter_button.pressed.connect(_on_enter_pressed)
	hide()

func show_for_node(node: MapNode) -> void:
	_current_node = node
	title_label.text = node.location_name
	description_label.text = node.description if node.description != "" else _default_description(node)

	match node.node_type:
		MapNode.NodeType.STATION:
			type_label.text = "[ Space Station ]"
			type_label.modulate = Color(0.4, 0.8, 1.0)
			difficulty_label.visible = false
			ore_types_label.visible = false
			hazards_label.visible = false
			hsep2.visible = true
			enter_button.text = "Dock at Station"
		MapNode.NodeType.MINE:
			type_label.text = "[ Asteroid Mine ]"
			type_label.modulate = Color(1.0, 0.8, 0.3)
			difficulty_label.visible = true
			ore_types_label.visible = node.ore_types.size() > 0
			hazards_label.visible = node.hazard_types.size() > 0
			hsep2.visible = true
			enter_button.text = "Launch"
		MapNode.NodeType.SETTLEMENT:
			type_label.text = "[ Outpost ]"
			type_label.modulate = Color(0.85, 0.60, 1.0)
			difficulty_label.visible = false
			ore_types_label.visible = false
			hazards_label.visible = false
			hsep2.visible = false
			enter_button.text = "Visit Outpost"
		_:
			type_label.text = "[ Unknown ]"
			type_label.modulate = Color(1.0, 1.0, 1.0)
			difficulty_label.visible = false
			ore_types_label.visible = false
			hazards_label.visible = false
			hsep2.visible = true
			enter_button.text = "Explore"

	if difficulty_label.visible:
		var diff_str = ""
		for i in node.difficulty:
			diff_str += "⛏ "
		difficulty_label.text = "Difficulty:  " + diff_str.strip_edges()

	if ore_types_label.visible:
		ore_types_label.text = "Ores: " + ", ".join(PackedStringArray(node.ore_types))

	if hazards_label.visible:
		hazards_label.text = "Hazards: " + ", ".join(PackedStringArray(node.hazard_types))

	show()

func _default_description(node: MapNode) -> String:
	match node.node_type:
		MapNode.NodeType.STATION:
			return "Your home Space Station. Visit the workshop to spend minerals on upgrades."
		MapNode.NodeType.MINE:
			return "A promising asteroid. Mine deep to uncover rare space ores."
		MapNode.NodeType.SETTLEMENT:
			return "A space outpost. Spend banked minerals on supplies for your next run."
	return "An unexplored sector."

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
