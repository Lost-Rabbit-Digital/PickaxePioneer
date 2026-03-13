class_name RunSummary
extends CanvasLayer

# Ore display info: tile_type_id -> { name, color, tex }
# IDs match MiningLevel.TileType enum values.
const ORE_INFO: Dictionary = {
	21: {"name": "Space Dust",      "color": Color(0.10, 0.20, 0.35), "tex": "res://assets/blocks/grass_side.png"},
	1:  {"name": "Moon Rock",       "color": Color(0.30, 0.30, 0.38), "tex": "res://assets/blocks/dirt.png"},
	2:  {"name": "Dense Moon Rock", "color": Color(0.22, 0.22, 0.30), "tex": "res://assets/blocks/mud.png"},
	11: {"name": "Asteroid",        "color": Color(0.35, 0.25, 0.55), "tex": "res://assets/blocks/stone_generic.png"},
	12: {"name": "Dark Asteroid",   "color": Color(0.25, 0.18, 0.45), "tex": "res://assets/blocks/gravel.png"},
	3:  {"name": "Space Coal",      "color": Color(0.25, 0.25, 0.28), "tex": "res://assets/blocks/mud.png"},
	4:  {"name": "Lunar Copper",    "color": Color(0.90, 0.60, 0.25), "tex": "res://assets/blocks/stone_ore_copper.png"},
	5:  {"name": "Meteor Iron",     "color": Color(0.65, 0.68, 0.75), "tex": "res://assets/blocks/stone_ore_iron.png"},
	6:  {"name": "Star Gold",       "color": Color(1.00, 0.80, 0.10), "tex": "res://assets/blocks/stone_ore_gold.png"},
	7:  {"name": "Cosmic Diamond",  "color": Color(0.60, 0.90, 1.00), "tex": "res://assets/blocks/stone_generic_ore_crystalline.png"},
}

# Display order: highest-value ores first, then common materials
const DISPLAY_ORDER: Array = [7, 6, 5, 4, 3, 12, 11, 2, 1, 21]

const VW := 1280.0
const VH := 720.0
const PANEL_W := 540.0
const ROW_H := 38.0
const HEADER_H := 68.0
const FOOTER_H := 132.0

# Animation state
var _panel_node: Control = null
var _row_groups: Array = []     # Array of Arrays — each inner array holds Control nodes for one row
var _total_label: Label = null
var _xp_label: Label = null
var _final_total: int = 0
var _border: ColorRect = null

var _narrow_escape: bool = false
var _escape_bonus: int = 0

# XP preview — computed before bank_currency() is called so we can display it
var _pending_xp: int = 0
var _pending_levels: int = 0
var _level_before: int = 1

func _ready() -> void:
	# Near-miss escape reward: +10% minerals if exiting with < 10% energy
	var energy_pct := float(GameManager.current_energy) / float(maxi(1, GameManager.get_max_energy()))
	if energy_pct < 0.10 and energy_pct > 0.0 and GameManager.run_coins > 0:
		_narrow_escape = true
		_escape_bonus = maxi(1, GameManager.run_coins / 10)
		GameManager.run_coins += _escape_bonus
	_final_total = GameManager.run_coins
	# Compute XP that will be earned when the player banks these minerals
	_level_before = GameManager.player_level
	_pending_xp = _final_total / 100
	if _pending_xp > 0:
		var sim_xp: int = GameManager.player_xp + _pending_xp
		var sim_level: int = GameManager.player_level
		while sim_xp >= PerkSystem.xp_for_next_level(sim_level):
			sim_xp -= PerkSystem.xp_for_next_level(sim_level)
			sim_level += 1
		_pending_levels = sim_level - GameManager.player_level
	_build_ui()
	_play_intro()

func _build_ui() -> void:
	# Full-screen catch-all control
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# Dark overlay (static, behind everything)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.0)
	root.add_child(dim)
	# Fade overlay in separately so it doesn't move with the panel
	var dim_tween := create_tween()
	dim_tween.tween_property(dim, "color:a", 0.82, 0.2)

	# Panel container — this node slides in
	_panel_node = Control.new()
	_panel_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_node.position = Vector2(0.0, -60.0)
	_panel_node.modulate.a = 0.0
	root.add_child(_panel_node)

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

	# Cosmic border (starts brighter, settles to normal)
	_border = ColorRect.new()
	_border.position = Vector2(px - 2.0, py - 2.0)
	_border.size = Vector2(PANEL_W + 4.0, panel_h + 4.0)
	_border.color = Color(0.50, 0.70, 1.00)
	_panel_node.add_child(_border)

	# Panel background
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(px, py)
	panel_bg.size = Vector2(PANEL_W, panel_h)
	panel_bg.color = Color(0.07, 0.09, 0.12, 1.0)
	_panel_node.add_child(panel_bg)

	# Title
	var title := Label.new()
	title.text = "Mission Complete!"
	title.position = Vector2(px, py + 8.0)
	title.size = Vector2(PANEL_W, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.40, 0.75, 1.00))
	_panel_node.add_child(title)

	# Header separator
	_add_separator(_panel_node, px, py + HEADER_H - 4.0, PANEL_W)

	# Column headers
	_add_label(_panel_node, "Material", px + 46.0, py + HEADER_H - ROW_H + 4.0,
			200.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
			HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(_panel_node, "Count", px + 260.0, py + HEADER_H - ROW_H + 4.0,
			90.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
			HORIZONTAL_ALIGNMENT_RIGHT)
	_add_label(_panel_node, "Value", px + 356.0, py + HEADER_H - ROW_H + 4.0,
			160.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
			HORIZONTAL_ALIGNMENT_RIGHT)

	# Ore rows
	var y := py + HEADER_H
	for i in rows.size():
		var tile_id: int = rows[i]
		var info: Dictionary = ORE_INFO[tile_id]
		var count: int = ore_counts.get(tile_id, 0)
		var earned: int = ore_earnings.get(tile_id, 0)

		var row_nodes: Array = []

		# Alternating row tint
		if i % 2 == 0:
			var row_bg := ColorRect.new()
			row_bg.position = Vector2(px, y)
			row_bg.size = Vector2(PANEL_W, ROW_H)
			row_bg.color = Color(1.0, 1.0, 1.0, 0.03)
			_panel_node.add_child(row_bg)
			row_nodes.append(row_bg)

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
				_panel_node.add_child(icon)
				row_nodes.append(icon)
			else:
				row_nodes.append(_add_colour_icon(_panel_node, px, y, info["color"]))
		else:
			row_nodes.append(_add_colour_icon(_panel_node, px, y, info["color"]))

		# Name
		row_nodes.append(_add_label(_panel_node, info["name"], px + 44.0, y, 220.0, ROW_H, 16,
				Color(0.92, 0.92, 0.92), HORIZONTAL_ALIGNMENT_LEFT))

		# Count
		row_nodes.append(_add_label(_panel_node, "x%d" % count, px + 260.0, y, 90.0, ROW_H, 16,
				Color(0.75, 0.75, 0.75), HORIZONTAL_ALIGNMENT_RIGHT))

		# Value earned (earned is in copper; format_coins converts to g)
		row_nodes.append(_add_label(_panel_node, "+%s" % GameManager.format_coins(earned), px + 356.0, y, 160.0, ROW_H, 16,
				Color(1.00, 0.88, 0.25), HORIZONTAL_ALIGNMENT_RIGHT))

		# Start invisible for stagger animation
		for node in row_nodes:
			node.modulate.a = 0.0

		_row_groups.append(row_nodes)
		y += ROW_H

	# Narrow Escape bonus line (if applicable)
	if _narrow_escape:
		_add_separator(_panel_node, px, y + 6.0, PANEL_W)
		y += 12.0
		var escape_lbl := _add_label(_panel_node, "Narrow Escape!  +%s" % GameManager.format_coins(_escape_bonus),
				px, y, PANEL_W, 30.0, 18, Color(1.0, 0.6, 0.1),
				HORIZONTAL_ALIGNMENT_CENTER)
		escape_lbl.modulate.a = 0.0
		_row_groups.append([escape_lbl])
		y += 30.0

	# Total separator + label
	_add_separator(_panel_node, px, y + 6.0, PANEL_W)

	_total_label = Label.new()
	_total_label.text = "Total:  0c"
	_total_label.position = Vector2(px, y + 10.0)
	_total_label.size = Vector2(PANEL_W, 40.0)
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_total_label.add_theme_font_size_override("font_size", 22)
	_total_label.add_theme_color_override("font_color", Color(1.00, 0.85, 0.10))
	_total_label.modulate.a = 0.0
	_panel_node.add_child(_total_label)

	# XP earned line
	_xp_label = Label.new()
	var xp_text: String = ""
	if _pending_xp > 0:
		xp_text = "+%d XP  (Lv. %d" % [_pending_xp, _level_before]
		if _pending_levels > 0:
			xp_text += " → Lv. %d  Level Up!" % (_level_before + _pending_levels)
		else:
			xp_text += ")"
	else:
		xp_text = "No minerals banked — no XP earned"
	_xp_label.text = xp_text
	_xp_label.position = Vector2(px, y + 50.0)
	_xp_label.size = Vector2(PANEL_W, 28.0)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 15)
	var xp_color := Color(0.45, 0.90, 0.55) if _pending_levels > 0 else Color(0.60, 0.80, 1.00)
	_xp_label.add_theme_color_override("font_color", xp_color)
	_xp_label.modulate.a = 0.0
	_panel_node.add_child(_xp_label)

	# Two buttons: Dive Again (left) + Return to Base (right)
	var btn_y := py + panel_h - 52.0
	var btn_w := 200.0
	var gap := 20.0
	var total_btns_w := btn_w * 2.0 + gap
	var btn_left_x := px + (PANEL_W - total_btns_w) / 2.0

	var btn_dive := Button.new()
	btn_dive.text = "Launch Again"
	btn_dive.position = Vector2(btn_left_x, btn_y)
	btn_dive.size = Vector2(btn_w, 40.0)
	btn_dive.pressed.connect(_on_dive_again_pressed)
	_panel_node.add_child(btn_dive)

	var btn_return := Button.new()
	btn_return.text = "Return to Station"
	btn_return.position = Vector2(btn_left_x + btn_w + gap, btn_y)
	btn_return.size = Vector2(btn_w, 40.0)
	btn_return.pressed.connect(_on_return_pressed)
	_panel_node.add_child(btn_return)

func _play_intro() -> void:
	# 1. Slide panel down and fade in
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_panel_node, "position:y", 0.0, 0.22) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel_node, "modulate:a", 1.0, 0.18)

	# 2. Settle border colour from bright flash to normal green
	var border_tween := create_tween()
	border_tween.tween_interval(0.12)
	border_tween.tween_property(_border, "color", Color(0.25, 0.45, 0.80), 0.4)

	# 3. Stagger ore rows in
	var row_delay := 0.22
	for i in _row_groups.size():
		for node in _row_groups[i]:
			var rt := create_tween()
			rt.tween_interval(row_delay + i * 0.055)
			rt.tween_property(node, "modulate:a", 1.0, 0.12)

	# 4. Count-up total after rows finish
	var count_delay := row_delay + _row_groups.size() * 0.055 + 0.12
	var count_tween := create_tween()
	count_tween.tween_interval(count_delay)
	count_tween.tween_property(_total_label, "modulate:a", 1.0, 0.1)
	if _final_total > 0:
		count_tween.tween_method(
			func(v: float) -> void:
				_total_label.text = "Total:  %s" % GameManager.format_coins(int(v)),
			0.0, float(_final_total), minf(0.6, float(_final_total) * 0.00002))
	else:
		_total_label.text = "Total:  0c"

	# 5. Fade in XP line shortly after total
	var xp_tween := create_tween()
	xp_tween.tween_interval(count_delay + 0.35)
	xp_tween.tween_property(_xp_label, "modulate:a", 1.0, 0.20)

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _add_separator(parent: Control, px: float, sep_y: float, width: float) -> void:
	var sep := ColorRect.new()
	sep.position = Vector2(px + 12.0, sep_y)
	sep.size = Vector2(width - 24.0, 2.0)
	sep.color = Color(0.25, 0.45, 0.80, 0.45)
	parent.add_child(sep)

func _add_colour_icon(parent: Control, px: float, row_y: float, color: Color) -> ColorRect:
	var icon := ColorRect.new()
	icon.position = Vector2(px + 10.0, row_y + (ROW_H - 26.0) / 2.0)
	icon.size = Vector2(26.0, 26.0)
	icon.color = color
	parent.add_child(icon)
	return icon

func _add_label(parent: Control, text: String, lx: float, ly: float,
		w: float, h: float, font_size: int, color: Color,
		h_align: HorizontalAlignment) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(lx, ly)
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = h_align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	parent.add_child(lbl)
	return lbl

func _on_return_pressed() -> void:
	GameManager.bank_currency()
	# Mark tier as completed if this was a mine or settlement run
	if GameManager.current_node_type == MapNode.NodeType.MINE:
		GameManager.mark_tier_completed(MapNode.NodeType.MINE)
	elif GameManager.current_node_type == MapNode.NodeType.SETTLEMENT:
		GameManager.mark_tier_completed(MapNode.NodeType.SETTLEMENT)
	queue_free()
	GameManager.load_overworld()

func _on_dive_again_pressed() -> void:
	GameManager.bank_currency()
	# Mark tier as completed if this was a mine or settlement run
	if GameManager.current_node_type == MapNode.NodeType.MINE:
		GameManager.mark_tier_completed(MapNode.NodeType.MINE)
	elif GameManager.current_node_type == MapNode.NodeType.SETTLEMENT:
		GameManager.mark_tier_completed(MapNode.NodeType.SETTLEMENT)
	queue_free()
	GameManager.load_mining_level()
