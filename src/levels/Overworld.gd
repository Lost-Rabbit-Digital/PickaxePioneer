class_name Overworld
extends Node2D

# Overworld Map

@onready var caravan: Caravan = $Caravan
@onready var city_node: MapNode = $CityNode
@onready var mine_node_1: MapNode = $MineNode1
@onready var mine_node_2: MapNode = $MineNode2
@onready var settlement_node_3: MapNode = $SettlementNode3
@onready var settlement_node_4: MapNode = $SettlementNode4

var current_node: MapNode
var nodes: Array[MapNode] = []
var _modal: LevelInfoModal = null

# Mine name options for randomization
var mine_names = [
	"Iron Mine",
	"Gold Mine",
	"Copper Mine",
	"Silver Mine",
	"Coal Mine",
	"Diamond Mine",
	"Platinum Mine",
	"Emerald Mine",
	"Ruby Mine",
	"Sapphire Mine",
	"Tin Mine",
	"Lead Mine",
	"Uranium Mine",
	"Crystal Cave",
	"Obsidian Pit"
]

# Difficulty, primary ore, and hazard info keyed by mine name.
# Ore names must match the game's actual tile types: Copper, Iron, Gold, Gem.
# Hazard names: "Explosives" (explosive tiles), "Lava" (lava tiles).
var mine_metadata: Dictionary = {
	"Iron Mine":     {"difficulty": 1, "ores": ["Iron", "Copper"],  "hazards": ["Explosives"]},
	"Gold Mine":     {"difficulty": 3, "ores": ["Gold", "Iron"],    "hazards": ["Explosives", "Lava"]},
	"Copper Mine":   {"difficulty": 1, "ores": ["Copper"],          "hazards": []},
	"Silver Mine":   {"difficulty": 2, "ores": ["Iron", "Copper"],  "hazards": ["Explosives"]},
	"Coal Mine":     {"difficulty": 1, "ores": ["Copper", "Iron"],  "hazards": ["Explosives"]},
	"Diamond Mine":  {"difficulty": 3, "ores": ["Gem", "Gold"],     "hazards": ["Explosives", "Lava"]},
	"Platinum Mine": {"difficulty": 3, "ores": ["Gold", "Gem"],     "hazards": ["Explosives", "Lava"]},
	"Emerald Mine":  {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Lava"]},
	"Ruby Mine":     {"difficulty": 2, "ores": ["Gem", "Copper"],   "hazards": ["Lava"]},
	"Sapphire Mine": {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Explosives"]},
	"Tin Mine":      {"difficulty": 1, "ores": ["Copper"],          "hazards": []},
	"Lead Mine":     {"difficulty": 1, "ores": ["Iron", "Copper"],  "hazards": []},
	"Uranium Mine":  {"difficulty": 3, "ores": ["Gem", "Gold"],     "hazards": ["Explosives", "Lava"]},
	"Crystal Cave":  {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Explosives"]},
	"Obsidian Pit":  {"difficulty": 3, "ores": ["Iron", "Gem"],     "hazards": ["Explosives", "Lava"]},
}

func _ready() -> void:
	# Start overworld music
	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)

	# Randomize mine nodes
	_randomize_mines()

	# Set static node metadata
	city_node.description = "Your home colony. Spend your hard-earned minerals on upgrades to improve your mining operation."
	settlement_node_3.description = "A small outpost along the mining route. Rest, resupply, and prepare for deeper delves."
	settlement_node_3.difficulty = 1
	settlement_node_3.ore_types = []
	settlement_node_3.hazard_types = []
	settlement_node_4.description = "A remote settlement near deeper deposits. Stock up before venturing into the lower zones."
	settlement_node_4.difficulty = 2
	settlement_node_4.ore_types = []
	settlement_node_4.hazard_types = []

	# Instantiate the level info modal
	_modal = preload("res://src/ui/LevelInfoModal.tscn").instantiate()
	add_child(_modal)
	_modal.confirmed.connect(_on_modal_confirmed)

	# Define connections - create a connected network
	_connect_nodes(city_node, mine_node_1)
	_connect_nodes(city_node, mine_node_2)
	_connect_nodes(mine_node_1, settlement_node_3)
	_connect_nodes(mine_node_2, settlement_node_4)
	_connect_nodes(settlement_node_3, settlement_node_4)

	# Collect all nodes
	nodes = [city_node, mine_node_1, mine_node_2, settlement_node_3, settlement_node_4]

	# Arrange nodes in a circular formation with random layout
	_arrange_nodes_in_circle()

	# Connect click signals
	for node in nodes:
		node.node_clicked.connect(_on_node_clicked)

	# Initialize position
	if GameManager.last_overworld_node_name != "":
		for node in nodes:
			if node.name == GameManager.last_overworld_node_name:
				current_node = node
				break

	if not current_node:
		current_node = city_node

	caravan.teleport_to(current_node.position)
	current_node.highlight(true)

	queue_redraw()

func _randomize_mines() -> void:
	# Randomly decide how many mines to show (1-2 mines)
	var mine_count = randi_range(1, 2)

	# Get random mine names
	var available_names = mine_names.duplicate()
	available_names.shuffle()

	# Apply randomization to both mines (positions set later in _arrange_nodes_in_circle)
	mine_node_1.location_name = available_names[0]
	_apply_mine_metadata(mine_node_1, available_names[0])
	mine_node_1._update_visuals()

	if mine_count >= 2:
		mine_node_2.location_name = available_names[1]
		_apply_mine_metadata(mine_node_2, available_names[1])
		mine_node_2._update_visuals()
		mine_node_2.visible = true
	else:
		# Hide second mine if only 1 mine is selected
		mine_node_2.visible = false

func _arrange_nodes_in_circle() -> void:
	var center := Vector2(640, 360)
	var radius := 240.0
	var jitter := deg_to_rad(20.0)
	var start_angle := randf() * TAU

	# Only position visible nodes so hidden mines don't take up a slot
	var visible_nodes: Array[MapNode] = []
	for node in nodes:
		if node.visible:
			visible_nodes.append(node)

	visible_nodes.shuffle()

	var base_step := TAU / visible_nodes.size()
	for i in range(visible_nodes.size()):
		var angle := start_angle + i * base_step + randf_range(-jitter, jitter)
		visible_nodes[i].position = center + Vector2(cos(angle), sin(angle)) * radius

func _apply_mine_metadata(node: MapNode, name: String) -> void:
	var meta: Dictionary = mine_metadata.get(name, {})
	node.difficulty = meta.get("difficulty", 1)
	node.ore_types = meta.get("ores", [])
	node.hazard_types = meta.get("hazards", [])

func _connect_nodes(node_a: MapNode, node_b: MapNode) -> void:
	if not node_a.neighbors.has(node_b):
		node_a.neighbors.append(node_b)
	if not node_b.neighbors.has(node_a):
		node_b.neighbors.append(node_a)

func _draw() -> void:
	# Draw dotted lines
	var visited_pairs = []
	for node in nodes:
		for neighbor in node.neighbors:
			var pair = [node, neighbor]
			pair.sort_custom(func(a, b): return a.name < b.name)
			if not visited_pairs.has(pair):
				visited_pairs.append(pair)
				draw_dashed_line(node.position, neighbor.position, Color(1, 1, 1, 0.5), 2.0, 10.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_enter_node(current_node)
		return

	var direction = Vector2.ZERO
	if event.is_action_pressed("ui_up"):
		direction = Vector2.UP
	elif event.is_action_pressed("ui_down"):
		direction = Vector2.DOWN
	elif event.is_action_pressed("ui_left"):
		direction = Vector2.LEFT
	elif event.is_action_pressed("ui_right"):
		direction = Vector2.RIGHT

	if direction != Vector2.ZERO:
		_move_selection(direction)

func _move_selection(direction: Vector2) -> void:
	var best_neighbor: MapNode = null
	var best_dot = -1.0

	for neighbor in current_node.neighbors:
		var dir_to_neighbor = current_node.position.direction_to(neighbor.position)
		var dot = dir_to_neighbor.dot(direction)

		if dot > 0.5 and dot > best_dot: # Must be roughly in the direction (45 degrees)
			best_dot = dot
			best_neighbor = neighbor

	if best_neighbor:
		current_node.highlight(false)
		current_node = best_neighbor
		current_node.highlight(true)
		caravan.move_to(current_node.position)

func _on_node_clicked(node: MapNode) -> void:
	if node != current_node:
		current_node.highlight(false)
		current_node = node
		current_node.highlight(true)
		caravan.move_to(node.position)
	# Always show the info panel immediately on click
	_enter_node(node)

func _enter_node(node: MapNode) -> void:
	_modal.show_for_node(node)

func _on_modal_confirmed(node: MapNode) -> void:
	GameManager.last_overworld_node_name = node.name
	GameManager.allowed_ore_types = node.ore_types.duplicate()
	GameManager.allowed_hazard_types = node.hazard_types.duplicate()

	if node.node_type == MapNode.NodeType.MINE or node.node_type == MapNode.NodeType.STATION:
		GameManager.load_mining_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.SETTLEMENT:
		GameManager.load_settlement_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.EMPTY:
		if node.name == "CityNode":
			GameManager.load_mining_level(node.scene_path)
