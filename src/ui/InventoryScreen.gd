class_name InventoryScreen
extends CanvasLayer

# Inventory overlay — toggled with I key during a mining run.
# Shows three sections:
#   1. Inventory Slot Grid  — tool items (pickaxe, ladder) + mined ore, with tooltips and drag
#   2. Equipment            — pelt / paws / claws / whiskers upgrade levels
#   3. Artifacts            — active run-buff items from the Wandering Trader

# Ore display order (matches terrain depth: shallow → deep)
# Textures and colors must match MiningLevel.TILE_TEXTURE_PATHS and TILE_COLORS exactly.
const ITEMS_TILESET_PATH: String = "res://assets/db32_rpg_items/items_tileset.tres"
const PICKAXE_ATLAS_COORD: Vector2i = Vector2i(0, 10)
const BLOCKS_TILESET_PATH: String = "res://assets/blocks/blocks_tileset.tres"
const LADDER_ATLAS_COORD: Vector2i = Vector2i(3, 8)
const TILE_SIZE: int = 16

const ORE_ORDER: Array = [
	{"tile": 3,  "name": "Lunar Copper",      "tex": "res://assets/blocks/stone_ore_copper.png",             "color": Color(0.90, 0.60, 0.25)},
	{"tile": 4,  "name": "Deep Lunar Copper", "tex": "res://assets/blocks/stone_ore_copper.png",             "color": Color(0.80, 0.50, 0.15)},
	{"tile": 5,  "name": "Meteor Iron",       "tex": "res://assets/blocks/stone_ore_iron.png",               "color": Color(0.90, 0.45, 0.70)},
	{"tile": 6,  "name": "Deep Meteor Iron",  "tex": "res://assets/blocks/stone_ore_iron.png",               "color": Color(0.75, 0.35, 0.60)},
	{"tile": 7,  "name": "Star Gold",         "tex": "res://assets/blocks/stone_ore_gold.png",               "color": Color(0.85, 0.80, 1.00)},
	{"tile": 8,  "name": "Deep Star Gold",    "tex": "res://assets/blocks/stone_ore_gold.png",               "color": Color(0.70, 0.65, 0.90)},
	{"tile": 9,  "name": "Cosmic Gem",        "tex": "res://assets/blocks/stone_generic_ore_crystalline.png","color": Color(0.20, 0.90, 0.95)},
	{"tile": 10, "name": "Deep Cosmic Gem",   "tex": "res://assets/blocks/stone_generic_ore_crystalline.png","color": Color(0.10, 0.80, 0.85)},
]

# Artifact plant icons: one distinct plant per trader item key
const ARTIFACT_DEFS: Dictionary = {
	"energy":    {"label": "Energy Cache",     "desc": "+50 Energy",               "plant": "res://assets/blocks/plants/cattail.png",       "color": Color(0.20, 0.90, 0.20)},
	"repair":  {"label": "Pelt Patch",     "desc": "Restored 1 HP",          "plant": "res://assets/blocks/plants/aloe.png",           "color": Color(0.85, 0.08, 0.08)},
	"shroom":  {"label": "Mining Shroom",  "desc": "x2 Ore Yield",           "plant": "res://assets/blocks/plants/mushroom_brown.png", "color": Color(0.50, 0.90, 0.20)},
	"compass": {"label": "Lucky Compass",  "desc": "x2 Lucky Strike",        "plant": "res://assets/blocks/plants/dandelion.png",      "color": Color(1.00, 0.90, 0.10)},
	"map":     {"label": "Ancient Map",    "desc": "x2 Sonar Radius",        "plant": "res://assets/blocks/plants/fern.png",           "color": Color(0.20, 0.90, 1.00)},
}

# Tool items that occupy dedicated slots at the front of the inventory grid.
# These are always present; the pickaxe is a usable tool and the ladder is a placeable tool.
const TOOL_DEFS: Array = [
	{
		"id": "pickaxe",
		"name": "Pickaxe",
		"slot_type": "Tool",
		"color": Color(0.80, 0.65, 0.35),
		"border_color": Color(0.95, 0.65, 0.15, 0.90),
		"desc": "Your primary digging tool.\nLeft-click to swing and break tiles.\nPower scales with Claws upgrade level.",
	},
	{
		"id": "ladder",
		"name": "Ladder",
		"slot_type": "Placeable",
		"color": Color(0.85, 0.65, 0.20),
		"border_color": Color(0.80, 0.60, 0.15, 0.90),
		"desc": "Climbable scaffolding tile.\nSelect hotbar slot 2 and left-click to place.\nRight-click a placed ladder to retrieve it.",
	},
]

const PANEL_W: int  = 780
const PANEL_H: int  = 560
const ICON_SZ: int  = 40
const ROW_H: int    = 50
const SEC_GAP: int  = 14

# Inventory slot grid constants
const SLOT_SIZE: int  = 52   # px per slot cell (icon + padding)
const SLOT_GAP: int   = 4    # gap between cells
const SLOT_COLS: int  = 10   # columns in the slot grid
const TOOL_SLOT_COUNT: int = 2  # Pickaxe slot + Ladder slot

var _bg: ColorRect
var _title: Label
var _close_hint: Label

# Sections rebuilt each time the screen opens
var _content_root: Control

# Reference set by MiningLevel when it instantiates this screen
var mining_level: Node = null

# -------------------------------------------------------------------
# Tooltip — floating info panel shown when hovering a slot
# -------------------------------------------------------------------
var _tooltip_root: Control
var _tooltip_bg: ColorRect
var _tooltip_name_lbl: Label
var _tooltip_type_lbl: Label
var _tooltip_stat_lbl: Label
var _tooltip_desc_lbl: Label

# -------------------------------------------------------------------
# Drag ghost — semi-transparent item copy that follows the cursor
# -------------------------------------------------------------------
var _drag_ghost: Control
var _drag_ghost_bg: ColorRect
var _drag_ghost_icon_root: Control  # Only this container's children are cleared between drags
var _is_dragging: bool = false
var _drag_slot_data: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_frame()
	_build_tooltip()
	_build_drag_ghost()

func _get_pickaxe_texture() -> Texture2D:
	var tileset = load(ITEMS_TILESET_PATH) as TileSet
	if not tileset:
		return null
	var source = tileset.get_source(0) as TileSetAtlasSource
	if not source:
		return null
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = source.texture
	atlas_texture.region = Rect2i(
		PICKAXE_ATLAS_COORD.x * TILE_SIZE,
		PICKAXE_ATLAS_COORD.y * TILE_SIZE,
		TILE_SIZE,
		TILE_SIZE
	)
	return atlas_texture

func _get_ladder_texture() -> Texture2D:
	var tileset = load(BLOCKS_TILESET_PATH) as TileSet
	if not tileset:
		return null
	var source = tileset.get_source(0) as TileSetAtlasSource
	if not source:
		return null
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = source.texture
	atlas_texture.region = Rect2i(
		LADDER_ATLAS_COORD.x * TILE_SIZE,
		LADDER_ATLAS_COORD.y * TILE_SIZE,
		TILE_SIZE,
		TILE_SIZE
	)
	return atlas_texture

func _process(_delta: float) -> void:
	if _is_dragging and _drag_ghost.visible:
		var mp: Vector2 = get_viewport().get_mouse_position()
		_drag_ghost.position = mp + Vector2(10, 10)

func _build_frame() -> void:
	var vp_w: int = 1280
	var vp_h: int = 720
	var px: int = (vp_w - PANEL_W) / 2
	var py: int = (vp_h - PANEL_H) / 2

	# Dark semi-transparent backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.65)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# Main panel
	_bg = ColorRect.new()
	_bg.color = Color(0.10, 0.09, 0.12, 0.96)
	_bg.position = Vector2(px, py)
	_bg.size = Vector2(PANEL_W, PANEL_H)
	add_child(_bg)

	# Panel border (drawn as 4 thin rects)
	var border_color := Color(0.50, 0.40, 0.65, 0.80)
	for side in _border_rects(px, py, PANEL_W, PANEL_H, 2):
		var br := ColorRect.new()
		br.color = border_color
		br.position = side[0]
		br.size = side[1]
		add_child(br)

	# Title
	_title = Label.new()
	_title.text = "INVENTORY"
	_title.position = Vector2(px + 20, py + 12)
	_title.custom_minimum_size = Vector2(PANEL_W - 40, 28)
	_title.add_theme_font_size_override("font_size", 20)
	_title.modulate = Color(0.85, 0.70, 1.00)
	add_child(_title)

	# Separator under title
	var sep := ColorRect.new()
	sep.color = Color(0.50, 0.40, 0.65, 0.50)
	sep.position = Vector2(px + 16, py + 44)
	sep.size = Vector2(PANEL_W - 32, 1)
	add_child(sep)

	# Close hint
	_close_hint = Label.new()
	_close_hint.text = "[I] Close"
	_close_hint.position = Vector2(px + PANEL_W - 100, py + 14)
	_close_hint.add_theme_font_size_override("font_size", 13)
	_close_hint.modulate = Color(0.55, 0.55, 0.65, 0.90)
	add_child(_close_hint)

	# Scrollable content area
	_content_root = Control.new()
	_content_root.position = Vector2(px + 16, py + 52)
	_content_root.size = Vector2(PANEL_W - 32, PANEL_H - 68)
	_content_root.clip_contents = true
	add_child(_content_root)

func _build_tooltip() -> void:
	_tooltip_root = Control.new()
	_tooltip_root.visible = false
	_tooltip_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tooltip_root)

	# Background
	_tooltip_bg = ColorRect.new()
	_tooltip_bg.color = Color(0.07, 0.06, 0.11, 0.97)
	_tooltip_bg.size = Vector2(230, 108)
	_tooltip_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_bg)

	# Border around tooltip
	var bc := Color(0.60, 0.50, 0.75, 0.80)
	for side in _border_rects(0, 0, 230, 108, 2):
		var br := ColorRect.new()
		br.color = bc
		br.position = side[0]
		br.size = side[1]
		br.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tooltip_root.add_child(br)

	_tooltip_name_lbl = Label.new()
	_tooltip_name_lbl.position = Vector2(10, 7)
	_tooltip_name_lbl.custom_minimum_size = Vector2(210, 20)
	_tooltip_name_lbl.add_theme_font_size_override("font_size", 14)
	_tooltip_name_lbl.modulate = Color(1.0, 0.95, 0.70)
	_tooltip_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_name_lbl)

	_tooltip_type_lbl = Label.new()
	_tooltip_type_lbl.position = Vector2(10, 26)
	_tooltip_type_lbl.custom_minimum_size = Vector2(210, 16)
	_tooltip_type_lbl.add_theme_font_size_override("font_size", 11)
	_tooltip_type_lbl.modulate = Color(0.55, 0.85, 0.55)
	_tooltip_type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_type_lbl)

	_tooltip_stat_lbl = Label.new()
	_tooltip_stat_lbl.position = Vector2(10, 44)
	_tooltip_stat_lbl.custom_minimum_size = Vector2(210, 18)
	_tooltip_stat_lbl.add_theme_font_size_override("font_size", 12)
	_tooltip_stat_lbl.modulate = Color(0.90, 0.85, 0.75)
	_tooltip_stat_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_stat_lbl)

	_tooltip_desc_lbl = Label.new()
	_tooltip_desc_lbl.position = Vector2(10, 63)
	_tooltip_desc_lbl.custom_minimum_size = Vector2(210, 40)
	_tooltip_desc_lbl.add_theme_font_size_override("font_size", 10)
	_tooltip_desc_lbl.modulate = Color(0.60, 0.60, 0.68)
	_tooltip_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tooltip_desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tooltip_root.add_child(_tooltip_desc_lbl)

func _build_drag_ghost() -> void:
	_drag_ghost = Control.new()
	_drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.visible = false
	_drag_ghost.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	add_child(_drag_ghost)

	_drag_ghost_bg = ColorRect.new()
	_drag_ghost_bg.color = Color(0.20, 0.18, 0.26, 0.80)
	_drag_ghost_bg.position = Vector2.ZERO
	_drag_ghost_bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	_drag_ghost_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost.add_child(_drag_ghost_bg)

	# Ghost border (permanent frame, not cleared between drags)
	for side in _slot_border_rects(0, 0, SLOT_SIZE, SLOT_SIZE, 2):
		var br := ColorRect.new()
		br.color = Color(0.85, 0.80, 0.40, 0.70)
		br.position = side[0]
		br.size = side[1]
		br.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_drag_ghost.add_child(br)

	# Dedicated container for icon content — cleared on each new drag
	_drag_ghost_icon_root = Control.new()
	_drag_ghost_icon_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_ghost_icon_root.position = Vector2.ZERO
	_drag_ghost_icon_root.size = Vector2(SLOT_SIZE, SLOT_SIZE)
	_drag_ghost.add_child(_drag_ghost_icon_root)

func _border_rects(x: int, y: int, w: int, h: int, t: int) -> Array:
	return [
		[Vector2(x, y),             Vector2(w, t)],      # top
		[Vector2(x, y + h - t),     Vector2(w, t)],      # bottom
		[Vector2(x, y),             Vector2(t, h)],      # left
		[Vector2(x + w - t, y),     Vector2(t, h)],      # right
	]

# Called by MiningLevel to open the screen and pass current run data.
func open(ore_counts: Dictionary, shroom_charges: int, lucky_compass: bool, ancient_map: bool) -> void:
	_rebuild_content(ore_counts, shroom_charges, lucky_compass, ancient_map)
	show()
	get_tree().paused = true

func close() -> void:
	_hide_tooltip()
	_end_drag()
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_inventory"):
		close()
		get_viewport().set_input_as_handled()
	# End drag if mouse is released outside any interactive slot
	if _is_dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_end_drag()

func _rebuild_content(ore_counts: Dictionary, shroom_charges: int, lucky_compass: bool, ancient_map: bool) -> void:
	_hide_tooltip()
	_end_drag()

	# Clear previous content
	for child in _content_root.get_children():
		child.queue_free()

	var content_w: int = PANEL_W - 32
	var col_w: int = content_w / 2

	# -----------------------------------------------------------------------
	# Section 1: Inventory Slot Grid  (full width) — tools + ore
	# -----------------------------------------------------------------------
	var y: int = 4
	y = _draw_section_header(_content_root, 0, y, content_w, "Inventory",
		Color(0.85, 0.65, 0.20))
	y += 4
	y = _draw_slot_grid(_content_root, 0, y, content_w, ore_counts)

	# Divider between grid and lower sections
	var div := ColorRect.new()
	div.color = Color(0.50, 0.40, 0.65, 0.30)
	div.position = Vector2(0, y + 6)
	div.size = Vector2(content_w, 1)
	_content_root.add_child(div)
	y += 14

	# -----------------------------------------------------------------------
	# Lower half: Equipment (left col) | Artifacts (right col)
	# -----------------------------------------------------------------------
	var eq_y: int = y
	eq_y = _draw_section_header(_content_root, 0, eq_y, col_w, "Equipment",
		Color(0.35, 0.75, 0.95))
	eq_y += 4
	_draw_equipment(_content_root, 0, eq_y, col_w)

	var art_x: int = col_w + 8
	var art_y: int = y
	art_y = _draw_section_header(_content_root, art_x, art_y, col_w - 8, "Artifacts",
		Color(0.55, 0.90, 0.45))
	art_y += 4
	_draw_artifacts(_content_root, art_x, art_y, col_w - 8,
		shroom_charges, lucky_compass, ancient_map)

# -----------------------------------------------------------------------
# Slot grid — tool slots first (pickaxe, ladder), then ore stacks.
# Every occupied slot has an interactive overlay for tooltip + drag.
# -----------------------------------------------------------------------
func _draw_slot_grid(parent: Control, x: int, y: int, w: int, ore_counts: Dictionary) -> int:
	var ore_capacity: int = GameManager.get_ore_capacity()
	var total_display_slots: int = TOOL_SLOT_COUNT + ore_capacity

	# Build ore stacks (same-type chunks grouped up to STACK_SIZE per slot)
	var stacks: Array[Dictionary] = []
	for ore in ORE_ORDER:
		var remaining: int = ore_counts.get(ore["tile"], 0)
		while remaining > 0:
			var stack_count: int = mini(remaining, GameManager.STACK_SIZE)
			stacks.append({"tile": ore["tile"], "count": stack_count, "ore": ore})
			remaining -= stack_count

	var used_ore_slots: int = stacks.size()
	var total_used_slots: int = TOOL_SLOT_COUNT + used_ore_slots

	var cols: int = SLOT_COLS
	var cell: int = SLOT_SIZE + SLOT_GAP
	var rows: int = ceili(float(total_display_slots) / float(cols))

	# Panel content_root offset in viewport space (for tooltip positioning)
	var vp_w: int = 1280
	var vp_h: int = 720
	var cr_gx: int = (vp_w - PANEL_W) / 2 + 16
	var cr_gy: int = (vp_h - PANEL_H) / 2 + 52

	for idx in range(total_display_slots):
		var col: int = idx % cols
		var row: int = idx / cols
		var sx: int = x + col * cell
		var sy: int = y + row * cell

		var is_tool: bool = idx < TOOL_SLOT_COUNT
		var slot_data: Dictionary = {}
		var is_occupied: bool = false

		if is_tool:
			is_occupied = true
			var tdef: Dictionary = TOOL_DEFS[idx]
			if idx == 0:
				# Pickaxe tool slot
				slot_data = {
					"type": "tool",
					"name": tdef["name"],
					"slot_type": tdef["slot_type"],
					"color": tdef["color"],
					"border_color": tdef["border_color"],
					"desc": tdef["desc"],
					"stat": "Power: %d  (Claws Lv%d)" % [
						GameManager.get_mandibles_power(),
						GameManager.mandibles_level
					],
					"texture": _get_pickaxe_texture(),
					"count": -1,
				}
			else:
				# Ladder placeable slot
				slot_data = {
					"type": "placeable",
					"name": tdef["name"],
					"slot_type": tdef["slot_type"],
					"color": tdef["color"],
					"border_color": tdef["border_color"],
					"desc": tdef["desc"],
					"stat": "Count: %d" % GameManager.ladder_count,
					"texture": _get_ladder_texture(),
					"count": GameManager.ladder_count,
				}
		else:
			var ore_idx: int = idx - TOOL_SLOT_COUNT
			if ore_idx < stacks.size():
				is_occupied = true
				var stack: Dictionary = stacks[ore_idx]
				var ore: Dictionary = stack["ore"]
				slot_data = {
					"type": "ore",
					"name": ore["name"],
					"slot_type": "Ore",
					"color": ore["color"],
					"border_color": Color(0.60, 0.50, 0.75, 0.70),
					"desc": "Mine ore and bank it at the surface station for minerals.",
					"stat": "×%d chunks" % stack["count"],
					"tex_path": ore["tex"],
					"count": stack["count"],
				}

		# --- Slot visuals ---

		# Slot background
		var bg := ColorRect.new()
		bg.color = Color(0.08, 0.07, 0.10, 0.90)
		bg.position = Vector2(sx, sy)
		bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(bg)

		# Tool slots get a tinted background tint to distinguish them
		if is_tool:
			var bc: Color = slot_data["border_color"]
			var tint := ColorRect.new()
			tint.color = Color(bc.r * 0.10, bc.g * 0.10, bc.b * 0.08, 1.0)
			tint.position = Vector2(sx + 2, sy + 2)
			tint.size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 4)
			tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(tint)

		# Slot border
		var border_col: Color
		if is_tool:
			border_col = slot_data["border_color"]
		elif is_occupied:
			border_col = Color(0.60, 0.50, 0.75, 0.70)
		else:
			border_col = Color(0.30, 0.25, 0.40, 0.50)

		for side in _slot_border_rects(sx, sy, SLOT_SIZE, SLOT_SIZE, 2):
			var br := ColorRect.new()
			br.color = border_col
			br.position = side[0]
			br.size = side[1]
			br.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(br)

		# Slot icon content
		if is_tool:
			_draw_tool_slot_content(parent, sx, sy, idx, slot_data)
		elif is_occupied:
			var stack: Dictionary = stacks[idx - TOOL_SLOT_COUNT]
			var ore: Dictionary = stack["ore"]

			var fill := ColorRect.new()
			fill.color = Color(ore["color"].r * 0.35, ore["color"].g * 0.35, ore["color"].b * 0.35, 1.0)
			fill.position = Vector2(sx + 2, sy + 2)
			fill.size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 4)
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(fill)

			var tex: Texture2D = load(ore["tex"]) as Texture2D
			if tex:
				var icon := TextureRect.new()
				icon.texture = tex
				icon.position = Vector2(sx + 4, sy + 4)
				icon.size = Vector2(SLOT_SIZE - 8, SLOT_SIZE - 8)
				icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				icon.modulate = ore["color"]
				icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				parent.add_child(icon)

			# Stack count badge in bottom-right corner
			var badge := Label.new()
			badge.text = "×%d" % stack["count"]
			badge.position = Vector2(sx + 2, sy + SLOT_SIZE - 16)
			badge.size = Vector2(SLOT_SIZE - 4, 14)
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			badge.add_theme_font_size_override("font_size", 10)
			badge.modulate = Color(1.0, 1.0, 1.0, 0.95)
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(badge)

		# --- Interactive overlay (hover tooltip + drag) for occupied slots ---
		if is_occupied or is_tool:
			var hit := Control.new()
			hit.position = Vector2(sx, sy)
			hit.size = Vector2(SLOT_SIZE, SLOT_SIZE)
			hit.mouse_filter = Control.MOUSE_FILTER_STOP
			# Capture slot data in closure-friendly variable
			var captured: Dictionary = slot_data.duplicate()
			var slot_gx: int = cr_gx + sx
			var slot_gy: int = cr_gy + sy
			hit.mouse_entered.connect(_on_slot_hover_enter.bind(captured, slot_gx, slot_gy))
			hit.mouse_exited.connect(_on_slot_hover_exit)
			hit.gui_input.connect(_on_slot_gui_input.bind(captured))
			parent.add_child(hit)

	# Slot count label below the grid
	var grid_h: int = rows * cell
	var count_lbl := Label.new()
	count_lbl.text = "%d / %d slots used" % [total_used_slots, total_display_slots]
	count_lbl.position = Vector2(x, y + grid_h + 2)
	count_lbl.custom_minimum_size = Vector2(w, 18)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.modulate = Color(0.65, 0.65, 0.70, 0.90)
	parent.add_child(count_lbl)

	return y + grid_h + 22

# Draws icon content inside a tool slot (pickaxe texture or ladder icon)
func _draw_tool_slot_content(parent: Control, sx: int, sy: int, tool_idx: int, slot_data: Dictionary) -> void:
	var item_color: Color = slot_data["color"]

	if tool_idx == 0:
		# Pickaxe — texture icon
		var tex: Texture2D = slot_data.get("texture") as Texture2D
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.position = Vector2(sx + 5, sy + 5)
			icon.size = Vector2(SLOT_SIZE - 10, SLOT_SIZE - 10)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.modulate = item_color
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(icon)

		# "T" badge in top-left corner (Tool)
		var tag := Label.new()
		tag.text = "T"
		tag.position = Vector2(sx + 3, sy + 2)
		tag.add_theme_font_size_override("font_size", 9)
		tag.modulate = Color(item_color.r, item_color.g, item_color.b, 0.65)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(tag)

	else:
		# Ladder — texture icon
		var tex: Texture2D = slot_data.get("texture") as Texture2D
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.position = Vector2(sx + 5, sy + 5)
			icon.size = Vector2(SLOT_SIZE - 10, SLOT_SIZE - 10)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.modulate = item_color
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			parent.add_child(icon)

		# Count badge bottom-right
		var badge := Label.new()
		badge.text = "×%d" % slot_data["count"]
		badge.position = Vector2(sx + 2, sy + SLOT_SIZE - 16)
		badge.size = Vector2(SLOT_SIZE - 4, 14)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.add_theme_font_size_override("font_size", 10)
		badge.modulate = Color(1.0, 1.0, 1.0, 0.95)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(badge)

		# "P" badge in top-left corner (Placeable)
		var tag := Label.new()
		tag.text = "P"
		tag.position = Vector2(sx + 3, sy + 2)
		tag.add_theme_font_size_override("font_size", 9)
		tag.modulate = Color(item_color.r, item_color.g, item_color.b, 0.65)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent.add_child(tag)

# -----------------------------------------------------------------------
# Slot interactivity — hover tooltip
# -----------------------------------------------------------------------

func _on_slot_hover_enter(slot_data: Dictionary, slot_gx: int, slot_gy: int) -> void:
	_show_tooltip(slot_data, slot_gx, slot_gy)

func _on_slot_hover_exit() -> void:
	_hide_tooltip()

func _show_tooltip(slot_data: Dictionary, slot_gx: int, slot_gy: int) -> void:
	_tooltip_name_lbl.text = slot_data.get("name", "")
	_tooltip_type_lbl.text = slot_data.get("slot_type", "")
	_tooltip_stat_lbl.text = slot_data.get("stat", "")
	_tooltip_desc_lbl.text = slot_data.get("desc", "")

	var item_color: Color = slot_data.get("color", Color(0.90, 0.90, 0.90))
	_tooltip_name_lbl.modulate = item_color

	match slot_data.get("type", ""):
		"tool":      _tooltip_type_lbl.modulate = Color(0.95, 0.65, 0.15)
		"placeable": _tooltip_type_lbl.modulate = Color(0.55, 0.90, 0.40)
		"ore":       _tooltip_type_lbl.modulate = Color(0.50, 0.80, 0.95)
		_:           _tooltip_type_lbl.modulate = Color(0.70, 0.70, 0.75)

	# Position tooltip to the right of the slot; flip left if near screen edge
	var tw: int = 230
	var th: int = 108
	var tx: float = slot_gx + SLOT_SIZE + 6
	var ty: float = slot_gy - 8
	if tx + tw > 1270:
		tx = slot_gx - tw - 6
	if ty + th > 715:
		ty = 715 - th
	if ty < 4:
		ty = 4

	_tooltip_root.position = Vector2(tx, ty)
	_tooltip_root.visible = true

func _hide_tooltip() -> void:
	if _tooltip_root:
		_tooltip_root.visible = false

# -----------------------------------------------------------------------
# Slot interactivity — drag ghost
# -----------------------------------------------------------------------

func _on_slot_gui_input(event: InputEvent, slot_data: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag(slot_data)
		else:
			_end_drag()

func _start_drag(slot_data: Dictionary) -> void:
	_drag_slot_data = slot_data
	_is_dragging = true

	# Clear previous icon content from the dedicated icon container
	for child in _drag_ghost_icon_root.get_children():
		child.queue_free()

	# Tint ghost background with item color
	var item_color: Color = slot_data.get("color", Color(0.5, 0.5, 0.5))
	_drag_ghost_bg.color = Color(item_color.r * 0.18, item_color.g * 0.18, item_color.b * 0.22, 0.85)

	var slot_type: String = slot_data.get("type", "")

	if slot_type == "tool":
		# Pickaxe texture ghost
		var tex: Texture2D = slot_data.get("texture") as Texture2D
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.position = Vector2(5, 5)
			icon.size = Vector2(SLOT_SIZE - 10, SLOT_SIZE - 10)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.modulate = Color(item_color.r, item_color.g, item_color.b, 0.75)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_drag_ghost_icon_root.add_child(icon)

	elif slot_type == "placeable":
		# Ladder texture ghost
		var tex: Texture2D = slot_data.get("texture") as Texture2D
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.position = Vector2(5, 5)
			icon.size = Vector2(SLOT_SIZE - 10, SLOT_SIZE - 10)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.modulate = Color(item_color.r, item_color.g, item_color.b, 0.75)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_drag_ghost_icon_root.add_child(icon)

	elif slot_type == "ore":
		# Ore icon ghost
		var tex_path: String = slot_data.get("tex_path", "")
		var tex: Texture2D = load(tex_path) as Texture2D if tex_path != "" else null
		if tex:
			var fill := ColorRect.new()
			fill.color = Color(item_color.r * 0.35, item_color.g * 0.35, item_color.b * 0.35, 0.80)
			fill.position = Vector2(2, 2)
			fill.size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 4)
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_drag_ghost_icon_root.add_child(fill)
			var icon := TextureRect.new()
			icon.texture = tex
			icon.position = Vector2(4, 4)
			icon.size = Vector2(SLOT_SIZE - 8, SLOT_SIZE - 8)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.modulate = Color(item_color.r, item_color.g, item_color.b, 0.80)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_drag_ghost_icon_root.add_child(icon)

	# Position ghost at cursor offset
	var mp: Vector2 = get_viewport().get_mouse_position()
	_drag_ghost.position = mp + Vector2(10, 10)
	_drag_ghost.visible = true

func _end_drag() -> void:
	_is_dragging = false
	_drag_ghost.visible = false
	# Clear icon content container (bg and border rects stay for next drag)
	for child in _drag_ghost_icon_root.get_children():
		child.queue_free()

func _slot_border_rects(x: int, y: int, w: int, h: int, t: int) -> Array:
	return [
		[Vector2(x, y),             Vector2(w, t)],
		[Vector2(x, y + h - t),     Vector2(w, t)],
		[Vector2(x, y),             Vector2(t, h)],
		[Vector2(x + w - t, y),     Vector2(t, h)],
	]


func _draw_section_header(parent: Control, x: int, y: int, w: int, title: String, color: Color) -> int:
	var lbl := Label.new()
	lbl.text = title.to_upper()
	lbl.position = Vector2(x, y)
	lbl.custom_minimum_size = Vector2(w, 22)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.modulate = color
	parent.add_child(lbl)

	var line := ColorRect.new()
	line.color = Color(color.r, color.g, color.b, 0.35)
	line.position = Vector2(x, y + 22)
	line.size = Vector2(w, 1)
	parent.add_child(line)

	return y + 26

func _draw_ore_row(parent: Control, x: int, y: int, w: int, ore: Dictionary, count: int) -> int:
	# Icon (texture from terrain gen)
	var tex: Texture2D = load(ore["tex"]) as Texture2D
	if tex:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.position = Vector2(x + 2, y + 4)
		icon.size = Vector2(ICON_SZ, ICON_SZ)
		icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		parent.add_child(icon)

	# Name + count
	var name_lbl := Label.new()
	name_lbl.text = ore["name"]
	name_lbl.position = Vector2(x + ICON_SZ + 8, y + 4)
	name_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 50, 20)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.modulate = ore["color"]
	parent.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "×%d" % count
	count_lbl.position = Vector2(x + w - 42, y + 4)
	count_lbl.custom_minimum_size = Vector2(40, 20)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.modulate = Color(0.90, 0.90, 0.90)
	parent.add_child(count_lbl)

	return y + ROW_H - 6

func _draw_equipment(parent: Control, x: int, y: int, w: int) -> int:
	# Equipment icon colors (colored squares since no dedicated art)
	var items := [
		{
			"label": "Pelt",
			"color": Color(0.85, 0.18, 0.18),
			"level": GameManager.carapace_level,
			"stat": "Max HP: %d" % GameManager.get_max_health(),
		},
		{
			"label": "Paws",
			"color": Color(0.30, 0.70, 1.00),
			"level": GameManager.legs_level,
			"stat": "Energy: %d  Spd: %d" % [GameManager.get_max_energy(), int(GameManager.get_max_speed())],
		},
		{
			"label": "Claws",
			"color": Color(0.95, 0.65, 0.15),
			"level": GameManager.mandibles_level,
			"stat": "Slots: %d" % GameManager.get_ore_capacity(),
		},
		{
			"label": "Whiskers",
			"color": Color(0.20, 0.90, 0.90),
			"level": GameManager.mineral_sense_level,
			"stat": "Radius: %.0ft" % GameManager.get_sonar_ping_radius(),
		},
	]

	for item in items:
		# Colored square icon
		var icon_bg := ColorRect.new()
		icon_bg.color = Color(item["color"].r * 0.25, item["color"].g * 0.25, item["color"].b * 0.25, 1.0)
		icon_bg.position = Vector2(x + 2, y + 2)
		icon_bg.size = Vector2(ICON_SZ, ICON_SZ)
		parent.add_child(icon_bg)

		var icon_fill := ColorRect.new()
		icon_fill.color = item["color"]
		var fill_h := int(ICON_SZ * clampf((item["level"] + 1) * 0.22, 0.15, 1.0))
		icon_fill.position = Vector2(x + 2, y + 2 + ICON_SZ - fill_h)
		icon_fill.size = Vector2(ICON_SZ, fill_h)
		parent.add_child(icon_fill)

		# Level label overlaid on icon
		var lv_lbl := Label.new()
		lv_lbl.text = "Lv%d" % item["level"]
		lv_lbl.position = Vector2(x + 2, y + ICON_SZ - 14)
		lv_lbl.custom_minimum_size = Vector2(ICON_SZ, 16)
		lv_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv_lbl.add_theme_font_size_override("font_size", 10)
		lv_lbl.modulate = Color(1.0, 1.0, 1.0, 0.95)
		parent.add_child(lv_lbl)

		# Name
		var name_lbl := Label.new()
		name_lbl.text = item["label"]
		name_lbl.position = Vector2(x + ICON_SZ + 8, y + 2)
		name_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 10, 20)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = item["color"]
		parent.add_child(name_lbl)

		# Stat line
		var stat_lbl := Label.new()
		stat_lbl.text = item["stat"]
		stat_lbl.position = Vector2(x + ICON_SZ + 8, y + 22)
		stat_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 10, 18)
		stat_lbl.add_theme_font_size_override("font_size", 11)
		stat_lbl.modulate = Color(0.75, 0.75, 0.80)
		parent.add_child(stat_lbl)

		y += ROW_H + 2

	return y

func _draw_artifacts(parent: Control, x: int, y: int, w: int,
		shroom_charges: int, lucky_compass: bool, ancient_map: bool) -> int:

	# Build list of currently active artifacts
	var active: Array = []
	if shroom_charges > 0:
		var def := ARTIFACT_DEFS["shroom"].duplicate()
		def["desc"] = "%d ores left" % shroom_charges
		active.append(def)
	if lucky_compass:
		active.append(ARTIFACT_DEFS["compass"])
	if ancient_map:
		active.append(ARTIFACT_DEFS["map"])

	if active.is_empty():
		var none_lbl := Label.new()
		none_lbl.text = "No active artifacts"
		none_lbl.position = Vector2(x + 2, y)
		none_lbl.add_theme_font_size_override("font_size", 12)
		none_lbl.modulate = Color(0.50, 0.50, 0.55, 0.80)
		parent.add_child(none_lbl)
		return y + 22

	for art in active:
		var tex: Texture2D = load(art["plant"]) as Texture2D
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.position = Vector2(x + 2, y + 2)
			icon.size = Vector2(ICON_SZ, ICON_SZ)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			parent.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = art["label"]
		name_lbl.position = Vector2(x + ICON_SZ + 8, y + 2)
		name_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 10, 20)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.modulate = art["color"]
		parent.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = art["desc"]
		desc_lbl.position = Vector2(x + ICON_SZ + 8, y + 22)
		desc_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 10, 18)
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.75, 0.75, 0.80)
		parent.add_child(desc_lbl)

		y += ROW_H + 2

	return y
