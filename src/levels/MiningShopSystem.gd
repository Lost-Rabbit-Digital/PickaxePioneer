class_name MiningShopSystem
extends Node

## MiningShopSystem — owns all shop CanvasLayer UIs for the mining level.
## Extracted from MiningLevel to keep MiningLevel under 1,000 lines.
##
## Shops managed:
##   • Surface Hub (bank & end-run panel)
##   • Energy Station (recharge, repair, buy ladders)
##   • Upgrade Station (permanent upgrades with dollars)
##   • Space Forge / Smeltery (smelt ores into bars, sell bars)
##   • Cat Tavern (hire Mining Cats and Collecting Cats using bars)

# ---------------------------------------------------------------------------
# Shop costs
# ---------------------------------------------------------------------------
const SHOP_REENERGY_FULL_COST: int = 10
const SHOP_REENERGY_HALF_COST: int = 5
const SHOP_REPAIR_COST: int = 15
const SHOP_LADDER_PACK_COST: int = 20   # buys 10 ladders
const SHOP_LADDER_PACK_COUNT: int = 10

# Cat Tavern hire costs (in bars)
const CAT_TAVERN_MINING_CAT_COPPER_BARS: int = 0
const CAT_TAVERN_MINING_CAT_IRON_BARS: int = 2
const CAT_TAVERN_COLLECT_CAT_COPPER_BARS: int = 2
const CAT_TAVERN_COLLECT_CAT_IRON_BARS: int = 0
const CAT_MAX_MINING: int = 3
const CAT_MAX_COLLECTING: int = 3

# Smeltery constants (kept here as they're only used by this system)
const SMELTERY_ORE_GROUPS_ORDER: Array = ["copper", "iron", "gold", "gem"]
const SMELTERY_ORE_GROUP_TILES: Dictionary = {
	"copper": [3, 4],   # ORE_COPPER, ORE_COPPER_DEEP
	"iron":   [5, 6],
	"gold":   [7, 8],
	"gem":    [9, 10],
}
const SMELTERY_ORES_PER_BAR: int = 3
const SMELTERY_BAR_SELL_VALUES: Dictionary = {
	"copper": 15, "iron": 30, "gold": 50, "gem": 75,
}
const SMELTERY_BAR_NAMES: Dictionary = {
	"copper": "Lunar Bar", "iron": "Meteor Bar", "gold": "Star Bar", "gem": "Cosmic Bar",
}
const SMELTERY_GROUP_COLORS: Dictionary = {
	"copper": Color(0.90, 0.60, 0.25),
	"iron":   Color(0.90, 0.45, 0.70),
	"gold":   Color(0.85, 0.80, 1.00),
	"gem":    Color(0.20, 0.90, 0.95),
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
var hub_visible: bool = false
var energy_shop_visible: bool = false
var upgrade_station_visible: bool = false
var smeltery_visible: bool = false
var cat_tavern_visible: bool = false

# ---------------------------------------------------------------------------
# UI node references
# ---------------------------------------------------------------------------
var _hub_layer: CanvasLayer
var _hub_minerals_label: Label

var _energy_layer: CanvasLayer
var _energy_minerals_label: Label
var _energy_btn_full: Button
var _energy_btn_half: Button
var _energy_btn_repair: Button
var _energy_btn_ladders: Button

var _upgrade_layer: CanvasLayer
var _upgrade_minerals_label: Label
var _upgrade_btn_carapace: Button
var _upgrade_btn_legs: Button
var _upgrade_btn_mandibles: Button

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

# Overlay for permanent upgrade panel (opened from hub)
var _upgrade_overlay_layer: CanvasLayer = null


func setup(p_player_node: Node, p_cat_system: CatSystem) -> void:
	player_node = p_player_node
	cat_system = p_cat_system
	_build_hub()
	_build_energy_shop()
	_build_upgrade_station()
	_build_smeltery()
	_build_cat_tavern()


func any_shop_open() -> bool:
	return hub_visible or energy_shop_visible or upgrade_station_visible \
		or smeltery_visible or cat_tavern_visible or _upgrade_overlay_layer != null


func close_active_shop() -> void:
	if smeltery_visible:
		hide_smeltery()
	elif energy_shop_visible:
		hide_energy_shop()
	elif upgrade_station_visible:
		hide_upgrade_station()
	elif cat_tavern_visible:
		hide_cat_tavern()
	elif _upgrade_overlay_layer != null:
		_close_upgrade_overlay()


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
# Surface Hub
# ---------------------------------------------------------------------------

func _build_hub() -> void:
	const PANEL_W: int = 460
	const PANEL_H: int = 310
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_hub_layer = CanvasLayer.new()
	_hub_layer.layer = 10
	_hub_layer.visible = false
	add_child(_hub_layer)

	_hub_layer.add_child(_dim_rect())

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.30, 0.70, 0.25)
	_hub_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.09, 0.08, 0.06, 0.97)
	_hub_layer.add_child(panel)

	var title := Label.new()
	title.text = "You reached the station!"
	title.position = Vector2(PX, PY + 14)
	title.size = Vector2(PANEL_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_layer.add_child(title)

	_hub_minerals_label = Label.new()
	_hub_minerals_label.position = Vector2(PX, PY + 50)
	_hub_minerals_label.size = Vector2(PANEL_W, 28)
	_hub_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hub_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_hub_layer.add_child(_hub_minerals_label)

	const BTN_X: int = PX + 30
	const BTN_W: int = PANEL_W - 60
	const BTN_H: int = 46

	var bank_btn := Button.new()
	bank_btn.text = "Bank Minerals & Keep Exploring"
	bank_btn.position = Vector2(BTN_X, PY + 100)
	bank_btn.size = Vector2(BTN_W, BTN_H)
	bank_btn.pressed.connect(_hub_bank_and_continue)
	_hub_layer.add_child(bank_btn)

	var shop_btn := Button.new()
	shop_btn.text = "Open Station Shop (banks minerals)"
	shop_btn.position = Vector2(BTN_X, PY + 156)
	shop_btn.size = Vector2(BTN_W, BTN_H)
	shop_btn.pressed.connect(_hub_open_shop)
	_hub_layer.add_child(shop_btn)

	var end_btn := Button.new()
	end_btn.text = "End Run & Return to Station"
	end_btn.position = Vector2(BTN_X, PY + 212)
	end_btn.size = Vector2(BTN_W, BTN_H)
	end_btn.pressed.connect(_hub_end_run)
	_hub_layer.add_child(end_btn)


func show_hub() -> void:
	_hub_minerals_label.text = "Minerals this run: %d" % GameManager.run_mineral_currency
	_hub_layer.visible = true
	hub_visible = true


func hide_hub() -> void:
	_hub_layer.visible = false
	hub_visible = false


func _hub_bank_and_continue() -> void:
	GameManager.bank_currency()
	hide_hub()


func _hub_open_shop() -> void:
	GameManager.bank_currency()
	hide_hub()
	_open_upgrade_overlay()


func _hub_end_run() -> void:
	hide_hub()
	GameManager.complete_run()


func _open_upgrade_overlay() -> void:
	_upgrade_overlay_layer = CanvasLayer.new()
	_upgrade_overlay_layer.layer = 10
	add_child(_upgrade_overlay_layer)

	var dim := ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(VW, VH)
	dim.color = Color(0, 0, 0, 0.75)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_upgrade_overlay_layer.add_child(dim)

	var upgrade_scene := load("res://src/ui/UpgradeMenu.tscn") as PackedScene
	if upgrade_scene:
		var menu: Node = upgrade_scene.instantiate()
		if menu is Control:
			(menu as Control).set_anchors_preset(Control.PRESET_CENTER)
		_upgrade_overlay_layer.add_child(menu)

	var close_btn := Button.new()
	close_btn.text = "Continue Mining"
	close_btn.position = Vector2((VW - 260) / 2, VH - 70)
	close_btn.size = Vector2(260, 44)
	close_btn.pressed.connect(_close_upgrade_overlay)
	_upgrade_overlay_layer.add_child(close_btn)


func _close_upgrade_overlay() -> void:
	if _upgrade_overlay_layer:
		_upgrade_overlay_layer.queue_free()
		_upgrade_overlay_layer = null


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

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.20, 0.60, 0.90)
	_energy_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.07, 0.10, 0.14, 0.97)
	_energy_layer.add_child(panel)

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
		"Buy %d Ladders  —  $%d" % [SHOP_LADDER_PACK_COUNT, SHOP_LADDER_PACK_COST],
		_shop_buy_ladders)
	_energy_layer.add_child(_energy_btn_ladders)

	_energy_layer.add_child(
		_make_btn(BTN_X + (BTN_W - 180) / 2, PY + 326, 180, 40, "Close Shop", hide_energy_shop))


func show_energy_shop() -> void:
	_energy_minerals_label.text = "$%d" % GameManager.dollars
	var max_e := GameManager.get_max_energy()
	_energy_btn_full.text = "Full Rest  (%d→%d energy)  — $%d" % [
		GameManager.current_energy, max_e, SHOP_REENERGY_FULL_COST]
	_energy_btn_half.text = "Rest 50%%  (+%d energy)  — $%d" % [
		max_e / 2, SHOP_REENERGY_HALF_COST]
	_energy_btn_repair.text = "+1 Health Bar  — $%d" % SHOP_REPAIR_COST
	_energy_btn_full.disabled   = GameManager.dollars < SHOP_REENERGY_FULL_COST or GameManager.current_energy >= max_e
	_energy_btn_half.disabled   = GameManager.dollars < SHOP_REENERGY_HALF_COST or GameManager.current_energy >= max_e
	_energy_btn_repair.disabled = GameManager.dollars < SHOP_REPAIR_COST or (player_node != null and player_node.is_at_max_health())
	_energy_btn_ladders.disabled = GameManager.dollars < SHOP_LADDER_PACK_COST
	_energy_layer.visible = true
	energy_shop_visible = true


func hide_energy_shop() -> void:
	_energy_layer.visible = false
	energy_shop_visible = false


func _shop_reenergy_full() -> void:
	if GameManager.dollars >= SHOP_REENERGY_FULL_COST:
		GameManager.dollars -= SHOP_REENERGY_FULL_COST
		GameManager.current_energy = GameManager.get_max_energy()
		EventBus.dollars_changed.emit(GameManager.dollars)
		EventBus.energy_changed.emit(GameManager.current_energy, GameManager.get_max_energy())
		GameManager.save_game()
		SoundManager.play_drill_sound()
		show_energy_shop()


func _shop_reenergy_half() -> void:
	if GameManager.dollars >= SHOP_REENERGY_HALF_COST:
		GameManager.dollars -= SHOP_REENERGY_HALF_COST
		GameManager.restore_energy(GameManager.get_max_energy() / 2)
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.save_game()
		SoundManager.play_drill_sound()
		show_energy_shop()


func _shop_repair() -> void:
	if GameManager.dollars >= SHOP_REPAIR_COST and player_node:
		GameManager.dollars -= SHOP_REPAIR_COST
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.save_game()
		player_node.heal(1)
		SoundManager.play_drill_sound()
		show_energy_shop()


func _shop_buy_ladders() -> void:
	if GameManager.dollars >= SHOP_LADDER_PACK_COST:
		GameManager.dollars -= SHOP_LADDER_PACK_COST
		GameManager.ladder_count += SHOP_LADDER_PACK_COUNT
		EventBus.ladder_count_changed.emit(GameManager.ladder_count)
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.save_game()
		EventBus.ore_mined_popup.emit(SHOP_LADDER_PACK_COUNT, "Ladders acquired!")
		SoundManager.play_drill_sound()
		show_energy_shop()


# ---------------------------------------------------------------------------
# Upgrade Station Shop
# ---------------------------------------------------------------------------

func _build_upgrade_station() -> void:
	const PANEL_W: int = 500
	const PANEL_H: int = 360
	const PX: int = (VW - PANEL_W) / 2
	const PY: int = (VH - PANEL_H) / 2

	_upgrade_layer = CanvasLayer.new()
	_upgrade_layer.layer = 10
	_upgrade_layer.visible = false
	add_child(_upgrade_layer)

	_upgrade_layer.add_child(_dim_rect())

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.30, 0.85, 0.50)
	_upgrade_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.07, 0.12, 0.09, 0.97)
	_upgrade_layer.add_child(panel)

	var title := Label.new()
	title.text = "Upgrade Bay"
	title.position = Vector2(PX, PY + 12)
	title.size = Vector2(PANEL_W, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(0.55, 1.0, 0.70)
	_upgrade_layer.add_child(title)

	_upgrade_minerals_label = Label.new()
	_upgrade_minerals_label.position = Vector2(PX, PY + 48)
	_upgrade_minerals_label.size = Vector2(PANEL_W, 24)
	_upgrade_minerals_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_upgrade_minerals_label.modulate = Color(1.0, 0.85, 0.2)
	_upgrade_layer.add_child(_upgrade_minerals_label)

	const BTN_X: int = PX + 25
	const BTN_W: int = PANEL_W - 50
	const BTN_H: int = 52

	_upgrade_btn_carapace  = _make_btn(BTN_X, PY + 94, BTN_W, BTN_H, "", _upgrade_buy_carapace)
	_upgrade_btn_legs      = _make_btn(BTN_X, PY + 156, BTN_W, BTN_H, "", _upgrade_buy_legs)
	_upgrade_btn_mandibles = _make_btn(BTN_X, PY + 218, BTN_W, BTN_H, "", _upgrade_buy_mandibles)
	_upgrade_layer.add_child(_upgrade_btn_carapace)
	_upgrade_layer.add_child(_upgrade_btn_legs)
	_upgrade_layer.add_child(_upgrade_btn_mandibles)

	_upgrade_layer.add_child(
		_make_btn(BTN_X + (BTN_W - 180) / 2, PY + 294, 180, 40, "Close", hide_upgrade_station))


func show_upgrade_station() -> void:
	_upgrade_minerals_label.text = "Dollars: $%d" % GameManager.dollars

	var carapace_cost := 50 + 25 * GameManager.carapace_level
	var hp := GameManager.get_max_health()
	_upgrade_btn_carapace.text = "Reinforce Spacesuit Lv%d — Max HP: %d → %d  ($%d)" % [
		GameManager.carapace_level, hp, hp + 1, carapace_cost]
	_upgrade_btn_carapace.disabled = GameManager.dollars < carapace_cost

	var legs_cost := 50 + 25 * GameManager.legs_level
	var energy_cap := GameManager.get_max_energy()
	_upgrade_btn_legs.text = "Upgrade Mining Boots Lv%d — Energy Limit: %d → %d  ($%d)" % [
		GameManager.legs_level, energy_cap, energy_cap + 25, legs_cost]
	_upgrade_btn_legs.disabled = GameManager.dollars < legs_cost

	var mandibles_cost := 50 + 25 * GameManager.mandibles_level
	var cap := GameManager.get_ore_capacity()
	_upgrade_btn_mandibles.text = "Expand Cargo Hold Lv%d — Ore Capacity: %d → %d  ($%d)" % [
		GameManager.mandibles_level, cap, cap + 25, mandibles_cost]
	_upgrade_btn_mandibles.disabled = GameManager.dollars < mandibles_cost

	_upgrade_layer.visible = true
	upgrade_station_visible = true


func hide_upgrade_station() -> void:
	_upgrade_layer.visible = false
	upgrade_station_visible = false


func _upgrade_buy_carapace() -> void:
	var cost := 50 + 25 * GameManager.carapace_level
	if GameManager.dollars >= cost:
		GameManager.dollars -= cost
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.upgrade_carapace()
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.health_component.max_health = GameManager.get_max_health()
			EventBus.player_health_changed.emit(player.health_component.current_health, player.health_component.max_health)
		SoundManager.play_drill_sound()
		show_upgrade_station()


func _upgrade_buy_legs() -> void:
	var cost := 50 + 25 * GameManager.legs_level
	if GameManager.dollars >= cost:
		GameManager.dollars -= cost
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.upgrade_legs()
		EventBus.energy_changed.emit(GameManager.current_energy, GameManager.get_max_energy())
		SoundManager.play_drill_sound()
		show_upgrade_station()


func _upgrade_buy_mandibles() -> void:
	var cost := 50 + 25 * GameManager.mandibles_level
	if GameManager.dollars >= cost:
		GameManager.dollars -= cost
		EventBus.dollars_changed.emit(GameManager.dollars)
		GameManager.upgrade_mandibles()
		SoundManager.play_drill_sound()
		show_upgrade_station()


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

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(1.0, 0.55, 0.0)
	_smeltery_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.12, 0.08, 0.04, 0.97)
	_smeltery_layer.add_child(panel)

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
	_smeltery_minerals_label.text = "Dollars: $%d" % GameManager.dollars
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
		_smeltery_sell_btns[ore_group].text = "Sell All ($%d/bar | $%d total)" % [sell_per_bar, sell_total]
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
	var sell_value: int = roundi(SMELTERY_BAR_SELL_VALUES[ore_group] * GameManager.get_dollar_sell_mult()) * bar_count
	run_bar_counts[ore_group] = 0
	GameManager.add_dollars(sell_value)
	SoundManager.play_pickup_sound()
	EventBus.ore_mined_popup.emit(sell_value, "%d %s sold!" % [bar_count, SMELTERY_BAR_NAMES[ore_group]])
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

	var border := ColorRect.new()
	border.position = Vector2(PX - 3, PY - 3)
	border.size = Vector2(PANEL_W + 6, PANEL_H + 6)
	border.color = Color(0.80, 0.55, 0.10)
	_cat_tavern_layer.add_child(border)

	var panel := ColorRect.new()
	panel.position = Vector2(PX, PY)
	panel.size = Vector2(PANEL_W, PANEL_H)
	panel.color = Color(0.08, 0.06, 0.03, 0.97)
	_cat_tavern_layer.add_child(panel)

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
	SoundManager.play_drill_sound()
	show_cat_tavern()


func _tavern_hire_collecting() -> void:
	if run_bar_counts.get("copper", 0) < CAT_TAVERN_COLLECT_CAT_COPPER_BARS:
		return
	if cat_system and cat_system.get_collecting_cat_count() >= CAT_MAX_COLLECTING:
		return
	run_bar_counts["copper"] = run_bar_counts.get("copper", 0) - CAT_TAVERN_COLLECT_CAT_COPPER_BARS
	if cat_system and player_node:
		cat_system.hire(CatSystem.CatRole.COLLECTING, player_node.global_position + Vector2(-64, 0))
	SoundManager.play_drill_sound()
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
