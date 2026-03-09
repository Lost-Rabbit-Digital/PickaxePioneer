extends CanvasLayer

## Perk Tree Menu — Diablo-2-style skill tree overlay.
## Registered as an autoload so it is accessible via the P key from any scene.
## Three vertical branch columns connected by drawn lines, mimicking COAL LLC /
## Diablo 2 layout.  Each node shows icon, name, rank/max, and description on
## hover.  Perk points are spent by clicking an available node.

# ---------------------------------------------------------------------------
# Layout constants
# ---------------------------------------------------------------------------

const SCREEN_W : int = 1280
const SCREEN_H : int = 720

const NODE_SIZE     : int = 88   # perk icon square (px)
const NODE_GAP      : int = 56   # vertical gap between tier rows
const BRANCH_GAP    : int = 80   # horizontal gap between branch columns
const CONNECTOR_W   : int = 4    # connector line width (px)

# Colours
const COL_BG        : Color = Color(0.03, 0.03, 0.08, 0.95)
const COL_HEADER_BG : Color = Color(0.06, 0.04, 0.14, 1.00)
const COL_BORDER    : Color = Color(0.45, 0.30, 0.70, 1.00)
const COL_LOCKED    : Color = Color(0.18, 0.18, 0.22, 1.00)
const COL_AVAILABLE : Color = Color(0.25, 0.25, 0.30, 1.00)
const COL_MAXED     : Color = Color(0.80, 0.70, 0.10, 1.00)
const COL_TEXT_DIM  : Color = Color(0.50, 0.50, 0.55, 1.00)
const COL_TEXT      : Color = Color(0.92, 0.88, 1.00, 1.00)
const COL_TEXT_GOLD : Color = Color(1.00, 0.88, 0.20, 1.00)
const COL_CONNECTOR : Color = Color(0.40, 0.30, 0.60, 1.00)
const COL_CONN_LIT  : Color = Color(0.70, 0.55, 1.00, 1.00)

# ---------------------------------------------------------------------------
# Inner class — single perk node button
# ---------------------------------------------------------------------------

class PerkNodeControl extends Control:
	var perk_id  : String
	var menu_ref : Node   # back-ref to PerkTreeMenu for spending points

	var _bg         : ColorRect
	var _icon       : ColorRect
	var _name_lbl   : Label
	var _rank_lbl   : Label
	var _locked_ovl : ColorRect  # grey overlay when locked

	func _init(p_id: String, ref: Node) -> void:
		perk_id  = p_id
		menu_ref = ref

	func setup() -> void:
		custom_minimum_size = Vector2(NODE_SIZE, NODE_SIZE)
		mouse_filter = MOUSE_FILTER_STOP

		# Outer border
		var border := ColorRect.new()
		border.color = Color(0.50, 0.38, 0.75, 1.00)
		border.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		border.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(border)

		# Background fill
		_bg = ColorRect.new()
		_bg.color = COL_AVAILABLE
		_bg.position = Vector2(2, 2)
		_bg.size = Vector2(NODE_SIZE - 4, NODE_SIZE - 4)
		_bg.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_bg)

		# Icon colour swatch (top half)
		var p := PerkSystem.get_perk(perk_id)
		_icon = ColorRect.new()
		_icon.color = p.get("icon_color", Color.WHITE)
		_icon.position = Vector2((NODE_SIZE - 40) / 2, 6)
		_icon.size = Vector2(40, 40)
		_icon.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_icon)

		# Perk name label
		_name_lbl = Label.new()
		_name_lbl.text = p.get("name", "?")
		_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_lbl.position = Vector2(2, 50)
		_name_lbl.size = Vector2(NODE_SIZE - 4, 18)
		_name_lbl.add_theme_font_size_override("font_size", 11)
		_name_lbl.add_theme_color_override("font_color", COL_TEXT)
		_name_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_name_lbl)

		# Rank label (e.g. "2/5")
		_rank_lbl = Label.new()
		_rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_rank_lbl.position = Vector2(2, 66)
		_rank_lbl.size = Vector2(NODE_SIZE - 4, 16)
		_rank_lbl.add_theme_font_size_override("font_size", 10)
		_rank_lbl.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_rank_lbl)

		# Locked overlay (drawn last so it covers everything)
		_locked_ovl = ColorRect.new()
		_locked_ovl.color = Color(0.0, 0.0, 0.0, 0.68)
		_locked_ovl.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		_locked_ovl.mouse_filter = MOUSE_FILTER_IGNORE
		add_child(_locked_ovl)

		refresh()

	func refresh() -> void:
		var p    := PerkSystem.get_perk(perk_id)
		var rank : int = GameManager.perk_ranks.get(perk_id, 0)
		var max_r: int = p.get("max_rank", 5)
		var unlocked := PerkSystem.is_unlocked(perk_id, GameManager.perk_ranks)
		var can_up   := PerkSystem.can_rank_up(perk_id, GameManager.perk_ranks, GameManager.perk_points)
		var maxed    := rank >= max_r

		# Background colour encodes state
		if maxed:
			_bg.color = Color(0.15, 0.13, 0.06)
		elif can_up:
			_bg.color = Color(0.10, 0.14, 0.18)
		elif unlocked:
			_bg.color = Color(0.08, 0.08, 0.12)
		else:
			_bg.color = COL_LOCKED

		# Icon brightness
		_icon.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.4, 0.4, 0.4, 1)

		# Border colour
		var border_col: Color
		if maxed:
			border_col = COL_MAXED
		elif can_up:
			border_col = Color(0.55, 0.90, 0.55, 1.00)
		elif unlocked:
			border_col = COL_BORDER
		else:
			border_col = Color(0.25, 0.22, 0.30, 1.00)
		get_child(0).color = border_col  # border rect

		# Rank label colour and text
		var rank_col: Color = COL_TEXT_GOLD if maxed else (Color(0.60, 1.00, 0.60) if can_up else COL_TEXT_DIM)
		_rank_lbl.add_theme_color_override("font_color", rank_col)
		_rank_lbl.text = "%d / %d" % [rank, max_r]

		_locked_ovl.visible = not unlocked

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if GameManager.spend_perk_point(perk_id):
				menu_ref.refresh_all_nodes()
				menu_ref._update_info_panel(perk_id)

	func _mouse_entered() -> void:
		menu_ref._update_info_panel(perk_id)

# ---------------------------------------------------------------------------
# PerkTreeMenu fields
# ---------------------------------------------------------------------------

var _root_panel   : ColorRect
var _points_label : Label
var _level_label  : Label
var _xp_fill      : ColorRect
var _xp_label     : Label
var _info_name    : Label
var _info_desc    : Label
var _info_stats   : Label

# node_controls[perk_id] = PerkNodeControl
var _node_controls : Dictionary = {}
# Connector ColorRects keyed by "from_id:to_id"
var _connectors    : Dictionary = {}

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
	EventBus.xp_changed.connect(_on_xp_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_P:
			if visible:
				_close()
			else:
				_open()
			get_viewport().set_input_as_handled()
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Open / Close
# ---------------------------------------------------------------------------

func _open() -> void:
	_refresh_header()
	refresh_all_nodes()
	show()

func _close() -> void:
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

	# Header bar
	var header := ColorRect.new()
	header.color = COL_HEADER_BG
	header.position = Vector2(0, 0)
	header.size = Vector2(SCREEN_W, 52)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(header)

	# Title
	var title := Label.new()
	title.text = "PERK TREE"
	title.position = Vector2(SCREEN_W / 2 - 120, 8)
	title.custom_minimum_size = Vector2(240, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.80, 0.60, 1.00))
	_root_panel.add_child(title)

	# Level label (left side of header)
	_level_label = Label.new()
	_level_label.position = Vector2(16, 10)
	_level_label.custom_minimum_size = Vector2(200, 32)
	_level_label.add_theme_font_size_override("font_size", 18)
	_level_label.add_theme_color_override("font_color", COL_TEXT_GOLD)
	_root_panel.add_child(_level_label)

	# Points label (right side of header)
	_points_label = Label.new()
	_points_label.position = Vector2(SCREEN_W - 280, 10)
	_points_label.custom_minimum_size = Vector2(264, 32)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_points_label.add_theme_font_size_override("font_size", 18)
	_points_label.add_theme_color_override("font_color", Color(0.50, 1.00, 0.55))
	_root_panel.add_child(_points_label)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "Close  [P]"
	close_btn.position = Vector2(SCREEN_W - 140, 8)
	close_btn.custom_minimum_size = Vector2(132, 36)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_close)
	_root_panel.add_child(close_btn)

	# XP bar background
	var xp_bg := ColorRect.new()
	xp_bg.color = Color(0.10, 0.08, 0.20, 1.00)
	xp_bg.position = Vector2(16, 36)
	xp_bg.size = Vector2(SCREEN_W - 32, 12)
	xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(xp_bg)

	_xp_fill = ColorRect.new()
	_xp_fill.color = Color(0.45, 0.25, 0.90, 1.00)
	_xp_fill.position = Vector2(16, 36)
	_xp_fill.size = Vector2(0, 12)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(_xp_fill)

	_xp_label = Label.new()
	_xp_label.position = Vector2(SCREEN_W / 2 - 100, 34)
	_xp_label.custom_minimum_size = Vector2(200, 14)
	_xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_xp_label.add_theme_font_size_override("font_size", 10)
	_xp_label.add_theme_color_override("font_color", Color(0.80, 0.70, 1.00))
	_root_panel.add_child(_xp_label)

	# Branch column headers + perk nodes
	var num_branches  : int = 3
	var branch_width  : int = NODE_SIZE
	var total_tree_w  : int = num_branches * branch_width + (num_branches - 1) * BRANCH_GAP
	var tree_x_start  : int = (SCREEN_W - total_tree_w) / 2
	var tree_y_start  : int = 68

	for b in range(num_branches):
		var bx : int = tree_x_start + b * (branch_width + BRANCH_GAP)

		# Branch name header
		var branch_lbl := Label.new()
		branch_lbl.text = PerkSystem.BRANCH_NAMES[b]
		branch_lbl.position = Vector2(bx, tree_y_start)
		branch_lbl.custom_minimum_size = Vector2(branch_width, 24)
		branch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		branch_lbl.add_theme_font_size_override("font_size", 14)
		branch_lbl.add_theme_color_override("font_color", PerkSystem.BRANCH_COLORS[b])
		_root_panel.add_child(branch_lbl)

		# Build perk nodes for this branch
		var perks_in_branch := PerkSystem.get_branch_perks(b)
		var prev_node_bottom : int = tree_y_start + 28  # y just below the branch header
		var prev_node_mid_x  : int = bx + NODE_SIZE / 2

		for i in range(perks_in_branch.size()):
			var p    := perks_in_branch[i]
			var p_id : String = p["id"]
			var ny   : int = prev_node_bottom + (NODE_GAP if i > 0 else 4)

			# Draw connector line between tiers (vertical bar)
			if i > 0:
				var conn_key := "%s:%s" % [perks_in_branch[i - 1]["id"], p_id]
				var conn := ColorRect.new()
				conn.color = COL_CONNECTOR
				var conn_top    : int = prev_node_bottom
				var conn_bottom : int = ny
				conn.position = Vector2(prev_node_mid_x - CONNECTOR_W / 2, conn_top)
				conn.size = Vector2(CONNECTOR_W, conn_bottom - conn_top)
				conn.mouse_filter = Control.MOUSE_FILTER_IGNORE
				_root_panel.add_child(conn)
				_connectors[conn_key] = conn

			# Perk node
			var node := PerkNodeControl.new(p_id, self)
			_root_panel.add_child(node)
			node.setup()
			node.position = Vector2(bx, ny)
			_node_controls[p_id] = node

			prev_node_bottom = ny + NODE_SIZE
			prev_node_mid_x  = bx + NODE_SIZE / 2

	# Info panel at the bottom
	var info_bg := ColorRect.new()
	info_bg.color = Color(0.04, 0.03, 0.10, 0.96)
	info_bg.position = Vector2(0, SCREEN_H - 96)
	info_bg.size = Vector2(SCREEN_W, 96)
	info_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(info_bg)

	var info_border := ColorRect.new()
	info_border.color = COL_BORDER
	info_border.position = Vector2(0, SCREEN_H - 96)
	info_border.size = Vector2(SCREEN_W, 2)
	info_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root_panel.add_child(info_border)

	_info_name = Label.new()
	_info_name.position = Vector2(20, SCREEN_H - 90)
	_info_name.custom_minimum_size = Vector2(400, 24)
	_info_name.add_theme_font_size_override("font_size", 18)
	_info_name.add_theme_color_override("font_color", COL_TEXT_GOLD)
	_root_panel.add_child(_info_name)

	_info_desc = Label.new()
	_info_desc.position = Vector2(20, SCREEN_H - 66)
	_info_desc.custom_minimum_size = Vector2(900, 22)
	_info_desc.add_theme_font_size_override("font_size", 14)
	_info_desc.add_theme_color_override("font_color", COL_TEXT)
	_root_panel.add_child(_info_desc)

	_info_stats = Label.new()
	_info_stats.position = Vector2(20, SCREEN_H - 44)
	_info_stats.custom_minimum_size = Vector2(900, 22)
	_info_stats.add_theme_font_size_override("font_size", 13)
	_info_stats.add_theme_color_override("font_color", Color(0.65, 0.85, 0.65))
	_root_panel.add_child(_info_stats)

	# Default info text
	_info_name.text = "Hover a perk to see details"
	_info_desc.text = "Spend perk points to unlock and upgrade perks.  Press P to close."
	_info_stats.text = "You gain 1 perk point each time you level up.  Mine blocks and defeat bosses to earn XP."

	_built = true
	_refresh_header()

# ---------------------------------------------------------------------------
# Refresh helpers
# ---------------------------------------------------------------------------

func refresh_all_nodes() -> void:
	for ctrl: PerkNodeControl in _node_controls.values():
		ctrl.refresh()
	_refresh_connectors()
	_refresh_header()

func _refresh_header() -> void:
	_level_label.text = "Lv. %d" % GameManager.player_level
	var pts : int = GameManager.perk_points
	_points_label.text = "%d Perk Point%s" % [pts, "s" if pts != 1 else ""]
	_points_label.add_theme_color_override("font_color",
		Color(0.50, 1.00, 0.55) if pts > 0 else COL_TEXT_DIM)
	# XP bar
	var xp       : int   = GameManager.player_xp
	var xp_max   : int   = PerkSystem.xp_for_next_level(GameManager.player_level)
	var bar_w    : float = float(SCREEN_W - 32) * float(xp) / float(maxi(1, xp_max))
	_xp_fill.size.x = bar_w
	_xp_label.text = "XP  %d / %d" % [xp, xp_max]

func _refresh_connectors() -> void:
	for key: String in _connectors.keys():
		var parts  := key.split(":")
		var top_id := parts[0]
		var bot_id := parts[1]
		var rank   : int = GameManager.perk_ranks.get(top_id, 0)
		_connectors[key].color = COL_CONN_LIT if rank > 0 else COL_CONNECTOR

func _update_info_panel(perk_id: String) -> void:
	var p    := PerkSystem.get_perk(perk_id)
	if p.is_empty():
		return
	var rank : int = GameManager.perk_ranks.get(perk_id, 0)
	var max_r: int = p.get("max_rank", 5)
	_info_name.text = "%s  [%d / %d]" % [p.get("name", ""), rank, max_r]
	_info_desc.text = p.get("desc", "")

	var prereq_id : String = p.get("prereq_id", "")
	var status_str : String
	if rank >= max_r:
		status_str = "MAXED"
	elif PerkSystem.can_rank_up(perk_id, GameManager.perk_ranks, GameManager.perk_points):
		status_str = "Click to upgrade  (costs 1 point)"
	elif not PerkSystem.is_unlocked(perk_id, GameManager.perk_ranks):
		var prereq_perk := PerkSystem.get_perk(prereq_id)
		status_str = "Locked — requires %s rank %d" % [prereq_perk.get("name", prereq_id), p.get("prereq_rank", 1)]
	else:
		status_str = "No perk points available"
	_info_stats.text = status_str

# ---------------------------------------------------------------------------
# EventBus callbacks
# ---------------------------------------------------------------------------

func _on_leveled_up(_new_level: int, _pts: int) -> void:
	if visible:
		refresh_all_nodes()

func _on_perk_points_changed(_pts: int) -> void:
	if visible:
		refresh_all_nodes()

func _on_xp_changed(_xp: int, _xp_next: int) -> void:
	if visible:
		_refresh_header()
