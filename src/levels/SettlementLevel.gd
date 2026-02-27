class_name SettlementLevel
extends Node2D

# Settlement rest stop — visited from the Overworld between mine runs.
# Players spend banked minerals (mineral_currency) on energy caches, repairs,
# and consumables that carry into their next mining run.

const PANEL_W: int = 520
const PANEL_H: int = 460
const VW: int = 1280
const VH: int = 720

# Consumables pre-purchased here persist into the next mine run via GameManager
# Costs are in banked mineral_currency (not run_mineral_currency)
const COST_ENERGY_CACHE: int    = 20   # +50 starting energy next run
const COST_RATIONS: int       = 25   # +20 scout cat carry capacity next run
const COST_SHROOM: int        = 35   # 12 shroom charges next run
const COST_SHARPENING: int    = 30   # +1 claw power for one run (temporary)

var _location_name: String = "Settlement"
var _minerals_label: Label
var _status_label: Label
var _btn_energy: Button
var _btn_rations: Button
var _btn_shroom: Button
var _btn_sharpen: Button

func _ready() -> void:
	# Pick up the settlement name from GameManager if available
	if GameManager.last_overworld_node_name != "":
		_location_name = GameManager.last_overworld_node_name.replace("Node", "").replace("3", " (North)").replace("4", " (South)")

	var music := load("res://assets/music/crickets.mp3") as AudioStream
	MusicManager.play_music(music)

	_build_ui()

func _build_ui() -> void:
	var px := (VW - PANEL_W) / 2
	var py := (VH - PANEL_H) / 2

	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	# Background dim
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0.05, 0.04, 0.03)
	canvas.add_child(dim)

	# Panel border
	var border := ColorRect.new()
	border.position = Vector2(px - 3, py - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.60, 0.45, 0.20, 1.0)
	canvas.add_child(border)

	# Panel body
	var panel := ColorRect.new()
	panel.position = Vector2(px, py)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.09, 0.08, 0.06, 0.97)
	canvas.add_child(panel)

	# Title
	var title := Label.new()
	title.text = "Settlement — Rest Stop"
	title.position = Vector2(px, py + 12)
	title.size = Vector2(PANEL_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.80, 0.35)
	canvas.add_child(title)

	# Subtitle / flavour
	var subtitle := Label.new()
	subtitle.text = "A small outpost where cat miners rest and resupply."
	subtitle.position = Vector2(px, py + 46)
	subtitle.size = Vector2(PANEL_W, 22)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.70, 0.65, 0.55)
	canvas.add_child(subtitle)

	# Minerals display
	_minerals_label = Label.new()
	_minerals_label.position = Vector2(px, py + 72)
	_minerals_label.size = Vector2(PANEL_W, 26)
	_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_minerals_label.modulate = Color(1.0, 0.85, 0.20)
	canvas.add_child(_minerals_label)
	_refresh_minerals()

	# Divider
	var div := ColorRect.new()
	div.position = Vector2(px + 20, py + 104)
	div.size = Vector2(PANEL_W - 40, 2)
	div.color = Color(0.60, 0.45, 0.20, 0.6)
	canvas.add_child(div)

	# Status label (feedback for purchases)
	_status_label = Label.new()
	_status_label.position = Vector2(px, py + PANEL_H - 94)
	_status_label.size = Vector2(PANEL_W, 26)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.modulate = Color(0.50, 1.0, 0.50)
	canvas.add_child(_status_label)

	# Buttons
	const BTN_X_OFFSET: int = 30
	const BTN_W_OFFSET: int = 60
	const BTN_H: int = 46
	const BTN_GAP: int = 56
	var bx := px + BTN_X_OFFSET
	var bw := PANEL_W - BTN_W_OFFSET
	var by := py + 116

	_btn_energy = _make_button(canvas, bx, by, bw, BTN_H,
		"Energy Cache  —  +50 starting energy next run  (%d minerals)" % COST_ENERGY_CACHE,
		_buy_energy_cache)
	by += BTN_GAP

	_btn_rations = _make_button(canvas, bx, by, bw, BTN_H,
		"Scout Rations  —  +20 scout cat carry capacity next run  (%d minerals)" % COST_RATIONS,
		_buy_rations)
	by += BTN_GAP

	_btn_shroom = _make_button(canvas, bx, by, bw, BTN_H,
		"Mining Shroom  —  +12 ore yield charges next run  (%d minerals)" % COST_SHROOM,
		_buy_shroom)
	by += BTN_GAP

	_btn_sharpen = _make_button(canvas, bx, by, bw, BTN_H,
		"Claw Whetstone  —  +1 Claw power next run  (%d minerals)" % COST_SHARPENING,
		_buy_sharpening)
	by += BTN_GAP

	# Return button
	var div2 := ColorRect.new()
	div2.position = Vector2(px + 20, py + PANEL_H - 70)
	div2.size = Vector2(PANEL_W - 40, 2)
	div2.color = Color(0.60, 0.45, 0.20, 0.5)
	canvas.add_child(div2)

	var return_btn := Button.new()
	return_btn.text = "Return to Map"
	return_btn.position = Vector2(px + (PANEL_W - 220) / 2, py + PANEL_H - 56)
	return_btn.size = Vector2(220, 44)
	return_btn.pressed.connect(_return_to_overworld)
	canvas.add_child(return_btn)

	_update_button_states()

func _make_button(parent: Node, x: int, y: int, w: int, h: int, label: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _refresh_minerals() -> void:
	_minerals_label.text = "Banked Minerals: %d" % GameManager.mineral_currency

func _update_button_states() -> void:
	var m := GameManager.mineral_currency
	_btn_energy.disabled    = m < COST_ENERGY_CACHE
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
	_set_status("+50 energy cache ready for next run!")
	_refresh_minerals()
	_update_button_states()

func _buy_rations() -> void:
	if GameManager.mineral_currency < COST_RATIONS:
		return
	GameManager.mineral_currency -= COST_RATIONS
	GameManager.settlement_forager_bonus += 20
	GameManager.save_game()
	_set_status("+20 scout cat carry capacity next run!")
	_refresh_minerals()
	_update_button_states()

func _buy_shroom() -> void:
	if GameManager.mineral_currency < COST_SHROOM:
		return
	GameManager.mineral_currency -= COST_SHROOM
	GameManager.settlement_shroom_charges += 12
	GameManager.save_game()
	_set_status("+12 Mining Shroom charges next run!")
	_refresh_minerals()
	_update_button_states()

func _buy_sharpening() -> void:
	if GameManager.mineral_currency < COST_SHARPENING:
		return
	GameManager.mineral_currency -= COST_SHARPENING
	GameManager.settlement_mandible_bonus += 1
	GameManager.save_game()
	_set_status("+1 Claw power next run!")
	_refresh_minerals()
	_update_button_states()

func _return_to_overworld() -> void:
	GameManager.load_overworld()
