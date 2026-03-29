class_name MiningShopSystem
extends Node

## MiningShopSystem — owns all shop CanvasLayer UIs for the mining level.
## Extracted from MiningLevel to keep MiningLevel under 1,000 lines.
##
## Shops managed:
##   • Energy Station (recharge, repair, buy ladders)
##   • Upgrade Station (permanent upgrades with dollars)
##   • Space Forge / Smeltery (smelt ores into bars, sell bars)
##   • Cat Tavern (hire Mining Cats and Collecting Cats using bars)

# ---------------------------------------------------------------------------
# Shop costs
# ---------------------------------------------------------------------------
## Shop costs in copper (100 copper = 1 silver).
const SHOP_REENERGY_FULL_COST: int = 1000   # 10s
const SHOP_REENERGY_HALF_COST: int = 500    # 5s
const SHOP_REPAIR_COST: int = 1500          # 15s
const SHOP_LADDER_PACK_COST: int = 2000     # 20s — buys 10 ladders
const SHOP_LADDER_PACK_COUNT: int = 10

# Cat Tavern hire costs (in bars)
const CAT_TAVERN_MINING_CAT_COPPER_BARS: int = 0
const CAT_TAVERN_MINING_CAT_IRON_BARS: int = 2
const CAT_TAVERN_COLLECT_CAT_COPPER_BARS: int = 2
const CAT_TAVERN_COLLECT_CAT_IRON_BARS: int = 0
const CAT_MAX_MINING: int = 3
const CAT_MAX_COLLECTING: int = 3

# Smeltery constants (kept here as they're only used by this system)
const SMELTERY_ORE_GROUPS_ORDER: Array = ["coal", "copper", "iron", "gold", "diamond"]
const SMELTERY_ORE_GROUP_TILES: Dictionary = {
	"coal":    [3],   # ORE_COAL
	"copper":  [4],   # ORE_COPPER
	"iron":    [5],   # ORE_IRON
	"gold":    [6],   # ORE_GOLD
	"diamond": [7],   # ORE_DIAMOND
}
const SMELTERY_ORES_PER_BAR: int = 3
## Bar sell values in minerals.
const SMELTERY_BAR_SELL_VALUES: Dictionary = {
	"coal": 500, "copper": 1500, "iron": 3000, "gold": 5000, "diamond": 8000,
}
const SMELTERY_BAR_NAMES: Dictionary = {
	"coal": "Coal Brick", "copper": "Lunar Bar", "iron": "Meteor Bar", "gold": "Star Bar", "diamond": "Cosmic Bar",
}
const SMELTERY_GROUP_COLORS: Dictionary = {
	"coal":    Color(0.25, 0.25, 0.28),
	"copper":  Color(0.90, 0.60, 0.25),
	"iron":    Color(0.65, 0.68, 0.75),
	"gold":    Color(1.00, 0.80, 0.10),
	"diamond": Color(0.60, 0.90, 1.00),
}

const VW: int = 1280
const VH: int = 720

# ---------------------------------------------------------------------------
# External references set by MiningLevel
# ---------------------------------------------------------------------------
var player_node: Node = null
var cat_system: CatSystem = null

# Run-scope bar data (owned here, shared with MiningLevel)
var run_bar_counts: Dictionary = {}    # ore_group -> bars smelted this run

# Visibility flags polled by MiningLevel._physics_process / _unhandled_input
var energy_shop_visible: bool = false
var upgrade_station_visible: bool = false
var smeltery_visible: bool = false
var cat_tavern_visible: bool = false

# ---------------------------------------------------------------------------
# UI node references
# ---------------------------------------------------------------------------
var _energy_layer: CanvasLayer
var _energy_minerals_label: Label
var _energy_btn_full: Button
var _energy_btn_half: Button
var _energy_btn_repair: Button
var _energy_btn_ladders: Button

var _upgrade_layer: CanvasLayer
var _upgrade_minerals_label: Label

var _smeltery_layer: CanvasLayer
var _smeltery_minerals_label: Label
var _smeltery_ore_labels: Dictionary = {}
var _smeltery_bar_labels: Dictionary = {}
var _smeltery_smelt_btns: Dictionary = {}
var _smeltery_sell_btns: Dictionary = {}

var _cat_tavern_layer: CanvasLayer
var _cat_tavern_label: Label
var _cat_tavern_btn_mining: Button
var _cat_tavern_btn_collecting: Button


func setup(p_player_node: Node, p_cat_system: CatSystem) -> void:
	player_node = p_player_node
	cat_system = p_cat_system
	_build_energy_shop()
	_build_upgrade_station()
	_build_smeltery()
	_build_cat_tavern()


func any_shop_open() -> bool:
	return energy_shop_visible or upgrade_station_visible \
		or smeltery_visible or cat_tavern_visible


func close_active_shop() -> void:
	if smeltery_visible:
		hide_smeltery()
	elif energy_shop_visible:
		hide_energy_shop()
	elif upgrade_station_visible:
		hide_upgrade_station()
	elif cat_tavern_visible:
		hide_cat_tavern()


# ---------------------------------------------------------------------------
# Ore count helpers (used by smeltery and cat tavern)
# ---------------------------------------------------------------------------

func get_ore_group_count(ore_group: String) -> int:
	var total := 0
	for tile_type in SMELTERY_ORE_GROUP_TILES[ore_group]:
		total += GameManager.run_ore_chunk_counts.get(tile_type, 0)
	return total


func consume_ores_for_smelt(ore_group: String, count: int) -> void:
	var remaining := count
	for tile_type in SMELTERY_ORE_GROUP_TILES[ore_group]:
		var have: int = GameManager.run_ore_chunk_counts.get(tile_type, 0)
		if have <= 0:
			continue
		var take := mini(have, remaining)
		GameManager.run_ore_chunk_counts[tile_type] = have - take
		remaining -= take
		if remaining <= 0:
			break


# ---------------------------------------------------------------------------
# Energy Station Shop
# ---------------------------------------------------------------------------

func _build_energy_shop() -> void:
	const PANEL_W: int = 420
	const PANEL_H: int = 380
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_energy_layer = CanvasLayer.new()
	_energy_layer.layer = 10
	_energy_layer.visible = false
	add_child(_energy_layer)

	_energy_layer.add_child(_dim_rect())

	UIHelper.create_bordered_panel(_energy_layer, PX, PY, PANEL_W, PANEL_H,
		Color(0.20, 0.60, 0.90), Color(0.07, 0.10, 0.14, 0.97))

	var title := Label.new()
	title.text = "Recharging Station"
	title.position = Vector2(PX, PY + 12)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.55, 0.85, 1.0)
	_energy_layer.add_child(title)

	_energy_minerals_label = Label.new()
	_energy_minerals_label.position = Vector2(PX, PY + 48)
	_energy_minerals_label.size = Vector2(PANEL_W, 24)
	_energy_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_energy_layer.add_child(_energy_minerals_label)

	const BTN_X: int = PX + 25
	const BTN_W: int = PANEL_W - 50
	const BTN_H: int = 46

	_energy_btn_full = _make_btn(BTN_X, PY + 86, BTN_W, BTN_H, "", _shop_reenergy_full)
	_energy_layer.add_child(_energy_btn_full)

	_energy_btn_half = _make_btn(BTN_X, PY + 142, BTN_W, BTN_H, "", _shop_reenergy_half)
	_energy_layer.add_child(_energy_btn_half)

	_energy_btn_repair = _make_btn(BTN_X, PY + 198, BTN_W, BTN_H, "", _shop_repair)
	_energy_layer.add_child(_energy_btn_repair)

	_energy_btn_ladders = _make_btn(BTN_X, PY + 254, BTN_W, BTN_H,
		"Buy %d Ladders  —  %s" % [SHOP_LADDER_PACK_COUNT, GameManager.format_coins(SHOP_LADDER_PACK_COST)],
		_shop_buy_ladders)
	_energy_layer.add_child(_energy_btn_ladders)

	_energy_layer.add_child(
		_make_btn(BTN_X + (BTN_W - 180) / 2, PY + 326, 180, 40, "Close Shop", hide_energy_shop))


func show_energy_shop() -> void:
	_energy_minerals_label.text = GameManager.format_coins(GameManager.coins)
	var max_e := GameManager.get_max_energy()
	_energy_btn_full.text = "Full Rest  (%d→%d energy)  — %s" % [
		GameManager.current_energy, max_e, GameManager.format_coins(SHOP_REENERGY_FULL_COST)]
	_energy_btn_half.text = "Rest 50%%  (+%d energy)  — %s" % [
		max_e / 2, GameManager.format_coins(SHOP_REENERGY_HALF_COST)]
	_energy_btn_repair.text = "Pelt Patch (+1 HP)  — %s" % GameManager.format_coins(SHOP_REPAIR_COST)
	_energy_btn_full.disabled   = GameManager.coins < SHOP_REENERGY_FULL_COST or GameManager.current_energy >= max_e
	_energy_btn_half.disabled   = GameManager.coins < SHOP_REENERGY_HALF_COST or GameManager.current_energy >= max_e
	_energy_btn_repair.disabled = GameManager.coins < SHOP_REPAIR_COST or (player_node != null and player_node.is_at_max_health())
	_energy_btn_ladders.disabled = GameManager.coins < SHOP_LADDER_PACK_COST
	_energy_layer.visible = true
	energy_shop_visible = true


func hide_energy_shop() -> void:
	_energy_layer.visible = false
	energy_shop_visible = false


func _shop_reenergy_full() -> void:
	if GameManager.coins >= SHOP_REENERGY_FULL_COST:
		GameManager.coins -= SHOP_REENERGY_FULL_COST
		GameManager.current_energy = GameManager.get_max_energy()
		EventBus.coins_changed.emit(GameManager.coins)
		EventBus.energy_changed.emit(GameManager.current_energy, GameManager.get_max_energy())
		GameManager.save_game()
		SoundManager.play_purchase_confirm_sound()
		show_energy_shop()


func _shop_reenergy_half() -> void:
	if GameManager.coins >= SHOP_REENERGY_HALF_COST:
		GameManager.coins -= SHOP_REENERGY_HALF_COST
		GameManager.restore_energy(GameManager.get_max_energy() / 2)
		EventBus.coins_changed.emit(GameManager.coins)
		GameManager.save_game()
		SoundManager.play_purchase_confirm_sound()
		show_energy_shop()


func _shop_repair() -> void:
	if GameManager.coins >= SHOP_REPAIR_COST and player_node:
		GameManager.coins -= SHOP_REPAIR_COST
		EventBus.coins_changed.emit(GameManager.coins)
		GameManager.save_game()
		player_node.heal(1)
		SoundManager.play_purchase_confirm_sound()
		show_energy_shop()


func _shop_buy_ladders() -> void:
	if GameManager.coins >= SHOP_LADDER_PACK_COST:
		GameManager.coins -= SHOP_LADDER_PACK_COST
		GameManager.ladder_count += SHOP_LADDER_PACK_COUNT
		EventBus.ladder_count_changed.emit(GameManager.ladder_count)
		EventBus.coins_changed.emit(GameManager.coins)
		GameManager.save_game()
		EventBus.ore_mined_popup.emit(SHOP_LADDER_PACK_COUNT, "Ladders acquired!")
		SoundManager.play_purchase_confirm_sound()
		show_energy_shop()


# ---------------------------------------------------------------------------
# Upgrade Station — redirects to Perk Tree (upgrades replaced by perk system)
# ---------------------------------------------------------------------------

func _build_upgrade_station() -> void:
	const PANEL_W: int = 480
	const PANEL_H: int = 280
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_upgrade_layer = CanvasLayer.new()
	_upgrade_layer.layer = 10
	_upgrade_layer.visible = false
	add_child(_upgrade_layer)

	_upgrade_layer.add_child(_dim_rect())

	UIHelper.create_bordered_panel(_upgrade_layer, PX, PY, PANEL_W, PANEL_H,
		Color(0.45, 0.30, 0.80), Color(0.06, 0.04, 0.14, 0.97))

	var title := Label.new()
	title.text = "Upgrade Bay"
	title.position = Vector2(PX, PY + 14)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.80, 0.60, 1.00)
	_upgrade_layer.add_child(title)

	var sub := Label.new()
	sub.text = "Upgrades are now handled through the Perk Tree."
	sub.position = Vector2(PX + 20, PY + 54)
	sub.size = Vector2(PANEL_W - 40, 22)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.modulate = Color(0.75, 0.70, 0.85)
	_upgrade_layer.add_child(sub)

	_upgrade_minerals_label = Label.new()
	_upgrade_minerals_label.position = Vector2(PX + 20, PY + 84)
	_upgrade_minerals_label.size = Vector2(PANEL_W - 40, 24)
	_upgrade_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_minerals_label.modulate = Color(1.0, 0.85, 0.20)
	_upgrade_layer.add_child(_upgrade_minerals_label)

	var hint := Label.new()
	hint.text = "Press  [P]  to open the Perk Tree at any time."
	hint.position = Vector2(PX + 20, PY + 120)
	hint.size = Vector2(PANEL_W - 40, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.modulate = Color(0.50, 0.90, 0.55)
	_upgrade_layer.add_child(hint)

	var open_btn := Button.new()
	open_btn.text = "Open Perk Tree  [P]"
	open_btn.position = Vector2(PX + (PANEL_W - 220) / 2, PY + 160)
	open_btn.size = Vector2(220, 44)
	open_btn.add_theme_font_size_override("font_size", 16)
	open_btn.pressed.connect(func() -> void:
		hide_upgrade_station()
		PerkTreeMenu._open())
	_upgrade_layer.add_child(open_btn)

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.position = Vector2(PX + (PANEL_W - 140) / 2, PY + 216)
	close_btn.size = Vector2(140, 38)
	close_btn.pressed.connect(hide_upgrade_station)
	_upgrade_layer.add_child(close_btn)


## Upgrade costs in copper: base 5000 (50s), scaling +2500 per level.
## Whiskers/reach base 7500 (75s), scaling +2500 per level.
func show_upgrade_station() -> void:
	_upgrade_minerals_label.text = "Level %d  |  %d Perk Point%s  |  %s" % [
		GameManager.player_level,
		GameManager.perk_points,
		"s" if GameManager.perk_points != 1 else "",
		GameManager.format_coins(GameManager.coins),
	]
	_upgrade_layer.visible = true
	upgrade_station_visible = true


func hide_upgrade_station() -> void:
	_upgrade_layer.visible = false
	upgrade_station_visible = false


# ---------------------------------------------------------------------------
# Smeltery / Space Forge
# ---------------------------------------------------------------------------

func _build_smeltery() -> void:
	const PANEL_W: int = 520
	const PANEL_H: int = 420
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_smeltery_layer = CanvasLayer.new()
	_smeltery_layer.layer = 10
	_smeltery_layer.visible = false
	add_child(_smeltery_layer)

	_smeltery_layer.add_child(_dim_rect())

	UIHelper.create_bordered_panel(_smeltery_layer, PX, PY, PANEL_W, PANEL_H,
		Color(1.0, 0.55, 0.0), Color(0.12, 0.08, 0.04, 0.97))

	var title := Label.new()
	title.text = "Space Forge"
	title.position = Vector2(PX, PY + 10)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.65, 0.15)
	_smeltery_layer.add_child(title)

	_smeltery_minerals_label = Label.new()
	_smeltery_minerals_label.position = Vector2(PX, PY + 40)
	_smeltery_minerals_label.size = Vector2(PANEL_W, 22)
	_smeltery_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_smeltery_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_smeltery_layer.add_child(_smeltery_minerals_label)

	var row_y := PY + 100
	const ROW_H: int = 58
	for ore_group in SMELTERY_ORE_GROUPS_ORDER:
		var gc: Color = SMELTERY_GROUP_COLORS[ore_group]

		var ore_lbl := Label.new()
		ore_lbl.position = Vector2(PX + 15, row_y + 4)
		ore_lbl.size = Vector2(90, 24)
		ore_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ore_lbl.modulate = gc
		_smeltery_layer.add_child(ore_lbl)
		_smeltery_ore_labels[ore_group] = ore_lbl

		var smelt_btn := Button.new()
		smelt_btn.position = Vector2(PX + 110, row_y)
		smelt_btn.size = Vector2(140, 36)
		smelt_btn.pressed.connect(_smeltery_smelt.bind(ore_group))
		_smeltery_layer.add_child(smelt_btn)
		_smeltery_smelt_btns[ore_group] = smelt_btn

		var bar_lbl := Label.new()
		bar_lbl.position = Vector2(PX + 260, row_y + 4)
		bar_lbl.size = Vector2(90, 24)
		bar_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bar_lbl.modulate = gc
		_smeltery_layer.add_child(bar_lbl)
		_smeltery_bar_labels[ore_group] = bar_lbl

		var sell_btn := Button.new()
		sell_btn.position = Vector2(PX + 355, row_y)
		sell_btn.size = Vector2(150, 36)
		sell_btn.pressed.connect(_smeltery_sell.bind(ore_group))
		_smeltery_layer.add_child(sell_btn)
		_smeltery_sell_btns[ore_group] = sell_btn

		row_y += ROW_H

	_smeltery_layer.add_child(
		_make_btn(PX + (PANEL_W - 200) / 2, row_y + 16, 200, 40, "Close Forge", hide_smeltery))


func show_smeltery() -> void:
	_smeltery_minerals_label.text = GameManager.format_coins(GameManager.coins)
	for ore_group in SMELTERY_ORE_GROUPS_ORDER:
		var ore_count := get_ore_group_count(ore_group)
		var bar_count: int = run_bar_counts.get(ore_group, 0)
		_smeltery_ore_labels[ore_group].text = "%s: %d" % [ore_group.capitalize(), ore_count]
		var bars_possible: int = ore_count / SMELTERY_ORES_PER_BAR
		_smeltery_smelt_btns[ore_group].text = "Smelt All (%d ore → %d bar%s)" % [bars_possible * SMELTERY_ORES_PER_BAR, bars_possible, "s" if bars_possible != 1 else ""]
		_smeltery_smelt_btns[ore_group].disabled = ore_count < SMELTERY_ORES_PER_BAR
		_smeltery_bar_labels[ore_group].text = "%s: %d" % [SMELTERY_BAR_NAMES[ore_group], bar_count]
		var sell_per_bar: int = roundi(SMELTERY_BAR_SELL_VALUES[ore_group] * GameManager.get_dollar_sell_mult())
		var sell_total: int = sell_per_bar * bar_count
		_smeltery_sell_btns[ore_group].text = "Sell All (%s/bar | %s total)" % [
			GameManager.format_coins(sell_per_bar), GameManager.format_coins(sell_total)]
		_smeltery_sell_btns[ore_group].disabled = bar_count <= 0
	_smeltery_layer.visible = true
	smeltery_visible = true


func hide_smeltery() -> void:
	_smeltery_layer.visible = false
	smeltery_visible = false


func _smeltery_smelt(ore_group: String) -> void:
	var ore_count := get_ore_group_count(ore_group)
	if ore_count < SMELTERY_ORES_PER_BAR:
		return
	var bars_to_smelt: int = ore_count / SMELTERY_ORES_PER_BAR
	consume_ores_for_smelt(ore_group, bars_to_smelt * SMELTERY_ORES_PER_BAR)
	run_bar_counts[ore_group] = run_bar_counts.get(ore_group, 0) + bars_to_smelt
	SoundManager.play_drill_sound()
	EventBus.ore_mined_popup.emit(0, "%d %s smelted!" % [bars_to_smelt, SMELTERY_BAR_NAMES[ore_group]])
	show_smeltery()


func _smeltery_sell(ore_group: String) -> void:
	var bar_count: int = run_bar_counts.get(ore_group, 0)
	if bar_count <= 0:
		return
	# sell_value is in copper (SMELTERY_BAR_SELL_VALUES already denominated in copper)
	var sell_value: int = roundi(SMELTERY_BAR_SELL_VALUES[ore_group] * GameManager.get_dollar_sell_mult()) * bar_count
	run_bar_counts[ore_group] = 0
	GameManager.add_coins_direct(sell_value)
	SoundManager.play_purchase_confirm_sound()
	EventBus.ore_mined_popup.emit(0, "%d %s sold! +%s" % [bar_count, SMELTERY_BAR_NAMES[ore_group], GameManager.format_coins(sell_value)])
	show_smeltery()


# ---------------------------------------------------------------------------
# Cat Tavern — underground shop; payment in smelted bars
# ---------------------------------------------------------------------------

func _build_cat_tavern() -> void:
	const PANEL_W: int = 480
	const PANEL_H: int = 310
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_cat_tavern_layer = CanvasLayer.new()
	_cat_tavern_layer.layer = 10
	_cat_tavern_layer.visible = false
	add_child(_cat_tavern_layer)

	_cat_tavern_layer.add_child(_dim_rect())

	UIHelper.create_bordered_panel(_cat_tavern_layer, PX, PY, PANEL_W, PANEL_H,
		Color(0.80, 0.55, 0.10), Color(0.08, 0.06, 0.03, 0.97))

	var title := Label.new()
	title.text = "The Cat Tavern"
	title.position = Vector2(PX, PY + 10)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = Color(1.0, 0.75, 0.20)
	_cat_tavern_layer.add_child(title)

	_cat_tavern_label = Label.new()
	_cat_tavern_label.position = Vector2(PX, PY + 48)
	_cat_tavern_label.size = Vector2(PANEL_W, 48)
	_cat_tavern_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cat_tavern_label.modulate = Color(0.85, 0.85, 0.85)
	_cat_tavern_layer.add_child(_cat_tavern_label)

	const BTN_X: int = PX + 25
	const BTN_W: int = PANEL_W - 50
	const BTN_H: int = 52

	_cat_tavern_btn_mining = _make_btn(BTN_X, PY + 104, BTN_W, BTN_H,
		"Hire Mining Cat  —  2 Meteor Bars\n(Mines ore autonomously near hire point)",
		_tavern_hire_mining)
	_cat_tavern_layer.add_child(_cat_tavern_btn_mining)

	_cat_tavern_btn_collecting = _make_btn(BTN_X, PY + 168, BTN_W, BTN_H,
		"Hire Collecting Cat  —  2 Lunar Bars\n(Gathers ore chunks & banks them at surface)",
		_tavern_hire_collecting)
	_cat_tavern_layer.add_child(_cat_tavern_btn_collecting)

	_cat_tavern_layer.add_child(
		_make_btn(BTN_X + (BTN_W - 180) / 2, PY + 252, 180, 40, "Leave Tavern", hide_cat_tavern))


func show_cat_tavern() -> void:
	var copper_bars: int = run_bar_counts.get("copper", 0)
	var iron_bars: int   = run_bar_counts.get("iron", 0)
	var mining_count := cat_system.get_mining_cat_count() if cat_system else 0
	var collect_count := cat_system.get_collecting_cat_count() if cat_system else 0

	_cat_tavern_label.text = "Lunar Bars: %d  |  Meteor Bars: %d\nHired: %d mining, %d collecting" % [
		copper_bars, iron_bars, mining_count, collect_count]

	_cat_tavern_btn_mining.disabled = iron_bars < CAT_TAVERN_MINING_CAT_IRON_BARS \
		or mining_count >= CAT_MAX_MINING
	_cat_tavern_btn_collecting.disabled = copper_bars < CAT_TAVERN_COLLECT_CAT_COPPER_BARS \
		or collect_count >= CAT_MAX_COLLECTING

	_cat_tavern_layer.visible = true
	cat_tavern_visible = true


func hide_cat_tavern() -> void:
	_cat_tavern_layer.visible = false
	cat_tavern_visible = false


func _tavern_hire_mining() -> void:
	if run_bar_counts.get("iron", 0) < CAT_TAVERN_MINING_CAT_IRON_BARS:
		return
	if cat_system and cat_system.get_mining_cat_count() >= CAT_MAX_MINING:
		return
	run_bar_counts["iron"] = run_bar_counts.get("iron", 0) - CAT_TAVERN_MINING_CAT_IRON_BARS
	if cat_system and player_node:
		cat_system.hire(CatSystem.CatRole.MINING, player_node.global_position + Vector2(64, 0))
	SoundManager.play_purchase_confirm_sound()
	show_cat_tavern()


func _tavern_hire_collecting() -> void:
	if run_bar_counts.get("copper", 0) < CAT_TAVERN_COLLECT_CAT_COPPER_BARS:
		return
	if cat_system and cat_system.get_collecting_cat_count() >= CAT_MAX_COLLECTING:
		return
	run_bar_counts["copper"] = run_bar_counts.get("copper", 0) - CAT_TAVERN_COLLECT_CAT_COPPER_BARS
	if cat_system and player_node:
		cat_system.hire(CatSystem.CatRole.COLLECTING, player_node.global_position + Vector2(-64, 0))
	SoundManager.play_purchase_confirm_sound()
	show_cat_tavern()


# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

func _dim_rect() -> ColorRect:
	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0, 0, 0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	return dim


func _make_btn(x: int, y: int, w: int, h: int, label: String, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = Vector2(x, y)
	btn.size = Vector2(w, h)
	btn.pressed.connect(cb)
	return btn
