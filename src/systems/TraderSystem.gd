class_name TraderSystem
extends Node2D

## TraderSystem — manages wandering space trader NPCs.
## Extracted from MiningLevel to keep MiningLevel under 1,000 lines.
## Draws trader nodes via _draw() and owns the trader shop CanvasLayer.

const TRADER_CHECK_INTERVAL: int   = 10
const TRADER_FIRST_CHECK: int      = 15
const TRADER_SPAWN_CHANCE: float   = 0.15
const TRADER_MAX_PER_RUN: int      = 3
const TRADER_INTERACT_RADIUS: float = 128.0

const TRADER_ITEMS: Array = [
	{"key": "energy",   "label": "Fuel Cell Cache",    "desc": "+50 Fuel",                  "cost": 12, "tier": 1},
	{"key": "repair",   "label": "Spacesuit Patch",    "desc": "Restore 1 HP",              "cost": 18, "tier": 1},
	{"key": "shroom",   "label": "Astro Shroom",       "desc": "Next 12 ores yield +100%",  "cost": 30, "tier": 2},
	{"key": "compass",  "label": "Lucky Star Chart",   "desc": "2× Lucky Strike (run)",     "cost": 45, "tier": 3},
	{"key": "map",      "label": "Deep Space Map",     "desc": "2× Scanner radius (run)",   "cost": 65, "tier": 4},
]

const CELL_SIZE := 64

# Active traders: Array of {world_pos: Vector2, tier: int, pulse: float}
var _active_traders: Array = []
var _trader_last_check_row: int = 0
var _traders_spawned_count: int = 0

var _shop_layer: CanvasLayer = null
var _shop_visible: bool = false
var _current_trader: Dictionary = {}

# Callbacks provided by MiningLevel
var _player_node: Node = null
var _shroom_charges_ref: Array = [0]   # [int] — writable reference
var _lucky_compass_ref: Array = [false]
var _ancient_map_ref: Array = [false]

var shop_visible: bool:
	get:
		return _shop_visible


func setup(player_node: Node,
		shroom_ref: Array, compass_ref: Array, map_ref: Array) -> void:
	_player_node = player_node
	_shroom_charges_ref = shroom_ref
	_lucky_compass_ref  = compass_ref
	_ancient_map_ref    = map_ref


func check_milestone(depth_row: int) -> void:
	if depth_row < TRADER_FIRST_CHECK or _traders_spawned_count >= TRADER_MAX_PER_RUN:
		return
	var check_row := (depth_row / TRADER_CHECK_INTERVAL) * TRADER_CHECK_INTERVAL
	if check_row <= _trader_last_check_row:
		return
	_trader_last_check_row = check_row
	if randf() > TRADER_SPAWN_CHANCE:
		return
	var tier := clampi(depth_row / 32 + 1, 1, 4)
	_spawn_trader(tier)


func get_nearby_trader() -> Dictionary:
	if not _player_node:
		return {}
	for trader in _active_traders:
		if (_player_node.global_position - trader["world_pos"]).length() <= TRADER_INTERACT_RADIUS:
			return trader
	return {}


func _spawn_trader(tier: int) -> void:
	if not _player_node:
		return
	var spawn_pos: Vector2 = _player_node.global_position + Vector2(CELL_SIZE * 2.5, 0.0)
	_active_traders.append({"world_pos": spawn_pos, "tier": tier, "pulse": 0.0})
	_traders_spawned_count += 1
	EventBus.ore_mined_popup.emit(0, "Space Trader!")


func _process(delta: float) -> void:
	for trader in _active_traders:
		trader["pulse"] += delta
	queue_redraw()


func _draw() -> void:
	for trader in _active_traders:
		var tp: Vector2 = trader["world_pos"]
		var pulse: float = sin(trader["pulse"] * 3.0) * 0.5 + 0.5
		var trader_color := Color(1.0, 0.75 + pulse * 0.15, 0.0 + pulse * 0.15, 0.90)
		var radius := CELL_SIZE * 0.40 + pulse * 4.0
		draw_circle(tp, radius, trader_color)
		draw_arc(tp, radius + 3.0, 0.0, TAU, 24,
			Color(1.0, 0.95, 0.50, 0.55 + pulse * 0.35), 2.0)
		var font := ThemeDB.fallback_font
		draw_string(font, tp + Vector2(-6, 8), "T",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.10, 0.05, 0.00))


func show_shop(trader: Dictionary) -> void:
	if _shop_visible:
		return
	_current_trader = trader
	_shop_visible = true

	const VW: int = 1280
	const VH: int = 720
	const PANEL_W: int = 480
	const PX: int = (VW - PANEL_W) / 2

	var tier: int = trader.get("tier", 1)
	var available: Array = []
	for item in TRADER_ITEMS:
		if item["tier"] <= tier:
			available.append(item)

	var panel_h: int = 120 + available.size() * 54 + 54
	var py: int = (VH - panel_h) / 2

	_shop_layer = CanvasLayer.new()
	_shop_layer.layer = 10
	add_child(_shop_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_shop_layer.add_child(dim)

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, py - 3)
	border.size = Vector2(PANEL_W + 6, panel_h + 6)
	border.color = Color(0.85, 0.65, 0.10)
	_shop_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, py)
	panel.size = Vector2(PANEL_W, panel_h)
	panel.color = Color(0.08, 0.06, 0.03, 0.97)
	_shop_layer.add_child(panel)

	var title := Label.new()
	title.text = "Space Trader  —  Tier %d" % tier
	title.position = Vector2(PX, py + 10)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(1.0, 0.85, 0.20)
	_shop_layer.add_child(title)

	var minerals_label := Label.new()
	minerals_label.text = "Run Minerals: %d" % GameManager.run_mineral_currency
	minerals_label.position = Vector2(PX, py + 42)
	minerals_label.size = Vector2(PANEL_W, 22)
	minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_shop_layer.add_child(minerals_label)

	const BTN_W: int = PANEL_W - 60
	const BTN_X: int = PX + 30
	const BTN_H: int = 44
	var btn_y := py + 78
	for item in available:
		var btn := Button.new()
		btn.text = "%s — %s  (%d minerals)" % [item["label"], item["desc"], item["cost"]]
		btn.position = Vector2(BTN_X, btn_y)
		btn.size = Vector2(BTN_W, BTN_H)
		btn.pressed.connect(_purchase.bind(item["key"]))
		_shop_layer.add_child(btn)
		btn_y += BTN_H + 10

	var close_btn := Button.new()
	close_btn.text = "Farewell"
	close_btn.position = Vector2(BTN_X, btn_y + 4)
	close_btn.size = Vector2(BTN_W, BTN_H)
	close_btn.pressed.connect(close_shop)
	_shop_layer.add_child(close_btn)


func close_shop() -> void:
	if _shop_layer:
		_shop_layer.queue_free()
		_shop_layer = null
	_shop_visible = false
	_current_trader = {}


func _purchase(item_key: String) -> void:
	var item_def: Dictionary = {}
	for item in TRADER_ITEMS:
		if item["key"] == item_key:
			item_def = item
			break
	if item_def.is_empty():
		return

	var cost: int = item_def["cost"]
	if GameManager.run_mineral_currency < cost:
		EventBus.ore_mined_popup.emit(0, "Not enough minerals")
		return

	match item_key:
		"energy":
			GameManager.run_mineral_currency -= cost
			GameManager.restore_energy(50)
			EventBus.ore_mined_popup.emit(0, "Fuel Cell Pack!")
		"repair":
			if _player_node and _player_node.is_at_max_health():
				EventBus.ore_mined_popup.emit(0, "Already at full HP")
				return
			GameManager.run_mineral_currency -= cost
			_player_node.heal(1)
			EventBus.ore_mined_popup.emit(0, "Spacesuit Patched!")
		"shroom":
			GameManager.run_mineral_currency -= cost
			_shroom_charges_ref[0] += 12
			EventBus.ore_mined_popup.emit(0, "Astro Shroom!")
		"compass":
			GameManager.run_mineral_currency -= cost
			_lucky_compass_ref[0] = true
			EventBus.ore_mined_popup.emit(0, "Lucky Compass!")
		"map":
			GameManager.run_mineral_currency -= cost
			_ancient_map_ref[0] = true
			EventBus.ore_mined_popup.emit(0, "Deep Space Map!")

	EventBus.minerals_changed.emit(GameManager.run_mineral_currency)
	SoundManager.play_drill_sound()
	close_shop()
	# Re-open with updated state if trader still nearby
	var nearby := get_nearby_trader()
	if nearby.size() > 0:
		show_shop(nearby)
