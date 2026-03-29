class_name FailureSummary
extends CanvasLayer

## Shown on death or energy depletion — recaps what was collected and lost,
## with a contextual tip so the player learns from the failure.

const ORE_INFO: Dictionary = RunSummary.ORE_INFO
const DISPLAY_ORDER: Array = RunSummary.DISPLAY_ORDER

const VW := 1280.0
const VH := 720.0
const PANEL_W := 540.0
const ROW_H := 38.0
const HEADER_H := 68.0
const FOOTER_H := 130.0

var _failure_reason: String = ""
var _lost_coins: int = 0
var _ore_counts: Dictionary = {}
var _ore_earnings: Dictionary = {}
var _panel_node: Control = null
var _row_groups: Array = []
var _total_label: Label = null
var _border: ColorRect = null

var _tips_energy: Array[String] = [
	"Watch the energy bar — surface before it runs out!",
	"Energy drains faster the deeper you dig.",
	"Energy nodes restore 10 energy — look for glowing tiles.",
	"The reenergy station at the surface can refill your energy.",
	"Short, safe runs are better than losing everything!",
]

var _tips_death: Array[String] = [
	"Upgrade your Pelt at the Clowder to survive longer.",
	"Explosive tiles flash before detonating — move away quickly!",
	"Avoid lava tiles — they burn on contact.",
	"Watch for boss encounters at deep milestones.",
	"Health is precious — mine carefully near hazards.",
]

func setup(reason: String) -> void:
	_failure_reason = reason
	_lost_coins = GameManager.run_coins
	_ore_counts = GameManager.run_ore_counts.duplicate()
	_ore_earnings = GameManager.run_ore_earnings.duplicate()

func _ready() -> void:
	if _lost_coins == 0 and _ore_counts.is_empty():
		# Capture data if setup() wasn't called (safety fallback)
		_lost_coins = GameManager.run_coins
		_ore_counts = GameManager.run_ore_counts.duplicate()
		_ore_earnings = GameManager.run_ore_earnings.duplicate()
	_build_ui()
	_play_intro()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	# Dark overlay
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.0)
	root.add_child(dim)
	var dim_tween := create_tween()
	dim_tween.tween_property(dim, "color:a", 0.85, 0.3)

	# Panel container
	_panel_node = Control.new()
	_panel_node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_node.position = Vector2(0.0, -60.0)
	_panel_node.modulate.a = 0.0
	root.add_child(_panel_node)

	# Determine rows
	var rows: Array = []
	for tile_id in DISPLAY_ORDER:
		if _ore_counts.get(tile_id, 0) > 0:
			rows.append(tile_id)

	# Panel height
	var tip_h := 50.0
	var panel_h := HEADER_H + rows.size() * ROW_H + FOOTER_H + tip_h
	panel_h = maxf(panel_h, 300.0)
	var px := (VW - PANEL_W) / 2.0
	var py := (VH - panel_h) / 2.0

	# Border (red-tinted for failure)
	_border = ColorRect.new()
	_border.position = Vector2(px - 2.0, py - 2.0)
	_border.size = Vector2(PANEL_W + 4.0, panel_h + 4.0)
	_border.color = Color(0.90, 0.30, 0.20)
	_panel_node.add_child(_border)

	# Panel background
	var panel_bg := ColorRect.new()
	panel_bg.position = Vector2(px, py)
	panel_bg.size = Vector2(PANEL_W, panel_h)
	panel_bg.color = Color(0.10, 0.06, 0.06, 1.0)
	_panel_node.add_child(panel_bg)

	# Title
	var title_text := "OUT OF ENERGY" if _failure_reason == "energy" else "LOST IN SPACE"
	var title := Label.new()
	title.text = title_text
	title.position = Vector2(px, py + 8.0)
	title.size = Vector2(PANEL_W, 44.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15))
	_panel_node.add_child(title)

	# Header separator
	_add_separator(_panel_node, px, py + HEADER_H - 4.0, PANEL_W)

	if rows.size() > 0:
		# Column headers
		_add_label(_panel_node, "Material", px + 46.0, py + HEADER_H - ROW_H + 4.0,
				200.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
				HORIZONTAL_ALIGNMENT_LEFT)
		_add_label(_panel_node, "Count", px + 260.0, py + HEADER_H - ROW_H + 4.0,
				90.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
				HORIZONTAL_ALIGNMENT_RIGHT)
		_add_label(_panel_node, "Lost", px + 356.0, py + HEADER_H - ROW_H + 4.0,
				160.0, ROW_H - 6.0, 13, Color(0.55, 0.55, 0.55),
				HORIZONTAL_ALIGNMENT_RIGHT)

	# Ore rows
	var y := py + HEADER_H
	for i in rows.size():
		var tile_id: int = rows[i]
		var info: Dictionary = ORE_INFO[tile_id]
		var count: int = _ore_counts.get(tile_id, 0)
		var earned: int = _ore_earnings.get(tile_id, 0)

		var row_nodes: Array = []

		# Alternating row tint
		if i % 2 == 0:
			var row_bg := ColorRect.new()
			row_bg.position = Vector2(px, y)
			row_bg.size = Vector2(PANEL_W, ROW_H)
			row_bg.color = Color(1.0, 1.0, 1.0, 0.03)
			_panel_node.add_child(row_bg)
			row_nodes.append(row_bg)

		# Icon
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
				Color(0.70, 0.70, 0.70), HORIZONTAL_ALIGNMENT_LEFT))

		# Count
		row_nodes.append(_add_label(_panel_node, "x%d" % count, px + 260.0, y, 90.0, ROW_H, 16,
				Color(0.60, 0.60, 0.60), HORIZONTAL_ALIGNMENT_RIGHT))

		# Lost coins (shown in red with strikethrough effect)
		row_nodes.append(_add_label(_panel_node, "-%s" % GameManager.format_coins(earned), px + 356.0, y, 160.0, ROW_H, 16,
				Color(1.0, 0.35, 0.25), HORIZONTAL_ALIGNMENT_RIGHT))

		for node in row_nodes:
			node.modulate.a = 0.0
		_row_groups.append(row_nodes)
		y += ROW_H

	# Total separator + label
	_add_separator(_panel_node, px, y + 6.0, PANEL_W)

	_total_label = Label.new()
	if _lost_coins > 0:
		_total_label.text = "Lost:  %s" % GameManager.format_coins(_lost_coins)
	else:
		_total_label.text = "Nothing collected"
	_total_label.position = Vector2(px, y + 10.0)
	_total_label.size = Vector2(PANEL_W, 36.0)
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_total_label.add_theme_font_size_override("font_size", 20)
	_total_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	_total_label.modulate.a = 0.0
	_panel_node.add_child(_total_label)

	# Tip label
	var tip_pool := _tips_energy if _failure_reason == "energy" else _tips_death
	var tip_text := tip_pool[randi() % tip_pool.size()]
	var tip_label := Label.new()
	tip_label.text = tip_text
	tip_label.position = Vector2(px + 20.0, y + 48.0)
	tip_label.size = Vector2(PANEL_W - 40.0, 40.0)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.70, 0.80, 0.95))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_node.add_child(tip_label)

	# Return button
	var btn_y := py + panel_h - 52.0
	var btn_w := 220.0
	var btn_x := px + (PANEL_W - btn_w) / 2.0

	var btn_return := Button.new()
	btn_return.text = "Return to Station"
	btn_return.position = Vector2(btn_x, btn_y)
	btn_return.size = Vector2(btn_w, 40.0)
	btn_return.pressed.connect(_on_return_pressed)
	_panel_node.add_child(btn_return)

func _play_intro() -> void:
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(_panel_node, "position:y", 0.0, 0.25) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(_panel_node, "modulate:a", 1.0, 0.2)

	# Settle border
	var border_tween := create_tween()
	border_tween.tween_interval(0.15)
	border_tween.tween_property(_border, "color", Color(0.60, 0.15, 0.10), 0.4)

	# Stagger rows
	var row_delay := 0.25
	for i in _row_groups.size():
		for node in _row_groups[i]:
			var rt := create_tween()
			rt.tween_interval(row_delay + i * 0.055)
			rt.tween_property(node, "modulate:a", 1.0, 0.12)

	# Fade total
	var total_delay := row_delay + _row_groups.size() * 0.055 + 0.12
	var total_tween := create_tween()
	total_tween.tween_interval(total_delay)
	total_tween.tween_property(_total_label, "modulate:a", 1.0, 0.15)

# ---------------------------------------------------------------------------
# Helpers (same pattern as RunSummary)
# ---------------------------------------------------------------------------

func _add_separator(parent: Control, px: float, sep_y: float, width: float) -> void:
	UIHelper.create_separator(parent, px, sep_y, width)

func _add_colour_icon(parent: Control, px: float, row_y: float, color: Color) -> ColorRect:
	return UIHelper.create_colour_icon(parent, px, row_y, color)

func _add_label(parent: Control, text: String, lx: float, ly: float,
		w: float, h: float, font_size: int, color: Color,
		h_align: HorizontalAlignment) -> Label:
	return UIHelper.create_label(parent, text, lx, ly, w, h, font_size, color, h_align)

func _on_return_pressed() -> void:
	queue_free()
	GameManager.lose_run()
