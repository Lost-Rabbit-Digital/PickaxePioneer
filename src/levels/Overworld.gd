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

func _ready() -> void:
	# Start overworld music
	var music = load("res://assets/overworld.mp3")
	MusicManager.play_music(music)

	# Randomize mine nodes
	_randomize_mines()

	# Define connections - create a connected network
	_connect_nodes(city_node, mine_node_1)
	_connect_nodes(city_node, mine_node_2)
	_connect_nodes(mine_node_1, settlement_node_3)
	_connect_nodes(mine_node_2, settlement_node_4)
	_connect_nodes(settlement_node_3, settlement_node_4)

	# Collect all nodes
	nodes = [city_node, mine_node_1, mine_node_2, settlement_node_3, settlement_node_4]

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

	# Randomize positions for mines
	var mine_positions = [
		Vector2(600, 200),
		Vector2(800, 500)
	]
	mine_positions.shuffle()

	# Apply randomization to both mines
	mine_node_1.location_name = available_names[0]
	mine_node_1.position = mine_positions[0]
	mine_node_1._update_visuals()

	if mine_count >= 2:
		mine_node_2.location_name = available_names[1]
		mine_node_2.position = mine_positions[1]
		mine_node_2._update_visuals()
		mine_node_2.visible = true
	else:
		# Hide second mine if only 1 mine is selected
		mine_node_2.visible = false

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
	elif not caravan.is_moving:
		# Already at the node and stopped, so enter
		_enter_node(node)

func _enter_node(node: MapNode) -> void:
	GameManager.last_overworld_node_name = node.name

	if node.node_type == MapNode.NodeType.ASTEROID or node.node_type == MapNode.NodeType.STATION:
		GameManager.load_mining_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.EMPTY: # City is usually NodeType.STATION or custom
		# Check if it's the city node specifically by name or type
		if node.name == "CityNode":
			GameManager.load_mining_level(node.scene_path) # CityLevel is loaded via same mechanism
