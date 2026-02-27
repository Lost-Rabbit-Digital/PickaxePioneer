class_name CityLevel
extends Node2D

# ── Layout ────────────────────────────────────────────────────────────────────
const VW: int = 1280
const VH: int = 720
const PANEL_W: int = 490
const PANEL_H: int = 590
const GAP: int     = 20
const PANEL_Y: int = 65
# Horizontally centred pair of panels
const LEFT_X: int  = (VW - PANEL_W * 2 - GAP) / 2   # 140
const RIGHT_X: int = LEFT_X + PANEL_W + GAP           # 650

const CHAMBERS: Array = [
	{
		"key": "fungus_garden", "name": "Fungus Garden",
		"effect": "+10% mineral yield",
		"unlock_label": "Bank 500 minerals total to unlock",
		"cost_const": "CHAMBER_COST_FUNGUS_GARDEN", "built_prop": "fungus_garden_built",
	},
	{
		"key": "brood_chamber", "name": "Brood Chamber",
		"effect": "Forager carry +20",
		"unlock_label": "Defeat first boss to unlock",
		"cost_const": "CHAMBER_COST_BROOD_CHAMBER", "built_prop": "brood_chamber_built",
	},
	{
		"key": "armory", "name": "Armory",
		"effect": "Blast radius +1 tile",
		"unlock_label": "Bank 1000 minerals total to unlock",
		"cost_const": "CHAMBER_COST_ARMORY", "built_prop": "armory_built",
	},
	{
		"key": "nursery_vault", "name": "Nursery Vault",
		"effect": "+5% fossil find rate",
		"unlock_label": "Find 10 fossils total to unlock",
		"cost_const": "CHAMBER_COST_NURSERY_VAULT", "built_prop": "nursery_vault_built",
	},
	{
		"key": "deep_antenna", "name": "Deep Antenna Array",
		"effect": "Sonar radius +3 tiles",
		"unlock_label": "Reach row 96 in a run to unlock",
		"cost_const": "CHAMBER_COST_DEEP_ANTENNA", "built_prop": "deep_antenna_built",
	},
]

# Upgrade costs scale per session (same behaviour as the old UpgradeMenu)
var _carapace_cost: int  = 50
var _legs_cost: int      = 50
var _mandibles_cost: int = 50
var _sense_cost: int     = 75

# ── UI refs ───────────────────────────────────────────────────────────────────
var _canvas: CanvasLayer
var _minerals_label: Label
var _status_label: Label
var _btn_carapace: Button
var _btn_legs: Button
var _btn_mandibles: Button
var _btn_sense: Button
var _btn_gem_carapace: Button
var _btn_gem_legs: Button
var _btn_gem_mandibles: Button
var _btn_gem_sense: Button
var _chamber_buttons: Dictionary = {}


func _ready() -> void:
	GameManager.bank_currency()
	var music := load("res://assets/music/crickets.mp3") as AudioStream
	MusicManager.play_music(music)
	_build_ui()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 5
	add_child(_canvas)
	_build_upgrades_panel()
	_build_chambers_panel()


# ── Left panel: Upgrades + Gem Sockets ───────────────────────────────────────
func _build_upgrades_panel() -> void:
	var px := LEFT_X
	var py := PANEL_Y

	_panel_border(px, py)
	_panel_body(px, py)

	var title := _label("Base City — Upgrades", px, py + 12, PANEL_W, 30, 20)
	title.modulate = Color(1.0, 0.80, 0.35)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub := _label("Spend minerals to permanently strengthen your colony.", px, py + 48, PANEL_W, 22)
	sub.modulate = Color(0.70, 0.65, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_minerals_label = _label("", px, py + 74, PANEL_W, 26)
	_minerals_label.modulate = Color(1.0, 0.85, 0.20)
	_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_divider(px, py + 108)

	const BTN_W: int  = PANEL_W - 40   # 20 px margin each side
	const BTN_H: int  = 40
	const BTN_GAP: int = 48
	var bx := px + 20
	var by := py + 120

	_btn_carapace  = _button(bx, by, BTN_W, BTN_H, "", _on_carapace_pressed);  by += BTN_GAP
	_btn_legs      = _button(bx, by, BTN_W, BTN_H, "", _on_legs_pressed);      by += BTN_GAP
	_btn_mandibles = _button(bx, by, BTN_W, BTN_H, "", _on_mandibles_pressed); by += BTN_GAP
	_btn_sense     = _button(bx, by, BTN_W, BTN_H, "", _on_sense_pressed);     by += BTN_GAP + 8

	_divider(px, by)
	by += 14

	var gem_hdr := _label("Gem Sockets  (cost: %d gems each)" % GameManager.GEM_SOCKET_COST,
		px, by, PANEL_W, 22)
	gem_hdr.modulate = Color(0.15, 0.85, 0.75)
	gem_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	by += 30

	_btn_gem_carapace  = _button(bx, by, BTN_W, BTN_H, "", _on_gem_carapace_pressed);  by += BTN_GAP
	_btn_gem_legs      = _button(bx, by, BTN_W, BTN_H, "", _on_gem_legs_pressed);      by += BTN_GAP
	_btn_gem_mandibles = _button(bx, by, BTN_W, BTN_H, "", _on_gem_mandibles_pressed); by += BTN_GAP
	_btn_gem_sense     = _button(bx, by, BTN_W, BTN_H, "", _on_gem_sense_pressed)

	_status_label = _label("", px, py + PANEL_H - 36, PANEL_W, 28)
	_status_label.modulate = Color(0.50, 1.0, 0.50)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_update_ui()


# ── Right panel: Colony Chambers ─────────────────────────────────────────────
func _build_chambers_panel() -> void:
	var px := RIGHT_X
	var py := PANEL_Y

	_panel_border(px, py)
	_panel_body(px, py)

	var title := _label("Colony Chambers", px, py + 12, PANEL_W, 30, 20)
	title.modulate = Color(1.0, 0.80, 0.35)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub := _label("Permanent expansions — built once, kept forever.", px, py + 48, PANEL_W, 22)
	sub.modulate = Color(0.70, 0.65, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_divider(px, py + 78)

	const BTN_W: int   = PANEL_W - 40
	const BTN_H: int   = 66
	const BTN_GAP: int = 76
	var bx := px + 20
	var by := py + 92

	for chamber in CHAMBERS:
		var btn := _button(bx, by, BTN_W, BTN_H, "", _on_chamber_pressed.bind(chamber["key"]))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chamber_buttons[chamber["key"]] = btn
		by += BTN_GAP

	_divider(px, py + PANEL_H - 64)

	_button((px + (PANEL_W - 220) / 2), py + PANEL_H - 52, 220, 44,
		"Return to Map", _on_return_button_pressed)

	_refresh_chamber_panel()


# ── Primitive builders ────────────────────────────────────────────────────────
func _panel_border(px: int, py: int) -> void:
	var b := ColorRect.new()
	b.position = Vector2(px - 3, py - 3)
	b.size     = Vector2(PANEL_W + 6, PANEL_H + 6)
	b.color    = Color(0.60, 0.45, 0.20, 1.0)
	_canvas.add_child(b)


func _panel_body(px: int, py: int) -> void:
	var p := ColorRect.new()
	p.position = Vector2(px, py)
	p.size     = Vector2(PANEL_W, PANEL_H)
	p.color    = Color(0.09, 0.08, 0.06, 0.97)
	_canvas.add_child(p)


func _divider(px: int, abs_y: int) -> void:
	var d := ColorRect.new()
	d.position = Vector2(px + 20, abs_y)
	d.size     = Vector2(PANEL_W - 40, 2)
	d.color    = Color(0.60, 0.45, 0.20, 0.6)
	_canvas.add_child(d)


func _label(text: String, x: int, y: int, w: int, h: int, font_size: int = 14) -> Label:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(x, y)
	lbl.size     = Vector2(w, h)
	if font_size != 14:
		lbl.add_theme_font_size_override("font_size", font_size)
	_canvas.add_child(lbl)
	return lbl


func _button(x: int, y: int, w: int, h: int, text: String, callback: Callable) -> Button:
	var btn := Button.new()
	btn.text     = text
	btn.position = Vector2(x, y)
	btn.size     = Vector2(w, h)
	btn.pressed.connect(callback)
	_canvas.add_child(btn)
	return btn


# ── UI refresh ────────────────────────────────────────────────────────────────
func _update_ui() -> void:
	_minerals_label.text = "Banked Minerals: %d   |   Gems: %d" % [
		GameManager.mineral_currency, GameManager.gem_count]

	var hp    := GameManager.get_max_health()
	var energy  := GameManager.get_max_energy()
	var spd   := GameManager.get_max_speed()
	var power := GameManager.get_mandibles_power()
	var r     := GameManager.get_sonar_ping_radius()
	var fc    := GameManager.get_sonar_ping_energy_cost()

	_btn_carapace.text  = "Harden Carapace Lv%d  —  HP %d → %d  (%d minerals)" % [
		GameManager.carapace_level, hp, hp + 1, _carapace_cost]
	_btn_legs.text      = "Strengthen Legs Lv%d  —  Energy %d → %d, Speed %.0f → %.0f  (%d minerals)" % [
		GameManager.legs_level, energy, energy + 25, spd, spd + 30.0, _legs_cost]
	_btn_mandibles.text = "Sharpen Mandibles Lv%d  —  Power %d → %d  (%d minerals)" % [
		GameManager.mandibles_level, power, power + 3, _mandibles_cost]
	_btn_sense.text     = "Mineral Sense Lv%d  —  Radius %.0f → %.0f tiles, Energy %d → %d  (%d minerals)" % [
		GameManager.mineral_sense_level, r, r + 3.0, fc, maxi(3, fc - 2), _sense_cost]

	var m := GameManager.mineral_currency
	_btn_carapace.disabled  = m < _carapace_cost
	_btn_legs.disabled      = m < _legs_cost
	_btn_mandibles.disabled = m < _mandibles_cost
	_btn_sense.disabled     = m < _sense_cost

	# Gem sockets
	if GameManager.carapace_gem_socketed:
		_btn_gem_carapace.text = "[SOCKETED]  Chitin Gem — +1 Max HP"
		_btn_gem_carapace.disabled = true
	else:
		_btn_gem_carapace.text = "Socket Chitin Gem — +1 Max HP  (%d gems)" % GameManager.GEM_SOCKET_COST
		_btn_gem_carapace.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

	if GameManager.legs_gem_socketed:
		_btn_gem_legs.text = "[SOCKETED]  Quickstride Gem — +25 Energy, +15 Speed"
		_btn_gem_legs.disabled = true
	else:
		_btn_gem_legs.text = "Socket Quickstride Gem — +25 Energy, +15 Speed  (%d gems)" % GameManager.GEM_SOCKET_COST
		_btn_gem_legs.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

	if GameManager.mandibles_gem_socketed:
		_btn_gem_mandibles.text = "[SOCKETED]  Fracture Gem — +4 Mining Power"
		_btn_gem_mandibles.disabled = true
	else:
		_btn_gem_mandibles.text = "Socket Fracture Gem — +4 Mining Power  (%d gems)" % GameManager.GEM_SOCKET_COST
		_btn_gem_mandibles.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

	if GameManager.sense_gem_socketed:
		_btn_gem_sense.text = "[SOCKETED]  Echo Gem — +3 Sonar Radius"
		_btn_gem_sense.disabled = true
	else:
		_btn_gem_sense.text = "Socket Echo Gem — +3 Sonar Radius  (%d gems)" % GameManager.GEM_SOCKET_COST
		_btn_gem_sense.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST


func _set_status(msg: String) -> void:
	_status_label.text = msg


# ── Upgrade purchases ─────────────────────────────────────────────────────────
func _on_carapace_pressed() -> void:
	if GameManager.mineral_currency < _carapace_cost:
		return
	GameManager.mineral_currency -= _carapace_cost
	GameManager.upgrade_carapace()
	_carapace_cost += 25
	GameManager.save_game()
	_set_status("Carapace hardened!")
	_update_ui()


func _on_legs_pressed() -> void:
	if GameManager.mineral_currency < _legs_cost:
		return
	GameManager.mineral_currency -= _legs_cost
	GameManager.upgrade_legs()
	_legs_cost += 25
	GameManager.save_game()
	_set_status("Legs strengthened!")
	_update_ui()


func _on_mandibles_pressed() -> void:
	if GameManager.mineral_currency < _mandibles_cost:
		return
	GameManager.mineral_currency -= _mandibles_cost
	GameManager.upgrade_mandibles()
	_mandibles_cost += 25
	GameManager.save_game()
	_set_status("Mandibles sharpened!")
	_update_ui()


func _on_sense_pressed() -> void:
	if GameManager.mineral_currency < _sense_cost:
		return
	GameManager.mineral_currency -= _sense_cost
	GameManager.upgrade_mineral_sense()
	_sense_cost += 50
	GameManager.save_game()
	_set_status("Mineral sense enhanced!")
	_update_ui()


# ── Gem sockets ───────────────────────────────────────────────────────────────
func _on_gem_carapace_pressed() -> void:
	if GameManager.carapace_gem_socketed or GameManager.gem_count < GameManager.GEM_SOCKET_COST:
		return
	GameManager.gem_count -= GameManager.GEM_SOCKET_COST
	GameManager.carapace_gem_socketed = true
	GameManager.save_game()
	_set_status("Chitin Gem socketed!")
	_update_ui()


func _on_gem_legs_pressed() -> void:
	if GameManager.legs_gem_socketed or GameManager.gem_count < GameManager.GEM_SOCKET_COST:
		return
	GameManager.gem_count -= GameManager.GEM_SOCKET_COST
	GameManager.legs_gem_socketed = true
	GameManager.save_game()
	_set_status("Quickstride Gem socketed!")
	_update_ui()


func _on_gem_mandibles_pressed() -> void:
	if GameManager.mandibles_gem_socketed or GameManager.gem_count < GameManager.GEM_SOCKET_COST:
		return
	GameManager.gem_count -= GameManager.GEM_SOCKET_COST
	GameManager.mandibles_gem_socketed = true
	GameManager.save_game()
	_set_status("Fracture Gem socketed!")
	_update_ui()


func _on_gem_sense_pressed() -> void:
	if GameManager.sense_gem_socketed or GameManager.gem_count < GameManager.GEM_SOCKET_COST:
		return
	GameManager.gem_count -= GameManager.GEM_SOCKET_COST
	GameManager.sense_gem_socketed = true
	GameManager.save_game()
	_set_status("Echo Gem socketed!")
	_update_ui()


# ── Colony Chambers ───────────────────────────────────────────────────────────
func _is_chamber_unlocked(key: String) -> bool:
	match key:
		"fungus_garden": return GameManager.total_minerals_banked >= 500
		"brood_chamber": return GameManager.bosses_defeated_total >= 1
		"armory":        return GameManager.total_minerals_banked >= 1000
		"nursery_vault": return GameManager.total_fossils >= 10
		"deep_antenna":  return GameManager.deepest_row_reached >= 96
	return false


func _refresh_chamber_panel() -> void:
	for chamber in CHAMBERS:
		var btn: Button = _chamber_buttons.get(chamber["key"])
		if not btn:
			continue
		var built: bool    = GameManager.get(chamber["built_prop"])
		var cost_val: int  = GameManager.get(chamber["cost_const"])
		var unlocked: bool = _is_chamber_unlocked(chamber["key"])

		btn.disabled = built or not unlocked or GameManager.mineral_currency < cost_val

		if built:
			btn.text = "[BUILT]  %s\n%s" % [chamber["name"], chamber["effect"]]
		elif not unlocked:
			btn.text = "[LOCKED]  %s\n%s\n%s" % [chamber["name"], chamber["effect"], chamber["unlock_label"]]
		else:
			btn.text = "Build %s  —  %s\nCost: %d minerals" % [chamber["name"], chamber["effect"], cost_val]


func _on_chamber_pressed(key: String) -> void:
	for chamber in CHAMBERS:
		if chamber["key"] != key:
			continue
		var built: bool   = GameManager.get(chamber["built_prop"])
		var cost_val: int = GameManager.get(chamber["cost_const"])
		if built or not _is_chamber_unlocked(key) or GameManager.mineral_currency < cost_val:
			return
		GameManager.mineral_currency -= cost_val
		GameManager.set(chamber["built_prop"], true)
		GameManager.save_game()
		_set_status("%s constructed!" % chamber["name"])
		_refresh_chamber_panel()
		_update_ui()
		break


func _on_return_button_pressed() -> void:
	GameManager.load_overworld()
