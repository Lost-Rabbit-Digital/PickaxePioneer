class_name Overworld
extends Control

# Star Chart Map

@onready var caravan: Caravan = $Caravan
@onready var city_node: MapNode = $CityNode
@onready var mine_node_1: MapNode = $MineNode1
@onready var mine_node_2: MapNode = $MineNode2
@onready var settlement_node_3: MapNode = $SettlementNode3
@onready var settlement_node_4: MapNode = $SettlementNode4
@onready var pause_menu = $PauseMenu

var current_node: MapNode
var nodes: Array[MapNode] = []
var _modal: LevelInfoModal = null
var _pending_node: MapNode = null

# Asteroid mine name options for randomization
var mine_names = [
	"Iron Asteroid",
	"Golden Nebula",
	"Copper Moon",
	"Silver Comet",
	"Carbon Asteroid",
	"Diamond Cluster",
	"Platinum Belt",
	"Emerald Nebula",
	"Ruby Sector",
	"Sapphire Void",
	"Tin Moon",
	"Lead Asteroid",
	"Uranium Nebula",
	"Crystal Cavern",
	"Obsidian Rift"
]

# Difficulty, primary ore, and hazard info keyed by mine name.
# Ore names must match the game's actual tile types: Copper, Iron, Gold, Gem.
# Hazard names: "Explosives" (space mines), "Lava" (plasma tiles).
var mine_metadata: Dictionary = {
	"Iron Asteroid":    {"difficulty": 1, "ores": ["Iron", "Copper"],  "hazards": ["Explosives"]},
	"Golden Nebula":    {"difficulty": 3, "ores": ["Gold", "Iron"],    "hazards": ["Explosives", "Lava"]},
	"Copper Moon":      {"difficulty": 1, "ores": ["Copper"],          "hazards": []},
	"Silver Comet":     {"difficulty": 2, "ores": ["Iron", "Copper"],  "hazards": ["Explosives"]},
	"Carbon Asteroid":  {"difficulty": 1, "ores": ["Copper", "Iron"],  "hazards": ["Explosives"]},
	"Diamond Cluster":  {"difficulty": 3, "ores": ["Gem", "Gold"],     "hazards": ["Explosives", "Lava"]},
	"Platinum Belt":    {"difficulty": 3, "ores": ["Gold", "Gem"],     "hazards": ["Explosives", "Lava"]},
	"Emerald Nebula":   {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Lava"]},
	"Ruby Sector":      {"difficulty": 2, "ores": ["Gem", "Copper"],   "hazards": ["Lava"]},
	"Sapphire Void":    {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Explosives"]},
	"Tin Moon":         {"difficulty": 1, "ores": ["Copper"],          "hazards": []},
	"Lead Asteroid":    {"difficulty": 1, "ores": ["Iron", "Copper"],  "hazards": []},
	"Uranium Nebula":   {"difficulty": 3, "ores": ["Gem", "Gold"],     "hazards": ["Explosives", "Lava"]},
	"Crystal Cavern":   {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Explosives"]},
	"Obsidian Rift":    {"difficulty": 3, "ores": ["Iron", "Gem"],     "hazards": ["Explosives", "Lava"]},
}

func _ready() -> void:
	# Restore or randomize mine nodes
	var saved_config := SaveManager.get_planet_config()
	if saved_config.size() > 0:
		_restore_mines(saved_config)
	else:
		_randomize_mines()

	# Set static node metadata
	city_node.description = "Your home Space Station. Spend your hard-earned minerals on upgrades to improve your space mining operation."
	settlement_node_3.description = "A small outpost along the space route. Rest, resupply, and prepare for deeper sectors."
	settlement_node_3.difficulty = 1
	settlement_node_3.ore_types = []
	settlement_node_3.hazard_types = []
	settlement_node_4.description = "A remote station near deeper sectors. Stock up before venturing into the outer zones."
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

	# Arrange nodes - restore saved positions or randomize fresh
	if saved_config.has("node_positions"):
		_restore_node_positions(saved_config["node_positions"])
	else:
		_arrange_nodes_in_circle()
		_save_node_positions()

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
	# Long-Range Scanner upgrade guarantees both mines are always visible.
	var mine_count = 2 if GameManager.long_scanner_built else randi_range(1, 2)

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

	# Persist planet config so it stays consistent until the player dies
	_save_planet_config()

func _restore_mines(config: Dictionary) -> void:
	# Restore mine configuration from a saved planet config
	var mine1_name: String = config.get("mine1_name", "")
	var mine2_name: String = config.get("mine2_name", "")
	var mine2_visible: bool = config.get("mine2_visible", true)

	if mine1_name != "":
		mine_node_1.location_name = mine1_name
		_apply_mine_metadata(mine_node_1, mine1_name)
		mine_node_1._update_visuals()

	if mine2_name != "":
		mine_node_2.location_name = mine2_name
		_apply_mine_metadata(mine_node_2, mine2_name)
		mine_node_2._update_visuals()
		mine_node_2.visible = mine2_visible
	else:
		mine_node_2.visible = false

func _save_planet_config() -> void:
	var config := {
		"mine1_name": mine_node_1.location_name,
		"mine2_name": mine_node_2.location_name if mine_node_2.visible else "",
		"mine2_visible": mine_node_2.visible,
	}
	SaveManager.save_planet_config(config)

func _arrange_nodes_in_circle() -> void:
	var center := Vector2(640, 360)
	var radius := 240.0
	var jitter := deg_to_rad(12.0)
	var start_angle := randf() * TAU

	# Use cycle order so connected nodes sit adjacent on the circle.
	# The graph forms a cycle: city -> mine1 -> settlement3 -> settlement4 -> mine2 -> city.
	# Placing nodes in this order means every edge is between neighbours on the
	# circle, producing a clean polygon instead of a pentagram.
	var ordered_nodes := _get_cycle_order()

	var base_step := TAU / ordered_nodes.size()
	for i in range(ordered_nodes.size()):
		var angle := start_angle + i * base_step + randf_range(-jitter, jitter)
		ordered_nodes[i].position = center + Vector2(cos(angle), sin(angle)) * radius

func _save_node_positions() -> void:
	var node_positions := {}
	for node in nodes:
		node_positions[node.name] = {"x": node.position.x, "y": node.position.y}
	var config := SaveManager.get_planet_config()
	config["node_positions"] = node_positions
	SaveManager.save_planet_config(config)

func _restore_node_positions(positions: Dictionary) -> void:
	for node in nodes:
		if positions.has(node.name):
			var pos_data = positions[node.name]
			node.position = Vector2(pos_data["x"], pos_data["y"])

func _get_cycle_order() -> Array[MapNode]:
	# Return visible nodes in the intended cycle order so edges stay on the
	# perimeter and never cross through the centre.
	var full_order: Array[MapNode] = [
		city_node, mine_node_1, settlement_node_3, settlement_node_4, mine_node_2
	]
	var result: Array[MapNode] = []
	for node in full_order:
		if node.visible:
			result.append(node)
	return result

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
	if event.is_action_pressed("ui_cancel"):
		if _modal and _modal.visible:
			return  # Let the modal handle its own dismissal
		pause_menu.show_menu()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		if not caravan.is_moving:
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
		if caravan.arrived.is_connected(_on_caravan_arrived):
			caravan.arrived.disconnect(_on_caravan_arrived)
		_modal.hide()
		current_node.highlight(false)
		current_node = best_neighbor
		current_node.highlight(true)
		_pending_node = best_neighbor
		caravan.arrived.connect(_on_caravan_arrived, CONNECT_ONE_SHOT)
		caravan.move_to(current_node.position)

func _on_node_clicked(node: MapNode) -> void:
	# Cancel any in-progress travel
	if caravan.arrived.is_connected(_on_caravan_arrived):
		caravan.arrived.disconnect(_on_caravan_arrived)

	if node == current_node:
		_enter_node(node)
		return

	# Hide the modal while the caravan is in transit
	_modal.hide()

	# Find shortest path through the graph so the caravan walks each segment
	var path := _find_path(current_node, node)

	current_node.highlight(false)
	current_node = node
	current_node.highlight(true)

	# Skip the first node (caravan is already there); collect waypoint positions
	var waypoints: Array[Vector2] = []
	for i in range(1, path.size()):
		waypoints.append(path[i].position)

	_pending_node = node
	caravan.arrived.connect(_on_caravan_arrived, CONNECT_ONE_SHOT)
	caravan.move_along_path(waypoints)

func _on_caravan_arrived() -> void:
	if _pending_node:
		_enter_node(_pending_node)
		_pending_node = null

func _find_path(from_node: MapNode, to_node: MapNode) -> Array[MapNode]:
	# BFS over visible, connected nodes to find the shortest path.
	if from_node == to_node:
		var direct: Array[MapNode] = [from_node]
		return direct

	var queue: Array = [[from_node]]
	var visited: Array[MapNode] = [from_node]

	while queue.size() > 0:
		var path: Array = queue.pop_front()
		var current: MapNode = path[-1]

		for neighbor in current.neighbors:
			if not neighbor.visible:
				continue
			if neighbor == to_node:
				path.append(neighbor)
				var result: Array[MapNode] = []
				result.assign(path)
				return result
			if not visited.has(neighbor):
				visited.append(neighbor)
				var new_path := path.duplicate()
				new_path.append(neighbor)
				queue.append(new_path)

	# Fallback: direct move if no path found
	var fallback: Array[MapNode] = [from_node, to_node]
	return fallback

func _enter_node(node: MapNode) -> void:
	_modal.show_for_node(node)

func _on_modal_confirmed(node: MapNode) -> void:
	GameManager.last_overworld_node_name = node.name
	GameManager.allowed_ore_types = node.ore_types.duplicate()
	GameManager.allowed_hazard_types = node.hazard_types.duplicate()
	GameManager.save_game()

	if node.node_type == MapNode.NodeType.MINE or node.node_type == MapNode.NodeType.STATION:
		GameManager.load_mining_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.SETTLEMENT:
		GameManager.load_settlement_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.EMPTY:
		if node.name == "CityNode":
			GameManager.load_mining_level(node.scene_path)
