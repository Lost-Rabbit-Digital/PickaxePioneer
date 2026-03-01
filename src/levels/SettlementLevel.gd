class_name SettlementLevel
extends Node2D

# Space Settlement — a walkable tile-based settlement world.
# Players explore, interact with wandering NPCs and the supply dock,
# and exit via the caravan ship on the left side of the map.
# Mining is NOT allowed in settlements.

const GRID_COLS: int = 64
const GRID_ROWS: int = 24
const CELL_SIZE: int = 64
const VIEWPORT_W: int = 1280
const VIEWPORT_H: int = 720

const SURFACE_ROWS: int = 8  # Sky area (rows 0..7)
const GROUND_ROW: int = SURFACE_ROWS  # First ground row

# Tile types used in the settlement world
enum Tile {
	EMPTY       = 0,
	GROUND      = 1,  # Walkable ground surface
	GROUND_DEEP = 2,  # Underground filler
	BUILDING    = 3,  # Building blocks (solid, varied textures)
	SUPPLY_DOCK = 4,  # The supply dock shop building
	CARAVAN     = 5,  # Caravan exit zone (left side)
}

# Textures for building blocks — NPCs use these same textures
const BUILDING_TEXTURES: Array = [
	"res://assets/blocks/cobblestone_bricks.png",
	"res://assets/blocks/beech_planks.png",
	"res://assets/blocks/oak_planks.png",
	"res://assets/blocks/pine_planks.png",
	"res://assets/blocks/limestone_bricks.png",
	"res://assets/blocks/sandstone_bricks.png",
	"res://assets/blocks/marble_bricks.png",
]

const GROUND_TEXTURE_PATH: String = "res://assets/blocks/grass_side.png"
const GROUND_DEEP_TEXTURE_PATH: String = "res://assets/blocks/dirt.png"
const SUPPLY_DOCK_TEXTURE_PATH: String = "res://assets/blocks/cobblestone_bricks_mossy.png"

# Consumable shop costs (same as before)
const COST_ENERGY_CACHE: int  = 20
const COST_RATIONS: int       = 25
const COST_SHROOM: int        = 35
const COST_SHARPENING: int    = 30

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var grid: Array = []
var _location_name: String = "Settlement"
var _game_over: bool = false
var _hub_visible: bool = false           # Compatibility with PlayerProbe checks
var _energy_shop_visible: bool = false
var _trader_shop_visible: bool = false
var _shop_visible: bool = false          # Settlement supply dock shop

var _exit_pulse_time: float = 0.0
var _building_data: Array = []  # Stores placed building info for drawing
var _npc_nodes: Array = []      # Wandering NPC Node2D references

# Textures
var _ground_tex: Texture2D
var _ground_deep_tex: Texture2D
var _supply_dock_tex: Texture2D
var _building_textures_loaded: Array = []  # Loaded Texture2D objects
var _caravan_tex: Texture2D

# Camera
var camera: Camera2D

# Collision
var collision_tilemap: TileMapLayer
var _tileset: TileSet

# UI
var _shop_layer: CanvasLayer
var _minerals_label: Label
var _status_label: Label
var _btn_energy: Button
var _btn_rations: Button
var _btn_shroom: Button
var _btn_sharpen: Button

# Supply dock position (grid coords of the door / interaction tile)
var _supply_dock_col: int = -1
var _supply_dock_row: int = -1

@onready var player_node := $PlayerProbe as PlayerProbe
@onready var pause_menu = $PauseMenu
@onready var _hud := $HUD as HUD

func _ready() -> void:
	texture_filter = TEXTURE_FILTER_NEAREST

	if GameManager.last_overworld_node_name != "":
		_location_name = GameManager.last_overworld_node_name.replace("Node", "").replace("3", " (North)").replace("4", " (South)")

	_load_textures()
	_generate_grid()
	_place_buildings()
	_setup_collision_tilemap()
	_sync_collision_tilemap()
	_setup_map_barriers()

	# Camera
	camera = Camera2D.new()
	add_child(camera)
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = GRID_COLS * CELL_SIZE
	camera.limit_bottom = GRID_ROWS * CELL_SIZE

	# Spawn player near the caravan (left side) on the ground
	if not player_node:
		push_error("SettlementLevel: PlayerProbe node not found — cannot spawn player.")
		return
	var spawn_col := 4
	var spawn_row := GROUND_ROW - 1
	player_node.global_position = Vector2(
		spawn_col * CELL_SIZE + CELL_SIZE * 0.5,
		spawn_row * CELL_SIZE + CELL_SIZE * 0.5
	)
	player_node.mining_level = self

	_spawn_npcs()
	_setup_supply_dock_shop()
	_hud.set_hotbar_visible(false)
	queue_redraw()

# ---------------------------------------------------------------------------
# Textures
# ---------------------------------------------------------------------------

func _load_textures() -> void:
	_ground_tex = load(GROUND_TEXTURE_PATH) as Texture2D
	_ground_deep_tex = load(GROUND_DEEP_TEXTURE_PATH) as Texture2D
	_supply_dock_tex = load(SUPPLY_DOCK_TEXTURE_PATH) as Texture2D
	_caravan_tex = load("res://assets/spaceship.png") as Texture2D
	for path in BUILDING_TEXTURES:
		var tex := load(path) as Texture2D
		if tex:
			_building_textures_loaded.append(tex)

# ---------------------------------------------------------------------------
# Grid generation
# ---------------------------------------------------------------------------

func _generate_grid() -> void:
	grid = []
	for col in range(GRID_COLS):
		var column: Array = []
		for row in range(GRID_ROWS):
			if row < GROUND_ROW:
				column.append(Tile.EMPTY)
			elif row == GROUND_ROW:
				column.append(Tile.GROUND)
			else:
				column.append(Tile.GROUND_DEEP)
		grid.append(column)

	# Caravan exit zone: left edge columns 0-1 at surface level
	for col in range(2):
		grid[col][GROUND_ROW - 1] = Tile.CARAVAN
		grid[col][GROUND_ROW - 2] = Tile.CARAVAN

func _place_buildings() -> void:
	var num_buildings := randi_range(4, 6)
	var placed_ranges: Array = []  # Track x-ranges to prevent overlap

	# Reserve space for caravan (cols 0-3) and supply dock (placed first)
	placed_ranges.append(Vector2i(0, 5))

	# Place supply dock building first (always present)
	var dock_col := randi_range(28, 36)
	var dock_w := 4
	var dock_h := 3
	_place_building_at(dock_col, dock_w, dock_h, true)
	placed_ranges.append(Vector2i(dock_col - 1, dock_col + dock_w + 1))

	# Place random buildings
	var attempts := 0
	var placed := 0
	while placed < num_buildings and attempts < 50:
		attempts += 1
		var bw := randi_range(3, 5)
		var bh := randi_range(2, 3)
		var bcol := randi_range(8, GRID_COLS - bw - 2)

		# Check overlap with existing buildings
		var overlap := false
		for r in placed_ranges:
			if bcol < r.y + 2 and bcol + bw > r.x - 2:
				overlap = true
				break
		if overlap:
			continue

		_place_building_at(bcol, bw, bh, false)
		placed_ranges.append(Vector2i(bcol - 1, bcol + bw + 1))
		placed += 1

func _place_building_at(col: int, w: int, h: int, is_supply_dock: bool) -> void:
	var tex_idx := randi() % _building_textures_loaded.size()
	var tile_type: int = Tile.SUPPLY_DOCK if is_supply_dock else Tile.BUILDING

	# Building sits on top of ground — occupies rows (GROUND_ROW - h) to (GROUND_ROW - 1)
	for dc in range(w):
		for dr in range(h):
			var gc := col + dc
			var gr := GROUND_ROW - h + dr
			if gc >= 0 and gc < GRID_COLS and gr >= 0 and gr < GRID_ROWS:
				grid[gc][gr] = tile_type

	# Store building data for rendering
	_building_data.append({
		"col": col, "w": w, "h": h,
		"tex_idx": tex_idx,
		"is_supply_dock": is_supply_dock,
	})

	if is_supply_dock:
		# Interaction point: bottom-center of building
		_supply_dock_col = col + w / 2
		_supply_dock_row = GROUND_ROW - 1

		# Clear the door tile so player can walk into it
		grid[_supply_dock_col][GROUND_ROW - 1] = Tile.EMPTY

# ---------------------------------------------------------------------------
# NPC spawning
# ---------------------------------------------------------------------------

func _spawn_npcs() -> void:
	var num_npcs := randi_range(4, 12)
	var npc_scene := load("res://src/entities/npcs/FarmAnimalNPC.tscn") as PackedScene
	if not npc_scene:
		return

	for i in range(num_npcs):
		var npc := npc_scene.instantiate() as FarmAnimalNPC
		npc.animal_name = "Settlement Resident"

		# Use a building texture for the NPC sprite (same as buildings)
		var tex_idx := randi() % _building_textures_loaded.size()
		var tex: Texture2D = _building_textures_loaded[tex_idx]
		var spr := npc.get_node("Sprite2D") as Sprite2D
		if spr and tex:
			spr.texture = tex
			spr.hframes = 1  # Single-frame texture (block texture)
			spr.frame = 0

		npc.scale = Vector2(2.0, 2.0)

		# Spawn on the ground surface row, spread across the map
		var spawn_x := randf_range(6.0 * CELL_SIZE, (GRID_COLS - 3.0) * CELL_SIZE)
		npc.position = Vector2(spawn_x, (GROUND_ROW - 1) * CELL_SIZE + CELL_SIZE * 0.5)

		# Wander bounds
		npc.bounce_left = 5.0 * CELL_SIZE
		npc.bounce_right = float(GRID_COLS - 3) * CELL_SIZE

		var speed := randf_range(30.0, 60.0)
		npc.velocity = Vector2(speed * (1.0 if randf() > 0.5 else -1.0), 0.0)

		add_child(npc)
		_npc_nodes.append(npc)

# ---------------------------------------------------------------------------
# Collision
# ---------------------------------------------------------------------------

func _setup_collision_tilemap() -> void:
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(CELL_SIZE, CELL_SIZE)
	_tileset.add_physics_layer()
	_tileset.set_physics_layer_collision_layer(0, 1)
	_tileset.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	var placeholder_img := Image.create(CELL_SIZE, CELL_SIZE, false, Image.FORMAT_RGBA8)
	placeholder_img.fill(Color(0, 0, 0, 0))
	var placeholder_tex := ImageTexture.create_from_image(placeholder_img)
	source.texture = placeholder_tex
	source.texture_region_size = Vector2i(CELL_SIZE, CELL_SIZE)
	_tileset.add_source(source, 0)
	source.create_tile(Vector2i(0, 0))

	var tile_data: TileData = source.get_tile_data(Vector2i(0, 0), 0)
	var half := CELL_SIZE / 2.0
	var collision_polygon := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half),
		Vector2(half, half), Vector2(-half, half)
	])
	tile_data.add_collision_polygon(0)
	tile_data.set_collision_polygon_points(0, 0, collision_polygon)

	collision_tilemap = TileMapLayer.new()
	collision_tilemap.tile_set = _tileset
	collision_tilemap.collision_enabled = true
	collision_tilemap.visible = false
	add_child(collision_tilemap)

func _sync_collision_tilemap() -> void:
	collision_tilemap.clear()
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var tile: int = grid[col][row]
			if tile == Tile.GROUND or tile == Tile.GROUND_DEEP:
				collision_tilemap.set_cell(Vector2i(col, row), 0, Vector2i(0, 0))

func _setup_map_barriers() -> void:
	var map_height := GRID_ROWS * CELL_SIZE
	var map_width := GRID_COLS * CELL_SIZE
	var barrier_thickness := CELL_SIZE

	for side in ["left", "right"]:
		var barrier := StaticBody2D.new()
		barrier.collision_layer = 1
		barrier.collision_mask = 0
		var shape_node := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(barrier_thickness, map_height)
		shape_node.shape = rect
		if side == "left":
			shape_node.position = Vector2(-barrier_thickness * 0.5, map_height * 0.5)
		else:
			shape_node.position = Vector2(map_width + barrier_thickness * 0.5, map_height * 0.5)
		barrier.add_child(shape_node)
		add_child(barrier)

	# Bottom barrier
	var bottom_barrier := StaticBody2D.new()
	bottom_barrier.collision_layer = 1
	bottom_barrier.collision_mask = 0
	var bottom_shape := CollisionShape2D.new()
	var bottom_rect := RectangleShape2D.new()
	bottom_rect.size = Vector2(map_width, barrier_thickness)
	bottom_shape.shape = bottom_rect
	bottom_shape.position = Vector2(map_width * 0.5, map_height + barrier_thickness * 0.5)
	bottom_barrier.add_child(bottom_shape)
	add_child(bottom_barrier)

# ---------------------------------------------------------------------------
# PlayerProbe compatibility — these properties/methods are accessed by
# PlayerProbe._physics_process and related code
# ---------------------------------------------------------------------------

func any_ui_open() -> bool:
	return _shop_visible

func try_mine_at(_grid_pos: Vector2i) -> void:
	# Mining is disabled in settlements — do nothing
	pass

func check_player_hazard(_col: int, _row: int) -> void:
	# No hazards in settlements
	pass

# ---------------------------------------------------------------------------
# Game loop
# ---------------------------------------------------------------------------

func _process(delta: float) -> void:
	_exit_pulse_time += delta
	queue_redraw()

	if _shop_visible or _game_over:
		return

	_update_camera()
	_update_interact_prompt()
	_check_caravan_exit()

func _update_camera() -> void:
	if not camera or not player_node:
		return
	camera.position = player_node.global_position

func _check_caravan_exit() -> void:
	if not player_node or _game_over:
		return
	var player_col := floori(player_node.global_position.x / CELL_SIZE)
	var player_row := floori(player_node.global_position.y / CELL_SIZE)
	if player_col <= 1 and player_row < GROUND_ROW:
		_game_over = true
		_return_to_overworld()

func _return_to_overworld() -> void:
	GameManager.load_overworld()

# ---------------------------------------------------------------------------
# Interact prompt
# ---------------------------------------------------------------------------

func _get_interact_key_name() -> String:
	var events := InputMap.action_get_events("interact")
	for event in events:
		if event is InputEventKey:
			return OS.get_keycode_string(event.keycode)
	return "E"

func _update_interact_prompt() -> void:
	if not player_node:
		return

	# Check proximity to supply dock
	if _supply_dock_col >= 0:
		var player_gp := player_node.get_grid_pos()
		var dist := Vector2(player_gp - Vector2i(_supply_dock_col, _supply_dock_row)).length()
		if dist <= 2.0:
			var key_name := _get_interact_key_name()
			player_node.show_prompt("Press %s to open Supply Dock" % key_name)
			var world_pos := Vector2(_supply_dock_col * CELL_SIZE + CELL_SIZE * 0.5, (_supply_dock_row - 1) * CELL_SIZE)
			var screen_pos := get_viewport().get_canvas_transform() * world_pos
			player_node.set_prompt_position(screen_pos)
			return

	# Check proximity to caravan (exit)
	var player_col := floori(player_node.global_position.x / CELL_SIZE)
	if player_col <= 3:
		var key_name := _get_interact_key_name()
		player_node.show_prompt("Walk left to return to Star Chart")
		var world_pos := Vector2(1.0 * CELL_SIZE, (GROUND_ROW - 2) * CELL_SIZE)
		var screen_pos := get_viewport().get_canvas_transform() * world_pos
		player_node.set_prompt_position(screen_pos)
		return

	# Check proximity to NPCs
	var nearby_npc := _get_nearby_npc()
	if nearby_npc:
		var key_name := _get_interact_key_name()
		player_node.show_prompt("Press %s to talk" % key_name)
		var world_pos := player_node.global_position + Vector2(0, -CELL_SIZE)
		var screen_pos := get_viewport().get_canvas_transform() * world_pos
		player_node.set_prompt_position(screen_pos)
	else:
		player_node.hide_prompt()

func _get_nearby_npc() -> FarmAnimalNPC:
	if not player_node:
		return null
	var player_pos := player_node.global_position
	for npc in _npc_nodes:
		if is_instance_valid(npc) and npc.global_position.distance_to(player_pos) <= CELL_SIZE * 2:
			return npc
	return null

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _shop_visible:
		if event.is_action_pressed("ui_cancel"):
			_close_shop()
		return

	if _game_over:
		return

	if event.is_action_pressed("ui_cancel"):
		pause_menu.show_menu()
		return

	if event.is_action_pressed("interact"):
		_try_interact()
		return

func _try_interact() -> void:
	if not player_node:
		return

	# Supply dock interaction
	if _supply_dock_col >= 0:
		var player_gp := player_node.get_grid_pos()
		var dist := Vector2(player_gp - Vector2i(_supply_dock_col, _supply_dock_row)).length()
		if dist <= 2.0:
			_show_shop()
			return

	# NPC interaction
	var nearby_npc := _get_nearby_npc()
	if nearby_npc:
		nearby_npc.wiggle()
		var messages := [
			"Welcome to the settlement, space cat!",
			"Stock up before your next mining run.",
			"I heard there's rare ore in the deeper sectors...",
			"The supply dock has everything you need.",
			"Be careful out there in the asteroid fields.",
			"Another miner? Good luck out there!",
			"The plasma in the deeper zones is no joke.",
			"I once found a Quantum Cat fossil. True story.",
			"That pickaxe looks like it could use sharpening.",
			"Got any Star Gold? I'll trade you for... oh wait, I'm broke.",
		]
		EventBus.ore_mined_popup.emit(0, messages[randi() % messages.size()])

# ---------------------------------------------------------------------------
# Rendering
# ---------------------------------------------------------------------------

func _draw() -> void:
	var cam_x: float
	var cam_y: float
	if camera:
		cam_x = clamp(camera.position.x, VIEWPORT_W * 0.5, GRID_COLS * CELL_SIZE - VIEWPORT_W * 0.5)
		cam_y = clamp(camera.position.y, VIEWPORT_H * 0.5, GRID_ROWS * CELL_SIZE - VIEWPORT_H * 0.5)
	else:
		cam_x = VIEWPORT_W * 0.5
		cam_y = VIEWPORT_H * 0.5

	var half_w: float = float(VIEWPORT_W) * 0.5 + float(CELL_SIZE)
	var half_h: float = float(VIEWPORT_H) * 0.5 + float(CELL_SIZE)

	var min_col: int = maxi(0, int((cam_x - half_w) / float(CELL_SIZE)))
	var max_col: int = mini(GRID_COLS - 1, int((cam_x + half_w) / float(CELL_SIZE)))
	var min_row: int = maxi(0, int((cam_y - half_h) / float(CELL_SIZE)))
	var max_row: int = mini(GRID_ROWS - 1, int((cam_y + half_h) / float(CELL_SIZE)))

	# Sky background
	if min_row < GROUND_ROW:
		var sky_top := min_row * CELL_SIZE
		var sky_bottom := mini(GROUND_ROW, max_row + 1) * CELL_SIZE
		var bg_left := min_col * CELL_SIZE
		var bg_width := (max_col - min_col + 1) * CELL_SIZE
		# Dark space background with subtle stars feel
		draw_rect(Rect2(bg_left, sky_top, bg_width, sky_bottom - sky_top), Color(0.04, 0.03, 0.08))

	# Underground background
	if max_row >= GROUND_ROW:
		var dirt_top := maxi(min_row, GROUND_ROW) * CELL_SIZE
		var dirt_bottom := (max_row + 1) * CELL_SIZE
		var bg_left := min_col * CELL_SIZE
		var bg_width := (max_col - min_col + 1) * CELL_SIZE
		draw_rect(Rect2(bg_left, dirt_top, bg_width, dirt_bottom - dirt_top), Color(0.08, 0.06, 0.04))

	# Draw tiles
	for col in range(min_col, max_col + 1):
		for row in range(min_row, max_row + 1):
			var tile: int = grid[col][row]
			if tile == Tile.EMPTY:
				continue

			var tile_rect := Rect2(col * CELL_SIZE, row * CELL_SIZE, CELL_SIZE, CELL_SIZE)

			match tile:
				Tile.GROUND:
					if _ground_tex:
						draw_texture_rect(_ground_tex, tile_rect, false)
					else:
						draw_rect(tile_rect, Color(0.25, 0.50, 0.20))

				Tile.GROUND_DEEP:
					if _ground_deep_tex:
						draw_texture_rect(_ground_deep_tex, tile_rect, false)
					else:
						draw_rect(tile_rect, Color(0.30, 0.22, 0.15))

				Tile.BUILDING:
					# Look up the building texture index for this position
					var btex := _get_building_texture_at(col, row)
					if btex:
						draw_texture_rect(btex, tile_rect, false)
					else:
						draw_rect(tile_rect, Color(0.45, 0.40, 0.35))

				Tile.SUPPLY_DOCK:
					if _supply_dock_tex:
						draw_texture_rect(_supply_dock_tex, tile_rect, false)
					else:
						draw_rect(tile_rect, Color(0.35, 0.50, 0.35))
					# Highlight border
					draw_rect(Rect2(col * CELL_SIZE + 2, row * CELL_SIZE + 2,
						CELL_SIZE - 4, CELL_SIZE - 4), Color(0.20, 0.80, 0.60), false, 2.0)

				Tile.CARAVAN:
					# Draw caravan area with pulsing effect
					pass

	# Draw caravan ship sprite on the left
	_draw_caravan_ship()

	# Draw supply dock label
	if _supply_dock_col >= 0:
		var font := ThemeDB.fallback_font
		var label_x := _supply_dock_col * CELL_SIZE - 40
		var label_y := (_supply_dock_row - 3) * CELL_SIZE + CELL_SIZE * 0.5
		draw_string(font, Vector2(label_x, label_y), "SUPPLY DOCK",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.20, 0.90, 0.60))

	# Draw settlement name banner at top
	var font := ThemeDB.fallback_font
	var banner_x := cam_x - 100.0
	var banner_y := (min_row + 1) * CELL_SIZE + 20.0
	draw_string(font, Vector2(banner_x, banner_y), _location_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.85, 0.70, 1.0, 0.8))

func _draw_caravan_ship() -> void:
	# Pulsing caravan exit indicator on left side
	var pulse: float = sin(_exit_pulse_time * 2.5) * 0.5 + 0.5

	# Draw the spaceship sprite
	if _caravan_tex:
		var ship_x := 0.5 * CELL_SIZE
		var ship_y := (GROUND_ROW - 2) * CELL_SIZE
		var ship_size := CELL_SIZE * 2.0
		var ship_rect := Rect2(ship_x - ship_size * 0.5, ship_y - ship_size * 0.25, ship_size, ship_size)
		draw_texture_rect(_caravan_tex, ship_rect, false)

	# Pulsing "EXIT" label
	var exit_x := 0.5 * CELL_SIZE - 12
	var exit_y := (GROUND_ROW - 3) * CELL_SIZE + CELL_SIZE * 0.5
	var font := ThemeDB.fallback_font
	var exit_color := Color(0.30 + pulse * 0.50, 1.0, 0.30 + pulse * 0.30)
	draw_string(font, Vector2(exit_x, exit_y), "EXIT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, exit_color)

	# Pulsing glow around exit zone
	var glow_alpha := 0.15 + pulse * 0.25
	var glow_rect := Rect2(0, (GROUND_ROW - 3) * CELL_SIZE, 2 * CELL_SIZE, 3 * CELL_SIZE)
	draw_rect(glow_rect, Color(0.20, 0.90, 0.30, glow_alpha), false, 3.0)

func _get_building_texture_at(col: int, row: int) -> Texture2D:
	for bd in _building_data:
		if col >= bd["col"] and col < bd["col"] + bd["w"]:
			if row >= GROUND_ROW - bd["h"] and row < GROUND_ROW:
				var idx: int = bd["tex_idx"]
				if idx >= 0 and idx < _building_textures_loaded.size():
					return _building_textures_loaded[idx]
	return null

# ---------------------------------------------------------------------------
# Supply Dock Shop UI
# ---------------------------------------------------------------------------

func _setup_supply_dock_shop() -> void:
	const PANEL_W: int = 520
	const PANEL_H: int = 460
	const VW: int = 1280
	const VH: int = 720
	var px := (VW - PANEL_W) / 2
	var py := (VH - PANEL_H) / 2

	_shop_layer = CanvasLayer.new()
	_shop_layer.layer = 10
	_shop_layer.visible = false
	add_child(_shop_layer)

	# Dim overlay
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.0, 0.0, 0.0, 0.70)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_layer.add_child(dim)

	# Panel border
	var border := ColorRect.new()
	border.position = Vector2(px - 3, py - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.60, 0.45, 0.20, 1.0)
	_shop_layer.add_child(border)

	# Panel body
	var panel := ColorRect.new()
	panel.position = Vector2(px, py)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.09, 0.08, 0.06, 0.97)
	_shop_layer.add_child(panel)

	# Title
	var title := Label.new()
	title.text = "Space Settlement — Supply Dock"
	title.position = Vector2(px, py + 12)
	title.size = Vector2(PANEL_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.80, 0.35)
	_shop_layer.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "A small space settlement where cat miners recharge and resupply."
	subtitle.position = Vector2(px, py + 46)
	subtitle.size = Vector2(PANEL_W, 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.70, 0.65, 0.55)
	_shop_layer.add_child(subtitle)

	# Minerals display
	_minerals_label = Label.new()
	_minerals_label.position = Vector2(px, py + 72)
	_minerals_label.size = Vector2(PANEL_W, 26)
	_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minerals_label.modulate = Color(1.0, 0.85, 0.20)
	_shop_layer.add_child(_minerals_label)

	# Divider
	var div := ColorRect.new()
	div.position = Vector2(px + 20, py + 104)
	div.size = Vector2(PANEL_W - 40, 2)
	div.color = Color(0.60, 0.45, 0.20, 0.6)
	_shop_layer.add_child(div)

	# Status label
	_status_label = Label.new()
	_status_label.position = Vector2(px, py + PANEL_H - 94)
	_status_label.size = Vector2(PANEL_W, 26)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.modulate = Color(0.50, 1.0, 0.50)
	_shop_layer.add_child(_status_label)

	# Buttons
	const BTN_X_OFFSET: int = 30
	const BTN_W_OFFSET: int = 60
	const BTN_H: int = 46
	const BTN_GAP: int = 56
	var bx := px + BTN_X_OFFSET
	var bw := PANEL_W - BTN_W_OFFSET
	var by := py + 116

	_btn_energy = _make_button(_shop_layer, bx, by, bw, BTN_H,
		"Energy Cell Cache  —  +50 starting energy next run  (%d minerals)" % COST_ENERGY_CACHE,
		_buy_energy_cache)
	by += BTN_GAP

	_btn_rations = _make_button(_shop_layer, bx, by, bw, BTN_H,
		"Space Snacks  —  +20 scout cat carry capacity next run  (%d minerals)" % COST_RATIONS,
		_buy_rations)
	by += BTN_GAP

	_btn_shroom = _make_button(_shop_layer, bx, by, bw, BTN_H,
		"Astro Shroom  —  +12 ore yield charges next run  (%d minerals)" % COST_SHROOM,
		_buy_shroom)
	by += BTN_GAP

	_btn_sharpen = _make_button(_shop_layer, bx, by, bw, BTN_H,
		"Pickaxe Sharpener  —  +1 Mining power next run  (%d minerals)" % COST_SHARPENING,
		_buy_sharpening)
	by += BTN_GAP

	# Close button
	var div2 := ColorRect.new()
	div2.position = Vector2(px + 20, py + PANEL_H - 70)
	div2.size = Vector2(PANEL_W - 40, 2)
	div2.color = Color(0.60, 0.45, 0.20, 0.5)
	_shop_layer.add_child(div2)

	var close_btn := Button.new()
	close_btn.text = "Close Shop"
	close_btn.position = Vector2(px + (PANEL_W - 220) / 2, py + PANEL_H - 56)
	close_btn.size = Vector2(220, 44)
	close_btn.pressed.connect(_close_shop)
	_shop_layer.add_child(close_btn)

func _make_button(parent: Node, x: int, y: int, w: int, h: int, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _show_shop() -> void:
	_shop_visible = true
	_hub_visible = true  # Freeze player movement via PlayerProbe check
	_refresh_minerals()
	_update_button_states()
	_status_label.text = ""
	_shop_layer.visible = true

func _close_shop() -> void:
	_shop_visible = false
	_hub_visible = false
	_shop_layer.visible = false

func _refresh_minerals() -> void:
	_minerals_label.text = "Banked Minerals: %d" % GameManager.mineral_currency

func _update_button_states() -> void:
	var m := GameManager.mineral_currency
	_btn_energy.disabled  = m < COST_ENERGY_CACHE
	_btn_rations.disabled = m < COST_RATIONS
	_btn_shroom.disabled  = m < COST_SHROOM
	_btn_sharpen.disabled = m < COST_SHARPENING

func _set_status(msg: String) -> void:
	_status_label.text = msg

# ---------------------------------------------------------------------------
# Purchases
# ---------------------------------------------------------------------------

func _buy_energy_cache() -> void:
	if GameManager.mineral_currency < COST_ENERGY_CACHE:
		return
	GameManager.mineral_currency -= COST_ENERGY_CACHE
	GameManager.settlement_energy_bonus += 50
	GameManager.save_game()
	_set_status("+50 energy cell cache ready for next run!")
	_refresh_minerals()
	_update_button_states()

func _buy_rations() -> void:
	if GameManager.mineral_currency < COST_RATIONS:
		return
	GameManager.mineral_currency -= COST_RATIONS
	GameManager.settlement_forager_bonus += 20
	GameManager.save_game()
	_set_status("+20 Scout Cat carry capacity next run!")
	_refresh_minerals()
	_update_button_states()

func _buy_shroom() -> void:
	if GameManager.mineral_currency < COST_SHROOM:
		return
	GameManager.mineral_currency -= COST_SHROOM
	GameManager.settlement_shroom_charges += 12
	GameManager.save_game()
	_set_status("+12 Astro Shroom charges next run!")
	_refresh_minerals()
	_update_button_states()

func _buy_sharpening() -> void:
	if GameManager.mineral_currency < COST_SHARPENING:
		return
	GameManager.mineral_currency -= COST_SHARPENING
	GameManager.settlement_mandible_bonus += 1
	GameManager.save_game()
	_set_status("+1 Mining power next run!")
	_refresh_minerals()
	_update_button_states()
