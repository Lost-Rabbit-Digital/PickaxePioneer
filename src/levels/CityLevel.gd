class_name CityLevel
extends Node2D

## City hub level — The Clowder, a feline space station.
## Polished atmospheric menu with NPC flavor, starfield backdrop,
## and themed station sections for Perk Tree and Spaceship Upgrades.

const VW: int = 1280
const VH: int = 720
const PANEL_W: int = 460
const PANEL_H: int = 530
const GAP: int = 24
const HEADER_H: int = 80
const PANEL_Y: int = HEADER_H + 20
const LEFT_X: int  = (VW - PANEL_W * 2 - GAP) / 2
const RIGHT_X: int = LEFT_X + PANEL_W + GAP

const ACCENT_GOLD := Color(0.90, 0.72, 0.30)
const ACCENT_PURPLE := Color(0.70, 0.45, 1.00)
const ACCENT_GREEN := Color(0.35, 0.90, 0.45)
const DIM_TEXT := Color(0.55, 0.55, 0.60)
const PANEL_BG := Color(0.06, 0.06, 0.10, 0.92)
const PANEL_BORDER := Color(0.25, 0.20, 0.40, 0.85)

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

# NPC dialogue pools — randomly chosen on each visit
const MATRIARCH_LINES: Array[String] = [
	"Welcome back, miner. The Clowder grows stronger with every haul.",
	"Your paws have been busy. Spend your points wisely.",
	"Another safe return. The kittens will eat well tonight.",
	"The stars await, but first... rest and restock.",
	"Every gem you bring home is one step closer to a new world.",
]

const ENGINEER_LINES: Array[String] = [
	"Ship's holding together. Got some upgrades if you've got the coin.",
	"I've been tinkering. Take a look at what's new in the bay.",
	"Warp drive's humming. Ready for whatever you need.",
	"More ore, more options. Let's see what we can build.",
	"The Clowder's finest engineer, at your service.",
]

var _canvas: CanvasLayer
var _status_label: Label
var _chamber_buttons: Dictionary = {}

# Perk tree info panel refs
var _perk_level_lbl   : Label
var _perk_points_lbl  : Label
var _perk_xp_bg       : ColorRect
var _perk_xp_fill     : ColorRect
var _perk_xp_lbl      : Label

# Starfield particles
var _stars: Array = []
const STAR_COUNT: int = 60

@onready var pause_menu = $PauseMenu


func _ready() -> void:
	GameManager.bank_currency()
	_build_starfield()
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_menu.show_menu()
		get_viewport().set_input_as_handled()


# ── Starfield — twinkling background stars ──────────────────────────────────
func _build_starfield() -> void:
	for i in range(STAR_COUNT):
		_stars.append({
			"pos": Vector2(randf_range(0, VW), randf_range(0, VH)),
			"size": randf_range(1.0, 3.0),
			"speed": randf_range(0.3, 1.2),
			"phase": randf_range(0, TAU),
			"brightness": randf_range(0.3, 0.9),
		})
	queue_redraw()


func _process(delta: float) -> void:
	for star in _stars:
		star["phase"] += delta * star["speed"]
	queue_redraw()


func _draw() -> void:
	# Deep space background gradient
	draw_rect(Rect2(0, 0, VW, VH), Color(0.02, 0.02, 0.06))
	var grad_color := Color(0.06, 0.04, 0.12, 0.5)
	draw_rect(Rect2(0, VH * 0.6, VW, VH * 0.4), grad_color)

	# Twinkling stars
	for star in _stars:
		var alpha: float = star["brightness"] * (0.5 + 0.5 * sin(star["phase"]))
		var color := Color(0.8, 0.85, 1.0, alpha)
		var sz: float = star["size"]
		draw_circle(star["pos"], sz, color)


# ── UI construction ─────────────────────────────────────────────────────────
func _build_ui() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 5
	add_child(_canvas)

	_build_header()
	_build_perk_panel()
	_build_chambers_panel()
	_build_footer()


func _build_header() -> void:
	# Header background bar
	var header_bg := ColorRect.new()
	header_bg.position = Vector2(0, 0)
	header_bg.size = Vector2(VW, HEADER_H)
	header_bg.color = Color(0.04, 0.04, 0.08, 0.90)
	header_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(header_bg)

	# Accent line under header
	var accent := ColorRect.new()
	accent.position = Vector2(0, HEADER_H - 2)
	accent.size = Vector2(VW, 2)
	accent.color = ACCENT_GOLD * Color(1, 1, 1, 0.4)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(accent)

	# Station name
	var title := Label.new()
	title.text = "THE CLOWDER"
	title.position = Vector2(0, 8)
	title.size = Vector2(VW, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", ACCENT_GOLD)
	_canvas.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Feline Space Station  —  Home of the Mining Cats"
	subtitle.position = Vector2(0, 44)
	subtitle.size = Vector2(VW, 24)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", DIM_TEXT)
	_canvas.add_child(subtitle)


# ── Left panel: Perk Tree ───────────────────────────────────────────────────
func _build_perk_panel() -> void:
	var px := LEFT_X
	var py := PANEL_Y

	_panel_border(px, py)
	_panel_body(px, py)

	# NPC portrait area
	var npc_bg := ColorRect.new()
	npc_bg.position = Vector2(px + 12, py + 12)
	npc_bg.size = Vector2(PANEL_W - 24, 52)
	npc_bg.color = Color(0.10, 0.08, 0.18, 0.80)
	npc_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(npc_bg)

	# NPC name
	var npc_name := Label.new()
	npc_name.text = "Matriarch Whisper"
	npc_name.position = Vector2(px + 20, py + 14)
	npc_name.size = Vector2(PANEL_W - 40, 20)
	npc_name.add_theme_font_size_override("font_size", 14)
	npc_name.add_theme_color_override("font_color", ACCENT_PURPLE)
	_canvas.add_child(npc_name)

	# NPC dialogue
	var dialogue := Label.new()
	dialogue.text = "\"%s\"" % MATRIARCH_LINES[randi() % MATRIARCH_LINES.size()]
	dialogue.position = Vector2(px + 20, py + 34)
	dialogue.size = Vector2(PANEL_W - 40, 22)
	dialogue.add_theme_font_size_override("font_size", 11)
	dialogue.add_theme_color_override("font_color", Color(0.70, 0.65, 0.80))
	_canvas.add_child(dialogue)

	_divider(px, py + 72)

	var title := _label("Perk Tree", px, py + 80, PANEL_W, 26, 20)
	title.add_theme_color_override("font_color", ACCENT_PURPLE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub := _label("Earn XP by mining and defeating bosses.", px, py + 108, PANEL_W, 20, 12)
	sub.add_theme_color_override("font_color", Color(0.60, 0.55, 0.70))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_divider(px, py + 134)

	# Level display
	_perk_level_lbl = _label("", px + 20, py + 144, PANEL_W - 40, 32, 24)
	_perk_level_lbl.add_theme_color_override("font_color", ACCENT_GOLD)

	# XP bar
	_perk_xp_bg = ColorRect.new()
	_perk_xp_bg.color = Color(0.10, 0.08, 0.20, 0.90)
	_perk_xp_bg.position = Vector2(px + 20, py + 182)
	_perk_xp_bg.size = Vector2(PANEL_W - 40, 14)
	_perk_xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_perk_xp_bg)

	_perk_xp_fill = ColorRect.new()
	_perk_xp_fill.color = Color(0.45, 0.25, 0.90, 1.00)
	_perk_xp_fill.position = Vector2(px + 20, py + 182)
	_perk_xp_fill.size = Vector2(0, 14)
	_perk_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(_perk_xp_fill)

	_perk_xp_lbl = _label("", px + 20, py + 200, PANEL_W - 40, 16, 11)
	_perk_xp_lbl.add_theme_color_override("font_color", Color(0.65, 0.55, 0.90))

	_perk_points_lbl = _label("", px + 20, py + 222, PANEL_W - 40, 24, 15)

	_divider(px, py + 252)

	# Perk branch descriptions
	var branch_info: Array[String] = [
		"PELT  —  HP, Energy, Boss resistance",
		"CLAWS  —  Mining power, Reach, Ore yield",
		"WHISKERS  —  Sonar, Cargo, Ladder speed",
	]
	var branch_colors: Array[Color] = [
		Color(0.95, 0.40, 0.40),
		Color(0.30, 0.90, 0.45),
		ACCENT_PURPLE,
	]
	var info_y := py + 264
	for i in range(3):
		var lbl := _label(branch_info[i], px + 20, info_y, PANEL_W - 40, 20, 12)
		lbl.add_theme_color_override("font_color", branch_colors[i])
		info_y += 26

	_divider(px, info_y + 8)

	# Open perk tree
	var hint := _label("Press  [P]  to open the Perk Tree", px, info_y + 18, PANEL_W, 24, 14)
	hint.add_theme_color_override("font_color", Color(0.45, 0.70, 0.45))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var btn_w := 200
	var btn := _button((px + (PANEL_W - btn_w) / 2), info_y + 50, btn_w, 40,
		"Open Perk Tree  [P]", _on_open_perk_tree_pressed)
	btn.tooltip_text = "View and spend perk points."

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
	_perk_points_lbl.add_theme_color_override("font_color",
		ACCENT_GREEN if pts > 0 else DIM_TEXT)


# ── Right panel: Spaceship Upgrades ─────────────────────────────────────────
func _build_chambers_panel() -> void:
	var px := RIGHT_X
	var py := PANEL_Y

	_panel_border(px, py)
	_panel_body(px, py)

	# NPC portrait area
	var npc_bg := ColorRect.new()
	npc_bg.position = Vector2(px + 12, py + 12)
	npc_bg.size = Vector2(PANEL_W - 24, 52)
	npc_bg.color = Color(0.12, 0.10, 0.06, 0.80)
	npc_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(npc_bg)

	# NPC name
	var npc_name := Label.new()
	npc_name.text = "Chief Engineer Bolt"
	npc_name.position = Vector2(px + 20, py + 14)
	npc_name.size = Vector2(PANEL_W - 40, 20)
	npc_name.add_theme_font_size_override("font_size", 14)
	npc_name.add_theme_color_override("font_color", ACCENT_GOLD)
	_canvas.add_child(npc_name)

	# NPC dialogue
	var dialogue := Label.new()
	dialogue.text = "\"%s\"" % ENGINEER_LINES[randi() % ENGINEER_LINES.size()]
	dialogue.position = Vector2(px + 20, py + 34)
	dialogue.size = Vector2(PANEL_W - 40, 22)
	dialogue.add_theme_font_size_override("font_size", 11)
	dialogue.add_theme_color_override("font_color", Color(0.65, 0.60, 0.45))
	_canvas.add_child(dialogue)

	_divider(px, py + 72)

	var title := _label("Spaceship Upgrades", px, py + 80, PANEL_W, 26, 20)
	title.add_theme_color_override("font_color", ACCENT_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var sub := _label("Permanent ship upgrades — built once, kept forever.", px, py + 108, PANEL_W, 20, 12)
	sub.add_theme_color_override("font_color", Color(0.60, 0.55, 0.45))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var dollars_lbl := _label("", px, py + 130, PANEL_W, 20, 14)
	dollars_lbl.add_theme_color_override("font_color", ACCENT_GREEN)
	dollars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dollars_lbl.text = "Coins: %s" % GameManager.format_coins(GameManager.coins)

	_divider(px, py + 156)

	const BTN_W: int   = PANEL_W - 40
	const BTN_H: int   = 58
	const BTN_GAP: int = 66
	var bx := px + 20
	var by := py + 168

	for upgrade in SHIP_UPGRADES:
		var btn := _button(bx, by, BTN_W, BTN_H, "", _on_chamber_pressed.bind(upgrade["key"]))
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_chamber_buttons[upgrade["key"]] = btn
		by += BTN_GAP

	_status_label = _label("", px, by + 4, PANEL_W, 24, 12)
	_status_label.add_theme_color_override("font_color", ACCENT_GREEN)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_refresh_chamber_panel()


func _build_footer() -> void:
	# Footer bar
	var footer_bg := ColorRect.new()
	footer_bg.position = Vector2(0, VH - 50)
	footer_bg.size = Vector2(VW, 50)
	footer_bg.color = Color(0.04, 0.04, 0.08, 0.85)
	footer_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(footer_bg)

	var accent := ColorRect.new()
	accent.position = Vector2(0, VH - 50)
	accent.size = Vector2(VW, 1)
	accent.color = ACCENT_GOLD * Color(1, 1, 1, 0.3)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(accent)

	# Return button — centered in footer
	var btn_w := 200
	var btn := Button.new()
	btn.text = "Return to Star Chart"
	btn.position = Vector2((VW - btn_w) / 2.0, VH - 42)
	btn.size = Vector2(btn_w, 36)
	btn.add_theme_font_size_override("font_size", 16)
	btn.pressed.connect(_on_return_button_pressed)
	_canvas.add_child(btn)

	# Stats summary — left of footer
	var stats := Label.new()
	stats.text = "Deepest: %dm  |  Bosses: %d" % [
		GameManager.deepest_row_reached * 50,
		GameManager.bosses_defeated_total]
	stats.position = Vector2(20, VH - 40)
	stats.size = Vector2(400, 24)
	stats.add_theme_font_size_override("font_size", 11)
	stats.add_theme_color_override("font_color", DIM_TEXT)
	_canvas.add_child(stats)


# ── Primitive builders ──────────────────────────────────────────────────────
func _panel_border(px: int, py: int) -> void:
	var b := ColorRect.new()
	b.position = Vector2(px - 2, py - 2)
	b.size     = Vector2(PANEL_W + 4, PANEL_H + 4)
	b.color    = PANEL_BORDER
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(b)


func _panel_body(px: int, py: int) -> void:
	var p := ColorRect.new()
	p.position = Vector2(px, py)
	p.size     = Vector2(PANEL_W, PANEL_H)
	p.color    = PANEL_BG
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(p)


func _divider(px: int, abs_y: int) -> void:
	var d := ColorRect.new()
	d.position = Vector2(px + 16, abs_y)
	d.size     = Vector2(PANEL_W - 32, 1)
	d.color    = PANEL_BORDER * Color(1, 1, 1, 0.6)
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.add_child(d)


func _label(text: String, x: int, y: int, w: int, h: int, font_size: int = 14) -> Label:
	var lbl := Label.new()
	lbl.text     = text
	lbl.position = Vector2(x, y)
	lbl.size     = Vector2(w, h)
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


# ── Spaceship upgrades ──────────────────────────────────────────────────────
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
		SoundManager.play_ui_click_sound()
		_refresh_chamber_panel()
		break


func _on_open_perk_tree_pressed() -> void:
	PerkTreeMenu._open()


func _on_return_button_pressed() -> void:
	GameManager.load_overworld()
