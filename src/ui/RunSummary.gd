class_name RunSummary
extends CanvasLayer

# Ore display info: tile_type_id -> { name, color, tex }
# IDs match MiningLevel.TileType enum values.
const ORE_INFO: Dictionary = {
	21: {"name": "Topsoil",     "color": Color(0.25, 0.50, 0.25), "tex": "res://assets/blocks/grass_side.png"},
	1:  {"name": "Dirt",        "color": Color(0.45, 0.28, 0.12), "tex": "res://assets/blocks/dirt.png"},
	2:  {"name": "Dark Mud",    "color": Color(0.35, 0.20, 0.08), "tex": "res://assets/blocks/mud.png"},
	11: {"name": "Stone",       "color": Color(0.50, 0.50, 0.50), "tex": "res://assets/blocks/stone_generic.png"},
	12: {"name": "Dark Stone",  "color": Color(0.40, 0.40, 0.40), "tex": "res://assets/blocks/gravel.png"},
	3:  {"name": "Copper",      "color": Color(0.80, 0.50, 0.20), "tex": "res://assets/blocks/stone_generic_ore_nuggets.png"},
	4:  {"name": "Deep Copper", "color": Color(0.70, 0.40, 0.10), "tex": "res://assets/blocks/stone_generic_ore_crystalline.png"},
	5:  {"name": "Iron",        "color": Color(0.65, 0.65, 0.72), "tex": "res://assets/blocks/gabbro.png"},
	6:  {"name": "Deep Iron",   "color": Color(0.55, 0.55, 0.65), "tex": "res://assets/blocks/schist.png"},
	7:  {"name": "Gold",        "color": Color(1.00, 0.85, 0.10), "tex": "res://assets/blocks/sandstone.png"},
	8:  {"name": "Deep Gold",   "color": Color(0.90, 0.75, 0.05), "tex": "res://assets/blocks/granite.png"},
	9:  {"name": "Gem",         "color": Color(0.15, 0.85, 0.75), "tex": "res://assets/blocks/amethyst.png"},
	10: {"name": "Deep Gem",    "color": Color(0.10, 0.75, 0.65), "tex": "res://assets/blocks/obsidian.png"},
}

# Display order: highest-value ores first, then common materials
const DISPLAY_ORDER: Array = [10, 9, 8, 7, 6, 5, 4, 3, 12, 11, 2, 1, 21]

const VW := 1280.0
const VH := 720.0
const PANEL_W := 540.0
const ROW_H := 38.0
const HEADER_H := 68.0
const FOOTER_H := 96.0

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# Full-screen catch-all control
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# Dark overlay
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.82)
	root.add_child(dim)

	# Determine which ore rows to show
	var ore_counts: Dictionary = GameManager.run_ore_counts
	var ore_earnings: Dictionary = GameManager.run_ore_earnings
	var rows: Array = []
	for tile_id in DISPLAY_ORDER:
		if ore_counts.get(tile_id, 0) > 0:
			rows.append(tile_id)

	# Panel height scales with number of rows
	var panel_h := HEADER_H + rows.size() * ROW_H + FOOTER_H
	panel_h = maxf(panel_h, 260.0)
	var px := (VW - PANEL_W) / 2.0
	var py := (VH - panel_h) / 2.0

	# Green border
	var border := ColorRect.new()
	border.position = Vector2(px - 2.0, py - 2.0)
	border.size = Vector2(PANEL_W + 4.0, panel_h + 4.0)
	border.color = Color(0.20, 0.70, 0.30)
	root.add_child(border)

	# Panel background
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(px, py)
	panel_bg.size = Vector2(PANEL_W, panel_h)
	panel_bg.color = Color(0.07, 0.09, 0.12, 1.0)
	root.add_child(panel_bg)

	# Title
	var title := Label.new()
	title.text = "Run Complete!"
	title.position = Vector2(px, py + 8.0)
	title.size = Vector2(PANEL_W, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.25, 0.95, 0.45))
	root.add_child(title)

	# Header separator
	_add_separator(root, px, py + HEADER_H - 4.0, PANEL_W)

	# Column headers
	_add_label(root, "Material", px + 46.0, py + HEADER_H - ROW_H + 4.0,
			200.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
			HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(root, "Count", px + 260.0, py + HEADER_H - ROW_H + 4.0,
			90.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
			HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label(root, "Minerals", px + 356.0, py + HEADER_H - ROW_H + 4.0,
			160.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
			HORIZONTAL_ALIGNMENT_RIGHT)

	# Ore rows
	var y := py + HEADER_H
	for i in rows.size():
		var tile_id: int = rows[i]
		var info: Dictionary = ORE_INFO[tile_id]
		var count: int = ore_counts.get(tile_id, 0)
		var earned: int = ore_earnings.get(tile_id, 0)

		# Alternating row tint
		if i % 2 == 0:
			var row_bg := ColorRect.new()
			row_bg.position = Vector2(px, y)
			row_bg.size = Vector2(PANEL_W, ROW_H)
			row_bg.color = Color(1.0, 1.0, 1.0, 0.03)
			root.add_child(row_bg)

		# Icon — try block texture first, fall back to solid colour square
		var tex_path: String = info.get("tex", "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tex := load(tex_path) as Texture2D
			if tex:
				var icon := TextureRect.new()
				icon.texture = tex
				icon.position = Vector2(px + 10.0, y + (ROW_H - 26.0) / 2.0)
				icon.size = Vector2(26.0, 26.0)
				icon.stretch_mode = TextureRect.STRETCH_SCALE
				root.add_child(icon)
			else:
				_add_colour_icon(root, px, y, info["color"])
		else:
			_add_colour_icon(root, px, y, info["color"])

		# Name
		_add_label(root, info["name"], px + 44.0, y, 220.0, ROW_H, 16,
				Color(0.92, 0.92, 0.92), HORIZONTAL_ALIGNMENT_LEFT)

		# Count
		_add_label(root, "x%d" % count, px + 260.0, y, 90.0, ROW_H, 16,
				Color(0.75, 0.75, 0.75), HORIZONTAL_ALIGNMENT_RIGHT)

		# Minerals earned
		_add_label(root, "+%d" % earned, px + 356.0, y, 160.0, ROW_H, 16,
				Color(1.00, 0.88, 0.25), HORIZONTAL_ALIGNMENT_RIGHT)

		y += ROW_H

	# Total separator + label
	_add_separator(root, px, y + 6.0, PANEL_W)

	var total_label := Label.new()
	total_label.text = "Total:  %d Minerals" % GameManager.run_mineral_currency
	total_label.position = Vector2(px, y + 10.0)
	total_label.size = Vector2(PANEL_W, 40.0)
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_label.add_theme_font_size_override("font_size", 22)
	total_label.add_theme_color_override("font_color", Color(1.00, 0.85, 0.10))
	root.add_child(total_label)

	# Return to Base button
	var btn := Button.new()
	btn.text = "Return to Base"
	btn.position = Vector2(px + PANEL_W / 2.0 - 100.0, py + panel_h - 52.0)
	btn.size = Vector2(200.0, 40.0)
	btn.pressed.connect(_on_return_pressed)
	root.add_child(btn)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _add_separator(parent: Control, px: float, sep_y: float, width: float) -> void:
	var sep := ColorRect.new()
	sep.position = Vector2(px + 12.0, sep_y)
	sep.size = Vector2(width - 24.0, 2.0)
	sep.color = Color(0.20, 0.70, 0.30, 0.45)
	parent.add_child(sep)

func _add_colour_icon(parent: Control, px: float, row_y: float, color: Color) -> void:
	var icon := ColorRect.new()
	icon.position = Vector2(px + 10.0, row_y + (ROW_H - 26.0) / 2.0)
	icon.size = Vector2(26.0, 26.0)
	icon.color = color
	parent.add_child(icon)

func _add_label(parent: Control, text: String, lx: float, ly: float,
		w: float, h: float, font_size: int, color: Color,
		h_align: HorizontalAlignment) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(lx, ly)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = h_align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)

func _on_return_pressed() -> void:
	GameManager.bank_currency()
	queue_free()
	GameManager.load_overworld()
