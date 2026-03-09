class_name CityLevel
extends Node2D

## City hub level — reached after banking a run.
## Left panel: Perk Tree status and prompt (upgrades handled via P key perk tree).
## Right panel: Spaceship upgrades (milestone-gated, bought with coins).

const VW: int = 1280
const VH: int = 720
const PANEL_W: int = 490
const PANEL_H: int = 590
const GAP: int = 20
const PANEL_Y: int = 65
const LEFT_X: int  = (VW - PANEL_W * 2 - GAP) / 2
const RIGHT_X: int = LEFT_X + PANEL_W + GAP

const SHIP_UPGRADES: Array = [
	{
		"key": "warp_drive", "name": "Warp Drive",
		"effect": "2x overworld travel speed",
		"unlock_label": "Bank 50s total to unlock",
		"cost_const": "SHIP_COST_WARP_DRIVE", "built_prop": "warp_drive_built",
	},
	{
		"key": "cargo_bay", "name": "Cargo Bay Expansion",
		"effect": "+25 ore carrying capacity",
		"unlock_label": "Defeat first boss to unlock",
		"cost_const": "SHIP_COST_CARGO_BAY", "built_prop": "cargo_bay_built",
	},
	{
		"key": "long_scanner", "name": "Long-Range Scanner",
		"effect": "Always shows both asteroid mines",
		"unlock_label": "Bank 10g total to unlock",
		"cost_const": "SHIP_COST_LONG_SCANNER", "built_prop": "long_scanner_built",
	},
	{
		"key": "gem_refinery", "name": "Gem Refinery",
		"effect": "+1 bonus gem per gem ore mined",
		"unlock_label": "Find 10 space fossils total to unlock",
		"cost_const": "SHIP_COST_GEM_REFINERY", "built_prop": "gem_refinery_built",
	},
	{
		"key": "trade_amplifier", "name": "Trade Amplifier",
		"effect": "+25% coin payout on bar sales",
		"unlock_label": "Reach sector 96 in a run to unlock",
		"cost_const": "SHIP_COST_TRADE_AMPLIFIER", "built_prop": "trade_amplifier_built",
	},
]

var _canvas: CanvasLayer
var _status_label: Label
var _chamber_buttons: Dictionary = {}

# Perk tree info panel refs (left panel)
var _perk_level_lbl   : Label
var _perk_points_lbl  : Label
var _perk_xp_bg       : ColorRect
var _perk_xp_fill     : ColorRect
var _perk_xp_lbl      : Label


func _ready() -> void:
	GameManager.bank_currency()
	_build_ui()


func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 5
	add_child(_canvas)
	_build_perk_panel()
	_build_chambers_panel()


# ── Left panel: Perk Tree status ─────────────────────────────────────────────
func _build_perk_panel() -> void:
	var px := LEFT_X
	var py := PANEL_Y

	_panel_border(px, py)
	_panel_body(px, py)

	var title := _label("Perk Tree", px, py + 12, PANEL_W, 30, 22)
	title.modulate = Color(0.80, 0.60, 1.00)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub := _label("Earn XP by mining and defeating bosses.", px, py + 50, PANEL_W, 22)
	sub.modulate = Color(0.70, 0.65, 0.80)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_divider(px, py + 80)

	# Level display
	_perk_level_lbl = _label("", px + 20, py + 96, PANEL_W - 40, 36, 26)
	_perk_level_lbl.modulate = Color(1.00, 0.85, 0.20)

	# XP bar
	var xp_bg := ColorRect.new()
	xp_bg.color = Color(0.10, 0.08, 0.20, 0.90)
	xp_bg.position = Vector2(px + 20, py + 142)
	xp_bg.size = Vector2(PANEL_W - 40, 16)
	xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(xp_bg)
	_perk_xp_bg = xp_bg

	_perk_xp_fill = ColorRect.new()
	_perk_xp_fill.color = Color(0.45, 0.25, 0.90, 1.00)
	_perk_xp_fill.position = Vector2(px + 20, py + 142)
	_perk_xp_fill.size = Vector2(0, 16)
	_perk_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_perk_xp_fill)

	_perk_xp_lbl = _label("", px + 20, py + 162, PANEL_W - 40, 18, 12)
	_perk_xp_lbl.modulate = Color(0.75, 0.65, 1.00)

	# Perk points available
	_perk_points_lbl = _label("", px + 20, py + 188, PANEL_W - 40, 28, 16)

	_divider(px, py + 224)

	# Describe branches
	var branch_info: Array[String] = [
		"PELT  —  HP, Energy, Boss resistance",
		"CLAWS  —  Mining power, Reach, Ore yield",
		"WHISKERS  —  Sonar, Cargo, Ladder speed",
	]
	var branch_colors: Array[Color] = [
		Color(0.95, 0.40, 0.40),
		Color(0.30, 0.90, 0.45),
		Color(0.75, 0.50, 1.00),
	]
	var info_y := py + 238
	for i in range(3):
		var lbl := _label(branch_info[i], px + 20, info_y, PANEL_W - 40, 22, 13)
		lbl.modulate = branch_colors[i]
		info_y += 28

	_divider(px, info_y + 6)

	# Open perk tree hint
	var hint := _label("Press  [P]  to open the Perk Tree", px, info_y + 20, PANEL_W, 30, 16)
	hint.modulate = Color(0.55, 0.80, 0.55)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Open perk tree button
	var btn_w := 220
	var btn := _button((px + (PANEL_W - btn_w) / 2), info_y + 58, btn_w, 44,
		"Open Perk Tree  [P]", _on_open_perk_tree_pressed)
	btn.tooltip_text = "View and spend perk points. Also accessible with the P key from anywhere."

	_refresh_perk_panel()


func _refresh_perk_panel() -> void:
	var lv    : int   = GameManager.player_level
	var xp    : int   = GameManager.player_xp
	var xp_nx : int   = PerkSystem.xp_for_next_level(lv)
	var pts   : int   = GameManager.perk_points
	_perk_level_lbl.text = "Level  %d" % lv
	_perk_xp_lbl.text    = "XP  %d / %d" % [xp, xp_nx]
	var bar_w: float = float(PANEL_W - 40) * float(xp) / float(maxi(1, xp_nx))
	_perk_xp_fill.size.x = bar_w
	_perk_points_lbl.text = (
		"%d Perk Point%s available" % [pts, "s" if pts != 1 else ""]
		if pts > 0 else
		"No perk points  —  keep mining!")
	_perk_points_lbl.modulate = Color(0.40, 1.00, 0.50) if pts > 0 else Color(0.55, 0.55, 0.60)


# ── Right panel: Spaceship Upgrades ──────────────────────────────────────────
func _build_chambers_panel() -> void:
	var px := RIGHT_X
	var py := PANEL_Y

	_panel_border(px, py)
	_panel_body(px, py)

	var title := _label("Spaceship Upgrades", px, py + 12, PANEL_W, 30, 20)
	title.modulate = Color(1.0, 0.80, 0.35)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub := _label("Permanent ship upgrades — built once, kept forever.", px, py + 48, PANEL_W, 22)
	sub.modulate = Color(0.70, 0.65, 0.55)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var dollars_lbl := _label("", px, py + 74, PANEL_W, 22)
	dollars_lbl.modulate = Color(0.30, 1.0, 0.40)
	dollars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dollars_lbl.text = "Coins: %s" % GameManager.format_coins(GameManager.coins)

	_divider(px, py + 100)

	const BTN_W: int   = PANEL_W - 40
	const BTN_H: int   = 66
	const BTN_GAP: int = 76
	var bx := px + 20
	var by := py + 114

	for upgrade in SHIP_UPGRADES:
		var btn := _button(bx, by, BTN_W, BTN_H, "", _on_chamber_pressed.bind(upgrade["key"]))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chamber_buttons[upgrade["key"]] = btn
		by += BTN_GAP

	_divider(px, py + PANEL_H - 64)

	_status_label = _label("", px, py + PANEL_H - 48, PANEL_W, 28)
	_status_label.modulate = Color(0.50, 1.0, 0.50)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

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


# ── Spaceship upgrades ────────────────────────────────────────────────────────
func _is_chamber_unlocked(key: String) -> bool:
	match key:
		"warp_drive":      return GameManager.total_coins_banked >= 50000
		"cargo_bay":       return GameManager.bosses_defeated_total >= 1
		"long_scanner":    return GameManager.total_coins_banked >= 100000
		"gem_refinery":    return GameManager.total_fossils >= 10
		"trade_amplifier": return GameManager.deepest_row_reached >= 96
	return false


func _refresh_chamber_panel() -> void:
	for upgrade in SHIP_UPGRADES:
		var btn: Button = _chamber_buttons.get(upgrade["key"])
		if not btn:
			continue
		var built: bool    = GameManager.get(upgrade["built_prop"])
		var cost_val: int  = GameManager.get(upgrade["cost_const"])
		var unlocked: bool = _is_chamber_unlocked(upgrade["key"])

		btn.disabled = built or not unlocked or GameManager.coins < cost_val

		if built:
			btn.text = "[INSTALLED]  %s\n%s" % [upgrade["name"], upgrade["effect"]]
		elif not unlocked:
			btn.text = "[LOCKED]  %s\n%s\n%s" % [upgrade["name"], upgrade["effect"], upgrade["unlock_label"]]
		else:
			btn.text = "Install %s  —  %s\nCost: %s" % [upgrade["name"], upgrade["effect"], GameManager.format_coins(cost_val)]


func _on_chamber_pressed(key: String) -> void:
	for upgrade in SHIP_UPGRADES:
		if upgrade["key"] != key:
			continue
		var built: bool   = GameManager.get(upgrade["built_prop"])
		var cost_val: int = GameManager.get(upgrade["cost_const"])
		if built or not _is_chamber_unlocked(key) or GameManager.coins < cost_val:
			return
		GameManager.coins -= cost_val
		EventBus.coins_changed.emit(GameManager.coins)
		GameManager.set(upgrade["built_prop"], true)
		GameManager.save_game()
		_status_label.text = "%s installed!" % upgrade["name"]
		_refresh_chamber_panel()
		break


func _on_open_perk_tree_pressed() -> void:
	PerkTreeMenu._open()


func _on_return_button_pressed() -> void:
	GameManager.load_overworld()
