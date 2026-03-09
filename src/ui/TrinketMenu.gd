class_name TrinketMenu
extends CanvasLayer

# Trinket Menu — toggle with G key during a mining run.
# Displays all available trinkets in a 2-column compact list.
# Each trinket can be independently equipped or unequipped.
# Equip state persists via GameManager booleans and saved to disk.

const PANEL_W: int = 720
const PANEL_H: int = 488

# Two columns, 13 trinkets → 7 rows (last row has 1 item)
const COL_W: int = 340
const COL_GAP: int = 8
const ITEM_H: int = 50
const ITEM_GAP: int = 4
const ICON_SZ: int = 32

# Set by MiningLevel after instantiation
var player: PlayerProbe = null

# Parallel arrays tracking UI refs for each trinket (indexed by TRINKETS key order)
var _toggle_btns: Dictionary = {}    # trinket_id -> Button
var _row_borders: Dictionary = {}    # trinket_id -> ColorRect (highlight border)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_ui()

func _build_ui() -> void:
	var vp_w: int = 1280
	var vp_h: int = 720
	var px: int = (vp_w - PANEL_W) / 2
	var py: int = (vp_h - PANEL_H) / 2

	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# Main panel
	var panel := ColorRect.new()
	panel.color = Color(0.10, 0.09, 0.14, 0.97)
	panel.position = Vector2(px, py)
	panel.size = Vector2(PANEL_W, PANEL_H)
	add_child(panel)

	# Panel border
	for side in _border_rects(px, py, PANEL_W, PANEL_H, 2):
		var br := ColorRect.new()
		br.color = Color(0.55, 0.30, 0.80, 0.85)
		br.position = side[0]
		br.size = side[1]
		add_child(br)

	# Title
	var title := Label.new()
	title.text = "TRINKETS"
	title.position = Vector2(px + 20, py + 12)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.80, 0.55, 1.00)
	add_child(title)

	# Close hint
	var hint := Label.new()
	hint.text = "[G] Close"
	hint.position = Vector2(px + PANEL_W - 110, py + 14)
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.55, 0.55, 0.65, 0.90)
	add_child(hint)

	# Separator under title
	var sep := ColorRect.new()
	sep.color = Color(0.55, 0.30, 0.80, 0.40)
	sep.position = Vector2(px + 16, py + 44)
	sep.size = Vector2(PANEL_W - 32, 1)
	add_child(sep)

	# Trinket rows — 2 columns
	var trinket_ids: Array = TrinketSystem.TRINKETS.keys()
	var start_y: int = py + 54
	var left_x: int = px + 16
	var right_x: int = px + 16 + COL_W + COL_GAP

	for i in trinket_ids.size():
		var id: String = trinket_ids[i]
		var col_x: int = right_x if (i % 2 == 1) else left_x
		var row_y: int = start_y + (i / 2) * (ITEM_H + ITEM_GAP)
		_build_trinket_row(id, col_x, row_y, COL_W)

	# Close button at bottom center
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.position = Vector2(px + (PANEL_W - 90) / 2, py + PANEL_H - 44)
	close_btn.size = Vector2(90, 32)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(close)
	add_child(close_btn)

func _build_trinket_row(id: String, rx: int, ry: int, rw: int) -> void:
	var def: Dictionary = TrinketSystem.TRINKETS[id]

	# Row background
	var row_bg := ColorRect.new()
	row_bg.color = Color(0.13, 0.11, 0.17, 1.0)
	row_bg.position = Vector2(rx, ry)
	row_bg.size = Vector2(rw, ITEM_H)
	add_child(row_bg)

	# Row border (colored when equipped)
	var row_border := ColorRect.new()
	row_border.position = Vector2(rx - 1, ry - 1)
	row_border.size = Vector2(rw + 2, ITEM_H + 2)
	row_border.z_index = -1
	add_child(row_border)
	_row_borders[id] = row_border

	# Colored icon square
	var icon := ColorRect.new()
	icon.color = def["color"]
	icon.position = Vector2(rx + 6, ry + (ITEM_H - ICON_SZ) / 2)
	icon.size = Vector2(ICON_SZ, ICON_SZ)
	add_child(icon)

	# Icon inner highlight
	var icon_hi := ColorRect.new()
	icon_hi.color = def["color"].lightened(0.40)
	icon_hi.position = Vector2(rx + 6, ry + (ITEM_H - ICON_SZ) / 2)
	icon_hi.size = Vector2(ICON_SZ * 0.4, ICON_SZ * 0.4)
	add_child(icon_hi)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = def["name"]
	name_lbl.position = Vector2(rx + ICON_SZ + 14, ry + 5)
	name_lbl.custom_minimum_size = Vector2(rw - ICON_SZ - 104, 18)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.modulate = Color(1.0, 0.90, 0.70)
	add_child(name_lbl)

	# Description label
	var desc_lbl := Label.new()
	desc_lbl.text = def["desc"]
	desc_lbl.position = Vector2(rx + ICON_SZ + 14, ry + 26)
	desc_lbl.custom_minimum_size = Vector2(rw - ICON_SZ - 104, 18)
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.modulate = Color(0.60, 0.60, 0.68)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(desc_lbl)

	# Toggle button
	var btn := Button.new()
	btn.position = Vector2(rx + rw - 86, ry + (ITEM_H - 30) / 2)
	btn.size = Vector2(82, 30)
	btn.add_theme_font_size_override("font_size", 12)
	btn.pressed.connect(_on_toggle_trinket.bind(id))
	add_child(btn)
	_toggle_btns[id] = btn

func _on_toggle_trinket(id: String) -> void:
	var prop: String = "trinket_" + id
	var current: bool = GameManager.get(prop)
	GameManager.set(prop, not current)
	GameManager.save_game()
	EventBus.trinket_equipped.emit(id)
	if player:
		player.update_trinket_stats()
	_refresh_rows()

func _refresh_rows() -> void:
	var equipped_color := Color(0.25, 0.55, 0.25, 0.90)
	var unequipped_color := Color(0.28, 0.24, 0.36, 0.55)

	for id in TrinketSystem.TRINKETS:
		var is_eq: bool = TrinketSystem.is_equipped(id)
		if _toggle_btns.has(id):
			_toggle_btns[id].text = "UNEQUIP" if is_eq else "EQUIP"
		if _row_borders.has(id):
			_row_borders[id].color = equipped_color if is_eq else unequipped_color

func open() -> void:
	_refresh_rows()
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_trinket_menu"):
		close()
		get_viewport().set_input_as_handled()

func _border_rects(x: int, y: int, w: int, h: int, t: int) -> Array:
	return [
		[Vector2(x, y),             Vector2(w, t)],
		[Vector2(x, y + h - t),     Vector2(w, t)],
		[Vector2(x, y),             Vector2(t, h)],
		[Vector2(x + w - t, y),     Vector2(t, h)],
	]
