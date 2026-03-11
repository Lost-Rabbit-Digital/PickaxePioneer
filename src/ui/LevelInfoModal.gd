class_name LevelInfoModal
extends CanvasLayer

# Shown on the overworld before the player enters a node.
# Displays location name, type, description, and hazards.

signal confirmed(node: MapNode)
signal travel_confirmed(node: MapNode)
signal cancelled

@onready var title_label: Label = $Control/Panel/MarginContainer/VBox/TitleLabel
@onready var type_label: Label = $Control/Panel/MarginContainer/VBox/TypeLabel
@onready var planet_info_label: Label = $Control/Panel/MarginContainer/VBox/PlanetInfoLabel
@onready var description_label: Label = $Control/Panel/MarginContainer/VBox/DescriptionLabel
@onready var hazards_label: Label = $Control/Panel/MarginContainer/VBox/HazardsLabel
@onready var enter_button: Button = $Control/Panel/MarginContainer/VBox/ButtonsBox/EnterButton
@onready var hsep2: HSeparator = $Control/Panel/MarginContainer/VBox/HSep2

var _current_node: MapNode = null
var _travel_mode: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	enter_button.pressed.connect(_on_enter_pressed)
	hide()

func show_locked_message(node: MapNode) -> void:
	# Show a lock message for a node that cannot be accessed yet
	_travel_mode = false
	_current_node = null
	title_label.text = node.location_name + " [LOCKED]"
	type_label.text = "[ Progression Gate ]"
	type_label.modulate = Color(0.8, 0.6, 0.4)
	description_label.text = _get_lock_reason_text(node)
	hazards_label.visible = false
	hsep2.visible = true
	enter_button.text = "OK"
	enter_button.disabled = true
	planet_info_label.visible = false
	show()

func _get_lock_reason_text(node: MapNode) -> String:
	# Return helpful message explaining why the node is locked
	if node.node_type == MapNode.NodeType.SETTLEMENT:
		return "This settlement is only accessible after you've completed a mining run on one of the first-tier mining asteroids. Return to the Clowder and explore Mine Node 1, 2, or 3 to progress."
	# Assume it's the final node if it's locked and not a settlement
	return "The final mining challenge awaits, but only after you've proven yourself in the settlements. Complete a mining run on one of the frontier settlements to unlock this sector."

func show_for_node(node: MapNode, travel_mode: bool = false) -> void:
	_current_node = node
	_travel_mode = travel_mode
	title_label.text = node.location_name
	description_label.text = node.description if node.description != "" else _default_description(node)

	match node.node_type:
		MapNode.NodeType.STATION:
			type_label.text = "[ Space Station ]"
			type_label.modulate = Color(0.4, 0.8, 1.0)
			hazards_label.visible = false
			hsep2.visible = true
			enter_button.text = "Dock at Station"
			planet_info_label.visible = false
		MapNode.NodeType.MINE:
			type_label.text = "[ Asteroid Mine ]"
			type_label.modulate = Color(1.0, 0.8, 0.3)
			hazards_label.visible = node.hazard_types.size() > 0
			hsep2.visible = true
			enter_button.text = "Launch"
			var planet_info := node.get_planet_info()
			planet_info_label.text = "Biome: %s  ·  Temp: %s  ·  Size: %s" % [
				planet_info["biome"], planet_info["temperature"], planet_info["size"]
			]
			planet_info_label.visible = true
		MapNode.NodeType.SETTLEMENT:
			type_label.text = "[ Settlement ]"
			type_label.modulate = Color(0.85, 0.60, 1.0)
			hazards_label.visible = false
			hsep2.visible = false
			enter_button.text = "Visit Settlement"
			planet_info_label.visible = false
		_:
			type_label.text = "[ Unknown ]"
			type_label.modulate = Color(1.0, 1.0, 1.0)
			hazards_label.visible = false
			hsep2.visible = true
			enter_button.text = "Explore"
			planet_info_label.visible = false

	if hazards_label.visible:
		hazards_label.text = "Hazards: " + ", ".join(PackedStringArray(node.hazard_types))

	if _travel_mode:
		enter_button.text = "Travel"

	show()

func _default_description(node: MapNode) -> String:
	match node.node_type:
		MapNode.NodeType.STATION:
			return "Your home Space Station. Visit the workshop to spend minerals on upgrades."
		MapNode.NodeType.MINE:
			return "A promising asteroid. Mine deep to uncover rare space ores."
		MapNode.NodeType.SETTLEMENT:
			return "A space settlement. Spend banked minerals on supplies for your next run."
	return "An unexplored sector."

func _on_enter_pressed() -> void:
	hide()
	# Only emit confirmed if a node was actually selected (not a lock message)
	if _current_node != null:
		if _travel_mode:
			travel_confirmed.emit(_current_node)
		else:
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
