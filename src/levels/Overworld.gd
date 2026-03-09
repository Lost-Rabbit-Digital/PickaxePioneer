class_name Overworld
extends Control

# Star Chart Map

@onready var caravan: Caravan = $Caravan
@onready var city_node: MapNode = $CityNode
@onready var mine_node_1: MapNode = $MineNode1
@onready var mine_node_2: MapNode = $MineNode2
@onready var mine_node_3: MapNode = $MineNode3
@onready var settlement_node_3: MapNode = $SettlementNode3
@onready var settlement_node_4: MapNode = $SettlementNode4
@onready var final_node: MapNode = $FinalNode
@onready var pause_menu = $PauseMenu
@onready var version_label: Label = $Camera2D/BackgroundCanvasLayer/VersionLabel
@onready var camera: Camera2D = $Camera2D

var current_node: MapNode
var nodes: Array[MapNode] = []
var _modal: LevelInfoModal = null
var _pending_node: MapNode = null

# Animated dashed lines
var _animation_time: float = 0.0
const _DASH_LENGTH: float = 10.0
const _GAP_LENGTH: float = 10.0
const _ANIMATION_SPEED: float = 80.0  # pixels per second

# Camera control
var _camera_zoom: float = 1.0
var _camera_pan_offset: Vector2 = Vector2.ZERO
var _camera_min_zoom: float = 0.5
var _camera_max_zoom: float = 3.0
var _camera_zoom_speed: float = 0.1
var _camera_follow_caravan: bool = true

# Mouse drag panning
var _is_dragging: bool = false
var _momentum_velocity: Vector2 = Vector2.ZERO
var _drag_velocity: Vector2 = Vector2.ZERO
var _mouse_delta_acc: Vector2 = Vector2.ZERO
const _MOMENTUM_DAMPING: float = 0.97
const _MOMENTUM_THRESHOLD: float = 0.5
const _DRAG_VEL_BLEND: float = 0.70

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
# Hazard names: "Explosives" (space mines), "Lava" (plasma tiles), "Bosses" (depth milestones).
var mine_metadata: Dictionary = {
	"Iron Asteroid":   {"difficulty": 1, "ores": ["Iron", "Copper"],  "hazards": ["Explosives", "Bosses"]},
	"Golden Nebula":   {"difficulty": 3, "ores": ["Gold", "Iron"],    "hazards": ["Explosives", "Lava", "Bosses"]},
	"Copper Moon":     {"difficulty": 1, "ores": ["Copper"],          "hazards": ["Bosses"]},
	"Silver Comet":    {"difficulty": 2, "ores": ["Iron", "Copper"],  "hazards": ["Explosives", "Bosses"]},
	"Carbon Asteroid": {"difficulty": 1, "ores": ["Copper", "Iron"],  "hazards": ["Explosives", "Bosses"]},
	"Diamond Cluster": {"difficulty": 3, "ores": ["Gem", "Gold"],     "hazards": ["Explosives", "Lava", "Bosses"]},
	"Platinum Belt":   {"difficulty": 3, "ores": ["Gold", "Gem"],     "hazards": ["Explosives", "Lava", "Bosses"]},
	"Emerald Nebula":  {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Lava", "Bosses"]},
	"Ruby Sector":     {"difficulty": 2, "ores": ["Gem", "Copper"],   "hazards": ["Lava", "Bosses"]},
	"Sapphire Void":   {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Explosives", "Bosses"]},
	"Tin Moon":        {"difficulty": 1, "ores": ["Copper"],          "hazards": ["Bosses"]},
	"Lead Asteroid":   {"difficulty": 1, "ores": ["Iron", "Copper"],  "hazards": ["Bosses"]},
	"Uranium Nebula":  {"difficulty": 3, "ores": ["Gem", "Gold"],     "hazards": ["Explosives", "Lava", "Bosses"]},
	"Crystal Cavern":  {"difficulty": 2, "ores": ["Gem", "Iron"],     "hazards": ["Explosives", "Bosses"]},
	"Obsidian Rift":   {"difficulty": 3, "ores": ["Iron", "Gem"],     "hazards": ["Explosives", "Lava", "Bosses"]},
}

func _ready() -> void:
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")

	# Collect all nodes first — needed before connection generation/restore
	# Note: mine_node_3 and settlement_node_4 are kept but hidden for backwards compatibility
	nodes = [city_node, mine_node_1, mine_node_2, settlement_node_3, final_node]

	# Restore or randomize mine nodes and their connections.
	# Re-generate if the save predates the neural-network layout (no mine3_name key).
	var saved_config := SaveManager.get_planet_config()
	if saved_config.size() > 0 and saved_config.has("mine3_name"):
		_restore_mines(saved_config)
		_restore_connections(saved_config)
	else:
		_randomize_mines()
		_generate_connections()

	# Set static node metadata
	city_node.description = "Your home Space Station. Spend your hard-earned minerals on upgrades to improve your space mining operation."
	settlement_node_3.description = "A frontier settlement connecting the outer mining sectors. Rest and resupply before pushing deeper."
	settlement_node_3.difficulty = 1
	settlement_node_3.ore_types = []
	settlement_node_3.hazard_types = []
	settlement_node_4.visible = false

	# Instantiate the level info modal
	_modal = preload("res://src/ui/LevelInfoModal.tscn").instantiate()
	add_child(_modal)
	_modal.confirmed.connect(_on_modal_confirmed)

	# Arrange nodes - restore saved positions or generate fresh neural network layout
	if saved_config.has("node_positions") and saved_config["node_positions"].has("MineNode3"):
		_restore_node_positions(saved_config["node_positions"])
		_save_node_positions()  # Persist sprite frames if missing from a legacy save
	else:
		_arrange_nodes_neural_network()
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
	caravan.set_map_node(current_node)
	current_node.highlight(true)

	# In co-op, show a banner reminding the guest they can only watch, then
	# request the host's star chart.  Pulling from _ready() guarantees the
	# Overworld node exists when the response arrives, eliminating the race
	# condition that occurred when the host pushed the config immediately after
	# sending rpc_start_game_as_guest (before the guest's scene was instantiated).
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		_show_coop_guest_banner()
		rpc_request_planet_config.rpc_id(1)

	# Host also pushes the chart when its own Overworld is ready and a guest is
	# already connected (normal lobby-start flow where both peers load together).
	if NetworkManager.is_multiplayer_session and NetworkManager.is_host and NetworkManager.guest_peer_id > 0:
		var config := SaveManager.get_planet_config()
		_add_ship_state_to_config(config)
		rpc_apply_planet_config.rpc_id(NetworkManager.guest_peer_id, config)

	if NetworkManager.is_multiplayer_session:
		add_child(preload("res://src/ui/ChatBox.tscn").instantiate())

	# Initialize camera
	camera.enabled = true
	camera.global_position = caravan.global_position
	_camera_zoom = 1.0
	_update_camera()

	# Pan camera to ship when movement starts
	caravan.movement_started.connect(_on_caravan_movement_started)

	queue_redraw()

## Guest → Host: request the current star chart config.  Called from the guest's
## _ready() once the Overworld scene is fully instantiated, ensuring the config
## RPC is never received before the node exists.
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_planet_config() -> void:
	if not NetworkManager.is_host:
		return
	var config := SaveManager.get_planet_config()
	_add_ship_state_to_config(config)
	rpc_apply_planet_config.rpc_id(NetworkManager.guest_peer_id, config)

## Append the caravan's current position and remaining waypoints to a config
## dict so the guest can reproduce the ship's location and in-flight movement.
func _add_ship_state_to_config(config: Dictionary) -> void:
	config["ship_node"] = current_node.name if current_node else ""
	config["ship_caravan_x"] = caravan.position.x
	config["ship_caravan_y"] = caravan.position.y
	var flat: Array = []
	for wp: Vector2 in caravan._waypoints_remaining:
		flat.append(wp.x)
		flat.append(wp.y)
	config["ship_waypoints"] = flat

## Host → Guest: mirror the host's star chart so the guest sees the same planet
## names, positions, connections, and sprite frames as the host.
## Clears whatever layout the guest's _ready() generated and rebuilds from the
## host's saved config.
@rpc("authority", "call_remote", "reliable")
func rpc_apply_planet_config(config: Dictionary) -> void:
	# Drop all neighbour edges built by _ready() before re-applying from config.
	for node in nodes:
		node.neighbors.clear()
	_restore_mines(config)
	_restore_connections(config)
	if config.has("node_positions"):
		_restore_node_positions(config["node_positions"])
	_apply_ship_state(config)
	queue_redraw()

## Position the caravan to match the host's ship state encoded in a config dict.
## Handles two cases: parked at a node, or in-flight along remaining waypoints.
func _apply_ship_state(config: Dictionary) -> void:
	var ship_node_name: String = config.get("ship_node", "")
	if ship_node_name.is_empty():
		return

	var node_lookup: Dictionary = {}
	for n in nodes:
		node_lookup[n.name] = n

	var dest_node: MapNode = node_lookup.get(ship_node_name, null)
	if not dest_node:
		return

	current_node.highlight(false)
	current_node = dest_node
	current_node.highlight(true)

	var waypoints_flat: Array = config.get("ship_waypoints", [])
	if waypoints_flat.size() >= 2:
		# Ship is in transit — place caravan at its exact physical position and
		# animate it along the remaining waypoints so the guest sees the journey.
		var start := Vector2(config.get("ship_caravan_x", 0.0), config.get("ship_caravan_y", 0.0))
		caravan.teleport_to(start)
		_pending_node = dest_node
		var waypoints: Array[Vector2] = []
		for i in range(0, waypoints_flat.size() - 1, 2):
			waypoints.append(Vector2(waypoints_flat[i], waypoints_flat[i + 1]))
		caravan.arrived.connect(func() -> void:
			caravan.set_map_node(current_node)
			_pending_node = null
		, CONNECT_ONE_SHOT)
		caravan.move_along_path(waypoints)
	else:
		# Ship is parked — snap caravan to the node position.
		caravan.teleport_to(dest_node.position)
		caravan.set_map_node(dest_node)

## Host → Guest: replicate a navigation move so the guest's caravan follows the
## same path in real time.  start_x/y is the caravan's physical pixel position
## at the moment the host initiated travel; waypoints_flat is the full ordered
## sequence of [x, y, x, y, …] positions the caravan will pass through;
## to_node_name is the destination MapNode (used to sync current_node/highlight).
@rpc("authority", "call_remote", "reliable")
func rpc_sync_ship_travel(start_x: float, start_y: float, waypoints_flat: Array, to_node_name: String) -> void:
	var node_lookup: Dictionary = {}
	for n in nodes:
		node_lookup[n.name] = n

	var dest_node: MapNode = node_lookup.get(to_node_name, null)
	if not dest_node:
		return

	# Clear any existing guest arrival callback so it doesn't fire mid-redirect.
	if caravan.arrived.is_connected(_on_caravan_arrived):
		caravan.arrived.disconnect(_on_caravan_arrived)

	current_node.highlight(false)
	current_node = dest_node
	current_node.highlight(true)
	_pending_node = dest_node

	caravan.teleport_to(Vector2(start_x, start_y))
	var waypoints: Array[Vector2] = []
	for i in range(0, waypoints_flat.size() - 1, 2):
		waypoints.append(Vector2(waypoints_flat[i], waypoints_flat[i + 1]))
	caravan.arrived.connect(func() -> void:
		caravan.set_map_node(current_node)
		_pending_node = null
	, CONNECT_ONE_SHOT)
	caravan.move_along_path(waypoints)

func _show_coop_guest_banner() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var lbl := Label.new()
	lbl.text = "CO-OP — Waiting for host to choose a destination..."
	lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	lbl.offset_top = -48.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	layer.add_child(lbl)

func _randomize_mines() -> void:
	# Two mine slots in the neural network layout.
	var available_names := mine_names.duplicate()
	available_names.shuffle()

	mine_node_1.location_name = available_names[0]
	_apply_mine_metadata(mine_node_1, available_names[0])
	mine_node_1._update_visuals()
	mine_node_1.visible = true

	mine_node_2.location_name = available_names[1]
	_apply_mine_metadata(mine_node_2, available_names[1])
	mine_node_2._update_visuals()
	mine_node_2.visible = true

	# Hide mine_node_3
	mine_node_3.visible = false

	# Final node picks a hard mine (difficulty 3) from the remaining pool.
	var hard_names := mine_names.filter(func(n: String) -> bool:
		return mine_metadata.get(n, {}).get("difficulty", 1) == 3 and \
			not [available_names[0], available_names[1]].has(n)
	)
	if hard_names.is_empty():
		hard_names = available_names.slice(2)
	hard_names.shuffle()
	var final_name: String = hard_names[0] if hard_names.size() > 0 else available_names[2]
	final_node.location_name = final_name
	_apply_mine_metadata(final_node, final_name)
	final_node._update_visuals()
	final_node.visible = true

	# Config is persisted by _generate_connections() after connections are built

func _restore_mines(config: Dictionary) -> void:
	# Restore mine configuration from a saved planet config
	var mine1_name: String = config.get("mine1_name", "")
	var mine2_name: String = config.get("mine2_name", "")
	var final_name: String = config.get("final_name", "")

	if mine1_name != "":
		mine_node_1.location_name = mine1_name
		_apply_mine_metadata(mine_node_1, mine1_name)
		mine_node_1._update_visuals()
	mine_node_1.visible = true

	if mine2_name != "":
		mine_node_2.location_name = mine2_name
		_apply_mine_metadata(mine_node_2, mine2_name)
		mine_node_2._update_visuals()
	mine_node_2.visible = true

	# Hide mine_node_3
	mine_node_3.visible = false

	if final_name != "":
		final_node.location_name = final_name
		_apply_mine_metadata(final_node, final_name)
		final_node._update_visuals()
	final_node.visible = true

func _save_planet_config() -> void:
	# Collect unique edges as [name_a, name_b] pairs so connections survive reloads.
	var connection_pairs: Array = []
	var seen_pairs: Array = []
	for node in nodes:
		for neighbor in node.neighbors:
			var pair: Array = [node.name, neighbor.name]
			pair.sort()
			if not seen_pairs.has(pair):
				seen_pairs.append(pair)
				connection_pairs.append(pair)

	var config := {
		"mine1_name": mine_node_1.location_name,
		"mine2_name": mine_node_2.location_name,
		"mine3_name": mine_node_3.location_name,
		"final_name": final_node.location_name,
		"connections": connection_pairs,
	}
	SaveManager.save_planet_config(config)

func _arrange_nodes_neural_network() -> void:
	# Neural network layout: four layers from left (city) to right (final mine).
	# Two mine planets in layer 2, one settlement in layer 3.
	# Each layer's nodes are centred vertically with a small random jitter so
	# repeated runs look slightly organic while preserving the layered structure.
	# Planets are spread far apart to encourage use of camera panning/zooming.
	var jx := 50.0  # horizontal jitter range (progression axis)
	var jy := 80.0  # vertical jitter range (spread axis)

	# Layer 1 — Base City (single node, centred vertically)
	city_node.position = Vector2(300, 600) + Vector2(randf_range(-jx * 0.5, jx * 0.5), randf_range(-jy * 0.5, jy * 0.5))

	# Layer 2 — two mine planets, spread across the height
	mine_node_1.position  = Vector2(1100, 300) + Vector2(randf_range(-jx, jx), randf_range(-jy, jy))
	mine_node_2.position  = Vector2(1100, 900) + Vector2(randf_range(-jx, jx), randf_range(-jy, jy))

	# Layer 3 — single settlement node (centred vertically)
	settlement_node_3.position = Vector2(1900, 600) + Vector2(randf_range(-jx, jx), randf_range(-jy, jy))
	settlement_node_4.position = Vector2(9999, 9999)  # Hide off-screen

	# Layer 4 — final mine (single node, centred vertically)
	final_node.position = Vector2(2700, 600) + Vector2(randf_range(-jx * 0.5, jx * 0.5), randf_range(-jy * 0.5, jy * 0.5))

func _save_node_positions() -> void:
	var node_positions := {}
	for node in nodes:
		node_positions[node.name] = {"x": node.position.x, "y": node.position.y, "sprite_frame": node.sprite.frame}
	var config := SaveManager.get_planet_config()
	config["node_positions"] = node_positions
	SaveManager.save_planet_config(config)

func _restore_node_positions(positions: Dictionary) -> void:
	for node in nodes:
		if positions.has(node.name):
			var pos_data = positions[node.name]
			node.position = Vector2(pos_data["x"], pos_data["y"])
			if pos_data.has("sprite_frame"):
				node.sprite.frame = pos_data["sprite_frame"]
				# Recalculate tint and scale to match this frame's planet size
				# category — _update_visuals() picked a random frame earlier, so
				# _base_scale may not yet reflect the saved planet's true size.
				node.refresh_visuals()

func _apply_mine_metadata(node: MapNode, name: String) -> void:
	var meta: Dictionary = mine_metadata.get(name, {})
	node.difficulty = meta.get("difficulty", 1)
	node.ore_types = meta.get("ores", [])
	node.hazard_types = meta.get("hazards", [])

func _generate_connections() -> void:
	# Neural network topology (left → right):
	#   Layer 1 → Layer 2: city connects to both mines
	_connect_nodes(city_node, mine_node_1)
	_connect_nodes(city_node, mine_node_2)

	#   Layer 2 → Layer 3: each mine connects to the settlement
	_connect_nodes(mine_node_1, settlement_node_3)
	_connect_nodes(mine_node_2, settlement_node_3)

	#   Layer 3 → Layer 4: settlement connects to the final mine
	_connect_nodes(settlement_node_3, final_node)

	_save_planet_config()

func _restore_connections(config: Dictionary) -> void:
	# Rebuild edges from a saved list of [node_name_a, node_name_b] pairs.
	# Falls back to fresh generation if the key is missing (legacy saves).
	var connection_pairs: Array = config.get("connections", [])
	if connection_pairs.is_empty():
		_generate_connections()
		return

	var node_lookup: Dictionary = {}
	for node in nodes:
		node_lookup[node.name] = node

	for pair in connection_pairs:
		if pair.size() == 2:
			var node_a: MapNode = node_lookup.get(pair[0])
			var node_b: MapNode = node_lookup.get(pair[1])
			if node_a and node_b:
				_connect_nodes(node_a, node_b)

func _connect_nodes(node_a: MapNode, node_b: MapNode) -> void:
	if not node_a.neighbors.has(node_b):
		node_a.neighbors.append(node_b)
	if not node_b.neighbors.has(node_a):
		node_b.neighbors.append(node_a)

func _draw() -> void:
	# Draw animated dotted lines between visible nodes only — hidden nodes (e.g. mine_node_2
	# when the Long-Range Scanner is inactive) must not produce orphan lines.
	var visited_pairs = []
	for node in nodes:
		if not node.visible:
			continue
		for neighbor in node.neighbors:
			if not neighbor.visible:
				continue
			var pair = [node, neighbor]
			pair.sort_custom(func(a, b): return a.name < b.name)
			if not visited_pairs.has(pair):
				visited_pairs.append(pair)
				_draw_animated_dashed_line(node.position, neighbor.position, Color(1, 1, 1, 0.5), 2.0)

func _draw_animated_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	# Draw an animated dashed line that moves toward the destination node.
	# The dashes travel from source to destination, continuously looping.

	var direction = to - from
	var distance = direction.length()

	if distance < 0.1:
		return

	var unit_dir = direction.normalized()
	var cycle_length = _DASH_LENGTH + _GAP_LENGTH
	var offset = fmod(_animation_time * _ANIMATION_SPEED, cycle_length)

	# Draw dashes along the line
	var current_distance = -offset
	while current_distance < distance:
		var dash_start = from + unit_dir * current_distance
		var dash_end = from + unit_dir * min(current_distance + _DASH_LENGTH, distance)

		# Only draw if the dash is visible on the line
		if current_distance + _DASH_LENGTH > 0:
			draw_line(dash_start, dash_end, color, width)

		current_distance += cycle_length

func _process(delta: float) -> void:
	# Update animation time for dashed lines
	_animation_time += delta

	if _camera_follow_caravan:
		camera.global_position = caravan.global_position + _camera_pan_offset
	_update_camera()

	# Handle momentum decay for mouse drag panning
	if _is_dragging:
		# Continuously estimate drag velocity so releasing feels natural
		if delta > 0.0:
			var instant := _mouse_delta_acc / delta
			_drag_velocity = _drag_velocity.lerp(instant, _DRAG_VEL_BLEND)
		_mouse_delta_acc = Vector2.ZERO
	elif _momentum_velocity.length_squared() > _MOMENTUM_THRESHOLD * _MOMENTUM_THRESHOLD:
		# Coast with throw momentum; damp it each frame (frame-rate independent)
		_camera_pan_offset += _momentum_velocity * delta
		_momentum_velocity *= pow(_MOMENTUM_DAMPING, delta * 60.0)

	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	# Handle mouse drag panning (right-click drag)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					_is_dragging = true
					_momentum_velocity = Vector2.ZERO
					_drag_velocity = Vector2.ZERO
					_mouse_delta_acc = Vector2.ZERO
					get_viewport().set_input_as_handled()
				else:
					_is_dragging = false
					# Transfer the drag velocity as throw momentum
					_momentum_velocity = _drag_velocity
					_drag_velocity = Vector2.ZERO
					_mouse_delta_acc = Vector2.ZERO
					get_viewport().set_input_as_handled()
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_camera_zoom = clamp(_camera_zoom + _camera_zoom_speed, _camera_min_zoom, _camera_max_zoom)
					_update_camera()
					get_viewport().set_input_as_handled()
				return
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_camera_zoom = clamp(_camera_zoom - _camera_zoom_speed, _camera_min_zoom, _camera_max_zoom)
					_update_camera()
					get_viewport().set_input_as_handled()
				return

	elif event is InputEventMouseMotion and _is_dragging:
		# Drag right → camera pans left. Divide by zoom so dragging feels
		# consistent across different zoom levels
		var world_delta: Vector2 = (event as InputEventMouseMotion).relative / _camera_zoom
		_camera_pan_offset -= world_delta
		_mouse_delta_acc -= world_delta
		get_viewport().set_input_as_handled()
		return

	# Handle space to toggle camera follow
	if event.is_action_pressed("ui_select"):  # Space bar
		_camera_follow_caravan = not _camera_follow_caravan
		_camera_pan_offset = Vector2.ZERO
		_momentum_velocity = Vector2.ZERO
		get_viewport().set_input_as_handled()
		return

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

	# Arrow keys for node selection when following caravan
	if _camera_follow_caravan:
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

		if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
			var flat: Array = []
			for wp: Vector2 in caravan._waypoints_remaining:
				flat.append(wp.x)
				flat.append(wp.y)
			rpc_sync_ship_travel.rpc_id(NetworkManager.guest_peer_id,
					caravan.position.x, caravan.position.y, flat, best_neighbor.name)

func _on_node_clicked(node: MapNode) -> void:
	# In co-op, only the host navigates the star chart; guest watches
	if NetworkManager.is_multiplayer_session and not NetworkManager.is_host:
		return

	# Check if node is locked due to progression gates
	if _is_node_locked(node):
		_show_lock_message(node)
		return

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

	if NetworkManager.is_multiplayer_session and NetworkManager.guest_peer_id > 0:
		var flat: Array = []
		for wp: Vector2 in caravan._waypoints_remaining:
			flat.append(wp.x)
			flat.append(wp.y)
		rpc_sync_ship_travel.rpc_id(NetworkManager.guest_peer_id,
				caravan.position.x, caravan.position.y, flat, node.name)

func _on_caravan_arrived() -> void:
	caravan.set_map_node(current_node)
	if _pending_node:
		_enter_node(_pending_node)
		_pending_node = null

func _on_caravan_movement_started() -> void:
	_camera_follow_caravan = true
	_camera_pan_offset = Vector2.ZERO
	_momentum_velocity = Vector2.ZERO

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

func _is_node_locked(node: MapNode) -> bool:
	# Check if a node is locked due to progression gates
	# Settlements are locked until player completes a tier-1 mine
	if node.node_type == MapNode.NodeType.SETTLEMENT:
		return not GameManager.has_completed_tier_1_mine

	# Final node is locked until player completes a tier-2 settlement
	if node == final_node:
		return not GameManager.has_completed_tier_2_settlement

	# All other nodes (City and Mines) are always accessible
	return false

func _show_lock_message(node: MapNode) -> void:
	# Show a lock message to the player
	_modal.show_locked_message(node)

func _enter_node(node: MapNode) -> void:
	_modal.show_for_node(node)

func _on_modal_confirmed(node: MapNode) -> void:
	GameManager.last_overworld_node_name = node.location_name
	GameManager.allowed_ore_types = node.ore_types.duplicate()
	GameManager.allowed_hazard_types = node.hazard_types.duplicate()
	GameManager.current_node_type = node.node_type
	if node.node_type == MapNode.NodeType.MINE:
		GameManager.sky_color = node.get_average_pixel_color()
	GameManager.save_game()

	if node.node_type == MapNode.NodeType.MINE or node.node_type == MapNode.NodeType.STATION:
		GameManager.load_mining_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.SETTLEMENT:
		GameManager.load_settlement_level(node.scene_path)
	elif node.node_type == MapNode.NodeType.EMPTY:
		if node.name == "CityNode":
			GameManager.load_mining_level(node.scene_path)

func _update_camera() -> void:
	camera.zoom = Vector2.ONE * _camera_zoom


func _on_center_button_pressed() -> void:
	_camera_follow_caravan = true
	_camera_pan_offset = Vector2.ZERO
	_momentum_velocity = Vector2.ZERO
