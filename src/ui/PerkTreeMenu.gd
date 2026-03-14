extends CanvasLayer

## Perk Tree Menu — dark space theme, pannable node graph.
## Perks are purchased with coins (minerals) via GameManager.purchase_perk().
## WASD pans the canvas. Right-click drag also pans.
## Hovering a perk node shows a tooltip above it.
## Square nodes are connected by lit/unlit lines based on unlock state.

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------

const SCREEN_W   : int   = 1280
const SCREEN_H   : int   = 720
const BOTTOM_H   : int   = 64          # bottom control bar height
const NODE_SIZE  : int   = 64          # perk square side length (px)
const COL_STRIDE : int   = 174         # horizontal distance between branch starts
const ROW_STRIDE : int   = 140         # vertical distance between tier starts
const HEADER_H   : int   = 26          # space above tier-0 for branch name labels
const LINE_W     : float = 3.0         # connector line width
const PAN_SPEED  : float = 280.0       # canvas pan speed via WASD (px/s)
const TIP_W      : int   = 218         # tooltip width
const TIP_HDR_H  : int   = 28          # tooltip header bar height
const TIP_BODY_H : int   = 90          # tooltip body height

# Colours
const COL_BG           := Color(0.06, 0.06, 0.10, 0.97)
const COL_NODE_LOCKED  := Color(0.14, 0.14, 0.18)
const COL_NODE_AVAIL   := Color(0.17, 0.19, 0.26)
const COL_NODE_CAN_BUY := Color(0.11, 0.20, 0.14)
const COL_NODE_MAXED   := Color(0.19, 0.15, 0.05)
const COL_BRD_LOCKED   := Color(0.27, 0.27, 0.32)
const COL_BRD_AVAIL    := Color(0.36, 0.42, 0.58)
const COL_BRD_CAN_BUY  := Color(0.30, 0.80, 0.37)
const COL_BRD_MAXED    := Color(0.80, 0.68, 0.14)
const COL_LINE         := Color(0.22, 0.22, 0.26)
const COL_LINE_LIT     := Color(0.36, 0.72, 0.42)
const COL_BOT_BG       := Color(0.04, 0.04, 0.08, 0.98)
const COL_BOT_BORDER   := Color(0.20, 0.20, 0.24)
const COL_TIP_BG       := Color(0.07, 0.09, 0.14, 0.98)
const COL_TIP_HDR      := Color(0.20, 0.47, 0.25, 1.00)
const COL_TIP_BORDER   := Color(0.30, 0.30, 0.36, 1.00)
const COL_TEXT         := Color(0.90, 0.87, 0.95)
const COL_TEXT_DIM     := Color(0.47, 0.47, 0.53)
const COL_TEXT_GOLD    := Color(1.00, 0.85, 0.18)
const COL_TEXT_GREEN   := Color(0.40, 0.88, 0.46)
const COL_TEXT_RED     := Color(0.80, 0.38, 0.33)

# ---------------------------------------------------------------------------
# ConnectorLayer — draws lines between vertically adjacent perk nodes
# ---------------------------------------------------------------------------

class ConnectorLayer extends Control:
	## Each entry: { "from": Vector2, "to": Vector2, "lit": bool }
	var lines: Array[Dictionary] = []

	func _draw() -> void:
		for ln: Dictionary in lines:
			var col: Color = COL_LINE_LIT if ln.get("lit", false) else COL_LINE
			draw_line(ln["from"], ln["to"], col, LINE_W, true)

# ---------------------------------------------------------------------------
# PerkNodeControl — individual perk square button
# ---------------------------------------------------------------------------

class PerkNodeControl extends Control:
	var perk_id  : String
	var menu_ref : Node

	var _border   : ColorRect
	var _bg       : ColorRect
	var _icon     : ColorRect
	var _lock_lbl : Label
	var _rank_lbl : Label

	func _init(p_id: String, ref: Node) -> void:
		perk_id  = p_id
		menu_ref = ref

	func setup() -> void:
		custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
		size                = Vector2(NODE_SIZE, NODE_SIZE)
		mouse_filter        = MOUSE_FILTER_STOP
		mouse_entered.connect(_mouse_entered)
		mouse_exited.connect(_mouse_exited)

		# Outer border
		_border = ColorRect.new()
		_border.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_border.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_border)

		# Inner background (2 px inset from border)
		_bg = ColorRect.new()
		_bg.position     = Vector2(2, 2)
		_bg.size         = Vector2(NODE_SIZE - 4, NODE_SIZE - 4)
		_bg.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_bg)

		# Icon colour swatch (centred, 26×26, shifted slightly up)
		var p := PerkSystem.get_perk(perk_id)
		_icon          = ColorRect.new()
		_icon.position = Vector2((NODE_SIZE - 26) / 2, (NODE_SIZE - 26) / 2 - 6)
		_icon.size     = Vector2(26, 26)
		_icon.color    = p.get("icon_color", Color.WHITE)
		_icon.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_icon)

		# Rank label at bottom
		_rank_lbl = Label.new()
		_rank_lbl.position = Vector2(2, NODE_SIZE - 17)
		_rank_lbl.size     = Vector2(NODE_SIZE - 4, 15)
		_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rank_lbl.add_theme_font_size_override("font_size", 9)
		_rank_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_rank_lbl)

		# Lock label — shown when prerequisites not met
		_lock_lbl = Label.new()
		_lock_lbl.text = "⚿"
		_lock_lbl.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		_lock_lbl.add_theme_font_size_override("font_size", 22)
		_lock_lbl.add_theme_color_override("font_color", Color(0.42, 0.42, 0.47))
		_lock_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_lock_lbl)

		refresh()

	func refresh() -> void:
		var p        := PerkSystem.get_perk(perk_id)
		var rank     : int  = GameManager.perk_ranks.get(perk_id, 0)
		var max_r    : int  = p.get("max_rank", 5)
		var unlocked : bool = PerkSystem.is_unlocked(perk_id, GameManager.perk_ranks)
		var can_buy  : bool = PerkSystem.can_purchase(perk_id, GameManager.perk_ranks, GameManager.coins)
		var maxed    : bool = rank >= max_r

		if maxed:
			_bg.color     = COL_NODE_MAXED
			_border.color = COL_BRD_MAXED
		elif can_buy:
			_bg.color     = COL_NODE_CAN_BUY
			_border.color = COL_BRD_CAN_BUY
		elif unlocked:
			_bg.color     = COL_NODE_AVAIL
			_border.color = COL_BRD_AVAIL
		else:
			_bg.color     = COL_NODE_LOCKED
			_border.color = COL_BRD_LOCKED

		_icon.visible  = unlocked
		_icon.modulate = Color(1, 1, 1, 1.0 if (maxed or can_buy) else 0.50)
		_lock_lbl.visible = not unlocked

		if maxed:
			_rank_lbl.text = "MAX"
			_rank_lbl.add_theme_color_override("font_color", COL_TEXT_GOLD)
		elif unlocked:
			_rank_lbl.text = "%d/%d" % [rank, max_r]
			_rank_lbl.add_theme_color_override("font_color",
				COL_TEXT_GREEN if can_buy else COL_TEXT_DIM)
		else:
			_rank_lbl.text = ""

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			if GameManager.purchase_perk(perk_id):
				menu_ref.refresh_all_nodes()
				menu_ref._show_tooltip(perk_id, global_position)

	func _mouse_entered() -> void:
		menu_ref._show_tooltip(perk_id, global_position)

	func _mouse_exited() -> void:
		menu_ref._hide_tooltip()

# ---------------------------------------------------------------------------
# Fields
# ---------------------------------------------------------------------------

var _root_panel    : ColorRect
var _tree_clip     : Control         # clips tree canvas to exclude bottom bar
var _canvas        : Control         # panning container
var _connector_lyr : ConnectorLayer

var _tip_panel     : ColorRect
var _tip_hdr_bg    : ColorRect
var _tip_name_lbl  : Label
var _tip_body_lbl  : Label
var _tip_cost_lbl  : Label

var _coins_label   : Label

## node_controls[perk_id] = PerkNodeControl
var _node_controls : Dictionary = {}

# Pan / drag state
var _drag_active       : bool    = false
var _drag_start_mouse  : Vector2 = Vector2.ZERO
var _drag_start_canvas : Vector2 = Vector2.ZERO
var _canvas_default    : Vector2 = Vector2.ZERO

var _built : bool = false

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_build_ui()
	hide()
	EventBus.player_leveled_up.connect(_on_leveled_up)
	EventBus.perk_points_changed.connect(_on_perk_points_changed)
	EventBus.coins_changed.connect(_on_coins_changed)

func _process(delta: float) -> void:
	if not visible:
		return
	var pan := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W):
		pan.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		pan.y += 1.0
	if Input.is_physical_key_pressed(KEY_A):
		pan.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		pan.x += 1.0
	if pan != Vector2.ZERO:
		_canvas.position += pan * PAN_SPEED * delta
		_clamp_canvas()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			if visible:
				_close()
			else:
				_open()
			get_viewport().set_input_as_handled()
		if visible and event.keycode == KEY_SPACE:
			_close()
			get_viewport().set_input_as_handled()
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	# Right-click drag to pan canvas
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_drag_active       = true
			_drag_start_mouse  = event.global_position
			_drag_start_canvas = _canvas.position
		else:
			_drag_active = false
	elif event is InputEventMouseMotion and _drag_active:
		_canvas.position = _drag_start_canvas + (event.global_position - _drag_start_mouse)
		_clamp_canvas()

# ---------------------------------------------------------------------------
# Open / Close
# ---------------------------------------------------------------------------

func _open() -> void:
	_canvas.position = _canvas_default
	_refresh_coins_label()
	refresh_all_nodes()
	show()

func _close() -> void:
	_hide_tooltip()
	_drag_active = false
	hide()

# ---------------------------------------------------------------------------
# UI Construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-screen dark overlay
	_root_panel = ColorRect.new()
	_root_panel.color = COL_BG
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root_panel)

	# Clipping region for the panning canvas (excludes bottom bar)
	_tree_clip = Control.new()
	_tree_clip.position      = Vector2(0, 0)
	_tree_clip.size          = Vector2(SCREEN_W, SCREEN_H - BOTTOM_H)
	_tree_clip.clip_contents = true
	_tree_clip.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(_tree_clip)

	# Panning canvas
	_canvas = Control.new()
	_canvas.size         = Vector2(2000, 2000)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tree_clip.add_child(_canvas)

	# Connector layer (drawn behind nodes)
	_connector_lyr = ConnectorLayer.new()
	_connector_lyr.size         = Vector2(2000, 2000)
	_connector_lyr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_connector_lyr)

	# Build branch labels + perk nodes inside canvas
	_build_canvas_nodes()

	# Bottom bar (built before tooltip so tooltip renders on top)
	_build_bottom_bar()

	# Tooltip (added last so it draws on top of everything)
	_build_tooltip()

	_built = true

func _build_canvas_nodes() -> void:
	# Compute canvas default position to centre tree in the usable area
	var tree_w         : int = 2 * COL_STRIDE + NODE_SIZE
	var canvas_h_need  : int = HEADER_H + ROW_STRIDE * 3 + NODE_SIZE
	_canvas_default = Vector2(
		(SCREEN_W - tree_w) / 2.0,
		(SCREEN_H - BOTTOM_H - canvas_h_need) / 2.0
	)
	_canvas.position = _canvas_default

	for b in range(3):
		var bx : int = b * COL_STRIDE

		# Branch column header label
		var hdr_lbl := Label.new()
		hdr_lbl.text                = PerkSystem.BRANCH_NAMES[b]
		hdr_lbl.position            = Vector2(bx, 0)
		hdr_lbl.custom_minimum_size = Vector2(NODE_SIZE, HEADER_H)
		hdr_lbl.size                = Vector2(NODE_SIZE, HEADER_H)
		hdr_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hdr_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		hdr_lbl.add_theme_font_size_override("font_size", 12)
		hdr_lbl.add_theme_color_override("font_color", PerkSystem.BRANCH_COLORS[b])
		hdr_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_canvas.add_child(hdr_lbl)

		# Perk nodes for this branch (tier 0 at top, tier 3 at bottom)
		var perks := PerkSystem.get_branch_perks(b)
		for i in range(perks.size()):
			var p    := perks[i]
			var p_id : String = p["id"]
			var nx   : int = bx
			var ny   : int = HEADER_H + i * ROW_STRIDE

			var node := PerkNodeControl.new(p_id, self)
			_canvas.add_child(node)
			node.setup()
			node.position = Vector2(nx, ny)
			_node_controls[p_id] = node

	_rebuild_connector_lines()

func _rebuild_connector_lines() -> void:
	_connector_lyr.lines.clear()
	for b in range(3):
		var perks := PerkSystem.get_branch_perks(b)
		for i in range(1, perks.size()):
			var top_id   : String = perks[i - 1]["id"]
			var bot_id   : String = perks[i]["id"]
			var top_node := _node_controls.get(top_id) as PerkNodeControl
			var bot_node := _node_controls.get(bot_id) as PerkNodeControl
			if top_node == null or bot_node == null:
				continue
			var from_pt := top_node.position + Vector2(NODE_SIZE / 2.0, NODE_SIZE)
			var to_pt   := bot_node.position + Vector2(NODE_SIZE / 2.0, 0.0)
			var lit     : bool = GameManager.perk_ranks.get(top_id, 0) > 0
			_connector_lyr.lines.append({"from": from_pt, "to": to_pt, "lit": lit})
	_connector_lyr.queue_redraw()

func _build_tooltip() -> void:
	var tip_h : int = TIP_HDR_H + TIP_BODY_H

	# Outer panel (border colour)
	_tip_panel = ColorRect.new()
	_tip_panel.color       = COL_TIP_BORDER
	_tip_panel.size        = Vector2(TIP_W, tip_h)
	_tip_panel.visible     = false
	_tip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(_tip_panel)

	# Inner background (1 px inset)
	var tip_inner := ColorRect.new()
	tip_inner.color       = COL_TIP_BG
	tip_inner.position    = Vector2(1, 1)
	tip_inner.size        = Vector2(TIP_W - 2, tip_h - 2)
	tip_inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(tip_inner)

	# Header bar (green)
	_tip_hdr_bg = ColorRect.new()
	_tip_hdr_bg.color       = COL_TIP_HDR
	_tip_hdr_bg.position    = Vector2(1, 1)
	_tip_hdr_bg.size        = Vector2(TIP_W - 2, TIP_HDR_H - 1)
	_tip_hdr_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(_tip_hdr_bg)

	# Perk name (in header)
	_tip_name_lbl = Label.new()
	_tip_name_lbl.position = Vector2(7, 5)
	_tip_name_lbl.size     = Vector2(TIP_W - 14, TIP_HDR_H - 6)
	_tip_name_lbl.add_theme_font_size_override("font_size", 13)
	_tip_name_lbl.add_theme_color_override("font_color", COL_TEXT)
	_tip_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(_tip_name_lbl)

	# Description + rank body
	_tip_body_lbl = Label.new()
	_tip_body_lbl.position    = Vector2(7, TIP_HDR_H + 7)
	_tip_body_lbl.size        = Vector2(TIP_W - 14, TIP_BODY_H - 28)
	_tip_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_body_lbl.add_theme_font_size_override("font_size", 11)
	_tip_body_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	_tip_body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(_tip_body_lbl)

	# Cost / status at bottom of tooltip
	_tip_cost_lbl = Label.new()
	_tip_cost_lbl.position = Vector2(7, TIP_HDR_H + TIP_BODY_H - 20)
	_tip_cost_lbl.size     = Vector2(TIP_W - 14, 18)
	_tip_cost_lbl.add_theme_font_size_override("font_size", 13)
	_tip_cost_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip_panel.add_child(_tip_cost_lbl)

func _build_bottom_bar() -> void:
	# Background
	var bar := ColorRect.new()
	bar.color        = COL_BOT_BG
	bar.position     = Vector2(0, SCREEN_H - BOTTOM_H)
	bar.size         = Vector2(SCREEN_W, BOTTOM_H)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(bar)

	# Top border line
	var border_line := ColorRect.new()
	border_line.color        = COL_BOT_BORDER
	border_line.position     = Vector2(0, SCREEN_H - BOTTOM_H)
	border_line.size         = Vector2(SCREEN_W, 1)
	border_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(border_line)

	# Control hints — left side
	var hints : Array[Array] = [
		["[W A S D]", "Pan Tree"],
		["[Right Drag]", "Drag Tree"],
		["[Click]", "Buy Upgrade"],
	]
	var hx : int = 18
	for hint: Array in hints:
		var key_lbl := Label.new()
		key_lbl.text        = hint[0] as String
		key_lbl.position    = Vector2(hx, SCREEN_H - BOTTOM_H + 8)
		key_lbl.add_theme_font_size_override("font_size", 11)
		key_lbl.add_theme_color_override("font_color", COL_TEXT)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root_panel.add_child(key_lbl)

		var act_lbl := Label.new()
		act_lbl.text        = hint[1] as String
		act_lbl.position    = Vector2(hx, SCREEN_H - BOTTOM_H + 26)
		act_lbl.add_theme_font_size_override("font_size", 11)
		act_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
		act_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_root_panel.add_child(act_lbl)

		hx += 118

	# Coin balance — centred
	_coins_label = Label.new()
	_coins_label.position             = Vector2(SCREEN_W / 2 - 90, SCREEN_H - BOTTOM_H + 12)
	_coins_label.custom_minimum_size  = Vector2(180, 40)
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_coins_label.add_theme_font_size_override("font_size", 26)
	_coins_label.add_theme_color_override("font_color", COL_TEXT_GREEN)
	_coins_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(_coins_label)

	# [SPACE] hint to the left of the Continue button
	var space_lbl := Label.new()
	space_lbl.text        = "[SPACE]"
	space_lbl.position    = Vector2(SCREEN_W - 230, SCREEN_H - BOTTOM_H + 22)
	space_lbl.add_theme_font_size_override("font_size", 11)
	space_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	space_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(space_lbl)

	# Continue button — right side
	var cont_btn := Button.new()
	cont_btn.text                = "Continue"
	cont_btn.position            = Vector2(SCREEN_W - 190, SCREEN_H - BOTTOM_H + 8)
	cont_btn.custom_minimum_size = Vector2(176, BOTTOM_H - 16)
	cont_btn.add_theme_font_size_override("font_size", 18)
	cont_btn.pressed.connect(_close)
	_root_panel.add_child(cont_btn)

	_refresh_coins_label()

# ---------------------------------------------------------------------------
# Tooltip helpers
# ---------------------------------------------------------------------------

func _show_tooltip(perk_id: String, node_global_pos: Vector2) -> void:
	var p := PerkSystem.get_perk(perk_id)
	if p.is_empty():
		return

	var rank     : int  = GameManager.perk_ranks.get(perk_id, 0)
	var max_r    : int  = p.get("max_rank", 5)
	var unlocked : bool = PerkSystem.is_unlocked(perk_id, GameManager.perk_ranks)
	var can_buy  : bool = PerkSystem.can_purchase(perk_id, GameManager.perk_ranks, GameManager.coins)
	var maxed    : bool = rank >= max_r
	var cost     : int  = p.get("mineral_cost", 0)

	_tip_name_lbl.text = (p.get("name", "") as String).to_upper()

	var body : String = p.get("desc", "")
	body += "\nRank: %d / %d" % [rank, max_r]
	_tip_body_lbl.text = body

	if maxed:
		_tip_cost_lbl.text = "MAXED"
		_tip_cost_lbl.add_theme_color_override("font_color", COL_TEXT_GOLD)
	elif not unlocked:
		var prereq_id  : String = p.get("prereq_id", "")
		var prereq_perk := PerkSystem.get_perk(prereq_id)
		_tip_cost_lbl.text = "Locked — needs %s rank %d" % [
			prereq_perk.get("name", prereq_id),
			p.get("prereq_rank", 1)
		]
		_tip_cost_lbl.add_theme_color_override("font_color", COL_TEXT_DIM)
	elif not can_buy:
		_tip_cost_lbl.text = "Cost: %s  (need more)" % GameManager.format_coins(cost)
		_tip_cost_lbl.add_theme_color_override("font_color", COL_TEXT_RED)
	else:
		_tip_cost_lbl.text = "Cost: %s" % GameManager.format_coins(cost)
		_tip_cost_lbl.add_theme_color_override("font_color", COL_TEXT_GREEN)

	# Position above node; flip below if too close to top edge
	var tip_h   : int   = TIP_HDR_H + TIP_BODY_H
	var tip_x   : float = node_global_pos.x + NODE_SIZE / 2.0 - TIP_W / 2.0
	var tip_y   : float = node_global_pos.y - tip_h - 10.0
	if tip_y < 6.0:
		tip_y = node_global_pos.y + NODE_SIZE + 10.0
	tip_x = clampf(tip_x, 6.0, SCREEN_W - TIP_W - 6.0)
	tip_y = clampf(tip_y, 6.0, SCREEN_H - BOTTOM_H - tip_h - 6.0)

	_tip_panel.position = Vector2(tip_x, tip_y)
	_tip_panel.visible  = true

func _hide_tooltip() -> void:
	_tip_panel.visible = false

# ---------------------------------------------------------------------------
# Refresh helpers
# ---------------------------------------------------------------------------

func refresh_all_nodes() -> void:
	for ctrl: PerkNodeControl in _node_controls.values():
		ctrl.refresh()
	_rebuild_connector_lines()
	_refresh_coins_label()

func _refresh_coins_label() -> void:
	if _coins_label != null:
		_coins_label.text = GameManager.format_coins(GameManager.coins)

func _clamp_canvas() -> void:
	# Allow panning up to 300 px away from the default centred position
	var margin : float = 300.0
	_canvas.position.x = clampf(
		_canvas.position.x,
		_canvas_default.x - margin,
		_canvas_default.x + margin
	)
	_canvas.position.y = clampf(
		_canvas.position.y,
		_canvas_default.y - margin,
		_canvas_default.y + margin
	)

# ---------------------------------------------------------------------------
# EventBus callbacks
# ---------------------------------------------------------------------------

func _on_leveled_up(_new_level: int, _pts: int) -> void:
	if visible:
		refresh_all_nodes()

func _on_perk_points_changed(_pts: int) -> void:
	if visible:
		refresh_all_nodes()

func _on_coins_changed(_copper: int) -> void:
	if visible:
		_refresh_coins_label()
		refresh_all_nodes()
