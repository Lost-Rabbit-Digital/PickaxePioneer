class_name InventoryScreen
extends CanvasLayer

# Inventory overlay — toggled with I key during a mining run.
# Shows three sections:
#   1. Mined Minerals — ore tiles collected this run, with terrain icons
#   2. Equipment     — carapace / legs / mandibles / mineral sense levels
#   3. Artifacts     — active run-buff items from the Wandering Trader

# Ore display order (matches terrain depth: shallow → deep)
# Textures and colors must match MiningLevel.TILE_TEXTURE_PATHS and TILE_COLORS exactly.
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

const PANEL_W: int  = 780
const PANEL_H: int  = 520
const ICON_SZ: int  = 40
const ROW_H: int    = 50
const SEC_GAP: int  = 14

# Inventory slot grid constants
const SLOT_SIZE: int  = 52   # px per slot cell (icon + padding)
const SLOT_GAP: int   = 4    # gap between cells
const SLOT_COLS: int  = 10   # columns in the slot grid

var _bg: ColorRect
var _title: Label
var _close_hint: Label

# Sections rebuilt each time the screen opens
var _content_root: Control

# Reference set by MiningLevel when it instantiates this screen
var mining_level: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_frame()

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
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_inventory"):
		close()
		get_viewport().set_input_as_handled()

func _rebuild_content(ore_counts: Dictionary, shroom_charges: int, lucky_compass: bool, ancient_map: bool) -> void:
	# Clear previous content
	for child in _content_root.get_children():
		child.queue_free()

	var content_w: int = PANEL_W - 32
	var col_w: int = content_w / 2

	# -----------------------------------------------------------------------
	# Section 1: Inventory Slot Grid  (full width)
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
	eq_y = _draw_equipment(_content_root, 0, eq_y, col_w)
	_draw_ladders(_content_root, 0, eq_y, col_w)

	var art_x: int = col_w + 8
	var art_y: int = y
	art_y = _draw_section_header(_content_root, art_x, art_y, col_w - 8, "Artifacts",
		Color(0.55, 0.90, 0.45))
	art_y += 4
	_draw_artifacts(_content_root, art_x, art_y, col_w - 8,
		shroom_charges, lucky_compass, ancient_map)

## Draws a grid of inventory slots. Same-type ores stack up to STACK_SIZE per slot.
## Occupied slots show the ore icon and a count badge; empty slots show a dark background.
## Returns the y position below the grid.
func _draw_slot_grid(parent: Control, x: int, y: int, w: int, ore_counts: Dictionary) -> int:
	var total_slots: int = GameManager.get_ore_capacity()

	# Build an array of stacks in collection order (grouped by ore type, STACK_SIZE per slot).
	# Each stack entry: {tile: int, count: int}
	var stacks: Array[Dictionary] = []
	for ore in ORE_ORDER:
		var remaining: int = ore_counts.get(ore["tile"], 0)
		while remaining > 0:
			var stack_count: int = mini(remaining, GameManager.STACK_SIZE)
			stacks.append({"tile": ore["tile"], "count": stack_count})
			remaining -= stack_count

	var used_slots: int = stacks.size()

	var cols: int = SLOT_COLS
	var cell: int = SLOT_SIZE + SLOT_GAP
	var rows: int = ceili(float(total_slots) / float(cols))

	for idx in range(total_slots):
		var col: int = idx % cols
		var row: int = idx / cols
		var sx: int = x + col * cell
		var sy: int = y + row * cell

		# Slot background
		var bg := ColorRect.new()
		bg.color = Color(0.08, 0.07, 0.10, 0.90)
		bg.position = Vector2(sx, sy)
		bg.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		parent.add_child(bg)

		# Slot border
		var border_col: Color
		if idx < used_slots:
			border_col = Color(0.60, 0.50, 0.75, 0.70)
		else:
			border_col = Color(0.30, 0.25, 0.40, 0.50)
		for side in _slot_border_rects(sx, sy, SLOT_SIZE, SLOT_SIZE, 2):
			var br := ColorRect.new()
			br.color = border_col
			br.position = side[0]
			br.size = side[1]
			parent.add_child(br)

		# Occupied slot — show ore icon, tint, and stack count badge
		if idx < stacks.size():
			var stack: Dictionary = stacks[idx]
			var tile_id: int = stack["tile"]
			var stack_count: int = stack["count"]
			for ore in ORE_ORDER:
				if ore["tile"] == tile_id:
					var fill := ColorRect.new()
					fill.color = Color(ore["color"].r * 0.35, ore["color"].g * 0.35, ore["color"].b * 0.35, 1.0)
					fill.position = Vector2(sx + 2, sy + 2)
					fill.size = Vector2(SLOT_SIZE - 4, SLOT_SIZE - 4)
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
						parent.add_child(icon)

					# Stack count badge in bottom-right corner
					var badge := Label.new()
					badge.text = "×%d" % stack_count
					badge.position = Vector2(sx + 2, sy + SLOT_SIZE - 16)
					badge.size = Vector2(SLOT_SIZE - 4, 14)
					badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
					badge.add_theme_font_size_override("font_size", 10)
					badge.modulate = Color(1.0, 1.0, 1.0, 0.95)
					parent.add_child(badge)
					break

	# Slot count label below the grid
	var grid_h: int = rows * cell
	var count_lbl := Label.new()
	count_lbl.text = "%d / %d slots used" % [used_slots, total_slots]
	count_lbl.position = Vector2(x, y + grid_h + 2)
	count_lbl.custom_minimum_size = Vector2(w, 18)
	count_lbl.add_theme_font_size_override("font_size", 12)
	count_lbl.modulate = Color(0.65, 0.65, 0.70, 0.90)
	parent.add_child(count_lbl)

	return y + grid_h + 22


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

func _draw_ladders(parent: Control, x: int, y: int, w: int) -> int:
	var count: int = GameManager.ladder_count
	y += SEC_GAP

	# Ladder icon — two poles + three rungs drawn as ColorRects
	var icon_container := Control.new()
	icon_container.position = Vector2(x + 2, y + 2)
	icon_container.size = Vector2(ICON_SZ, ICON_SZ)

	var pole_color := Color(0.80, 0.60, 0.15, 0.90)
	var rung_color := Color(0.70, 0.50, 0.10, 0.90)

	var lp := ColorRect.new()
	lp.color = pole_color
	lp.position = Vector2(6, 2)
	lp.size = Vector2(5, 36)
	icon_container.add_child(lp)

	var rp := ColorRect.new()
	rp.color = pole_color
	rp.position = Vector2(29, 2)
	rp.size = Vector2(5, 36)
	icon_container.add_child(rp)

	for r in 3:
		var rung := ColorRect.new()
		rung.color = rung_color
		rung.position = Vector2(6, 5 + r * 12)
		rung.size = Vector2(28, 4)
		icon_container.add_child(rung)

	parent.add_child(icon_container)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = "Ladders"
	name_lbl.position = Vector2(x + ICON_SZ + 8, y + 4)
	name_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 50, 20)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.modulate = Color(0.85, 0.65, 0.20)
	parent.add_child(name_lbl)

	# Count
	var count_lbl := Label.new()
	count_lbl.text = "×%d" % count
	count_lbl.position = Vector2(x + w - 42, y + 4)
	count_lbl.custom_minimum_size = Vector2(40, 20)
	count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_lbl.add_theme_font_size_override("font_size", 13)
	count_lbl.modulate = Color(0.90, 0.90, 0.90)
	parent.add_child(count_lbl)

	# "[F] to place" hint
	var hint_lbl := Label.new()
	hint_lbl.text = "[F] to place"
	hint_lbl.position = Vector2(x + ICON_SZ + 8, y + 24)
	hint_lbl.custom_minimum_size = Vector2(w - ICON_SZ - 10, 18)
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.modulate = Color(0.60, 0.55, 0.45, 0.80)
	parent.add_child(hint_lbl)

	return y + ROW_H + 2
