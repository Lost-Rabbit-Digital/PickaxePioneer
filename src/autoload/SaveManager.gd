extends Node

# SaveManager — Manages 3 save slots with full game state + planet configuration.
# Planet config (mine names, ores, hazards) is persisted per run so the overworld
# stays consistent until the player dies.

const SAVE_PATH := "user://save_slots.json"
const GLOBAL_SAVE_PATH := "user://global_progress.json"
const MAX_SLOTS := 3

# Currently active slot index (-1 = no slot loaded)
var active_slot: int = -1

# In-memory slot data: Array of 3 Dictionaries (or null for empty slots)
var _slots: Array = [null, null, null]

func _ready() -> void:
	_load_all_slots()
	_load_global_progress()

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns true if any slot has save data.
func has_any_save() -> bool:
	for slot in _slots:
		if slot != null:
			return true
	return false

## Returns slot data dictionary (or null) for the given index (0-2).
func get_slot(index: int) -> Variant:
	if index < 0 or index >= MAX_SLOTS:
		return null
	return _slots[index]

## Returns summary info for display in the save-slot picker UI.
func get_slot_summary(index: int) -> Dictionary:
	var slot = get_slot(index)
	if slot == null:
		return {}
	var mandibles_lvl: int = slot.get("mandibles_level", 0)
	var cargo_bay: bool = slot.get("cargo_bay_built", false)
	var mandibles_gem: bool = slot.get("mandibles_gem_socketed", false)
	var ore_capacity: int = 200 + (25 if cargo_bay else 0) + (mandibles_lvl * 25) + (25 if mandibles_gem else 0)
	# Migrate legacy saves that used separate mineral_currency + dollars keys
	var legacy_coins: int = slot.get("mineral_currency", 0) * 100 + slot.get("dollars", 0) * 100
	return {
		"coins": slot.get("coins", legacy_coins),
		"ore_capacity": ore_capacity,
		"deepest_row": slot.get("deepest_row_reached", 0),
		"last_node": slot.get("last_overworld_node_name", ""),
		"carapace_level": slot.get("carapace_level", 0),
		"legs_level": slot.get("legs_level", 0),
		"mandibles_level": mandibles_lvl,
		"mineral_sense_level": slot.get("mineral_sense_level", 0),
		"playtime_seconds": slot.get("total_playtime_seconds", 0.0),
	}

## Start a new game in the given slot — resets GameManager and saves.
func new_game(slot_index: int) -> void:
	active_slot = slot_index
	_reset_game_manager()
	save_active_slot()

## Load a slot into GameManager and make it active.
func load_slot(slot_index: int) -> void:
	var data = get_slot(slot_index)
	if data == null:
		return
	active_slot = slot_index
	_apply_to_game_manager(data)

## Save current GameManager state into the active slot.
func save_active_slot() -> void:
	if active_slot < 0 or active_slot >= MAX_SLOTS:
		return
	_slots[active_slot] = _snapshot_game_manager()
	_persist_all_slots()

## Delete a slot entirely.
func delete_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return
	_slots[slot_index] = null
	if active_slot == slot_index:
		active_slot = -1
	_persist_all_slots()

## Save overworld planet configuration for the active slot.
func save_planet_config(config: Dictionary) -> void:
	if active_slot < 0 or active_slot >= MAX_SLOTS:
		return
	if _slots[active_slot] == null:
		_slots[active_slot] = _snapshot_game_manager()
	_slots[active_slot]["planet_config"] = config
	_persist_all_slots()

## Get saved planet configuration for the active slot (or empty dict).
func get_planet_config() -> Dictionary:
	if active_slot < 0 or active_slot >= MAX_SLOTS:
		return {}
	var slot = _slots[active_slot]
	if slot == null:
		return {}
	return slot.get("planet_config", {})

## Clear the active save slot's run data (called on player death or run complete).
func clear_active_slot_run_data() -> void:
	if active_slot < 0 or active_slot >= MAX_SLOTS:
		return
	if _slots[active_slot] != null:
		# Clear planet config so overworld re-randomizes next run
		_slots[active_slot].erase("planet_config")
		_slots[active_slot]["last_overworld_node_name"] = ""
		# Clear mid-run save state so no stale terrain diff survives a death
		_slots[active_slot]["run_is_in_mining_level"] = false
		_slots[active_slot]["run_node_name"] = ""
		_slots[active_slot]["run_player_pos_x"] = 0.0
		_slots[active_slot]["run_player_pos_y"] = 0.0
		_slots[active_slot]["run_player_health"] = 0.0
		_slots[active_slot]["run_terrain_seed"] = 0
		_slots[active_slot]["run_current_energy"] = 0
		_slots[active_slot]["run_coins"] = 0
		_slots[active_slot]["run_ore_chunk_counts"] = {}
		_slots[active_slot]["run_terrain_changes"] = []
		# Save the updated slot (upgrades persist, but run state resets)
		_persist_all_slots()

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func _load_all_slots() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		# Migrate legacy single save if it exists
		_migrate_legacy_save()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Array:
		for i in range(mini(json.data.size(), MAX_SLOTS)):
			_slots[i] = json.data[i]  # may be null for empty slots

func _persist_all_slots() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_slots))
		file.close()

## Save global progress (cross-save XP and level) to its own file.
func save_global_progress() -> void:
	var gm = GameManager
	var data := {
		"global_player_xp": gm.global_player_xp,
		"global_player_level": gm.global_player_level,
	}
	var file = FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func _load_global_progress() -> void:
	if not FileAccess.file_exists(GLOBAL_SAVE_PATH):
		return
	var file = FileAccess.open(GLOBAL_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		var gm = GameManager
		gm.global_player_xp = json.data.get("global_player_xp", 0)
		gm.global_player_level = json.data.get("global_player_level", 1)

func _migrate_legacy_save() -> void:
	# If the old single-file save exists, import it into slot 0
	const LEGACY_PATH = "user://save_data.json"
	if not FileAccess.file_exists(LEGACY_PATH):
		return
	var file = FileAccess.open(LEGACY_PATH, FileAccess.READ)
	if not file:
		return
	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) == OK and json.data is Dictionary:
		_slots[0] = json.data
		_persist_all_slots()

# ---------------------------------------------------------------------------
# Snapshot / Apply
# ---------------------------------------------------------------------------

func _snapshot_game_manager() -> Dictionary:
	var gm = GameManager
	var data := {
		"coins": gm.coins,
		"carapace_level": gm.carapace_level,
		"legs_level": gm.legs_level,
		"mandibles_level": gm.mandibles_level,
		"mineral_sense_level": gm.mineral_sense_level,
		"claws_level": gm.claws_level,
		"settlement_energy_bonus": gm.settlement_energy_bonus,
		"settlement_forager_bonus": gm.settlement_forager_bonus,
		"settlement_shroom_charges": gm.settlement_shroom_charges,
		"settlement_mandible_bonus": gm.settlement_mandible_bonus,
		"gem_count": gm.gem_count,
		"carapace_gem_socketed": gm.carapace_gem_socketed,
		"legs_gem_socketed": gm.legs_gem_socketed,
		"mandibles_gem_socketed": gm.mandibles_gem_socketed,
		"sense_gem_socketed": gm.sense_gem_socketed,
		"total_coins_banked": gm.total_coins_banked,
		"bosses_defeated_total": gm.bosses_defeated_total,
		"total_fossils": gm.total_fossils,
		"deepest_row_reached": gm.deepest_row_reached,
		"total_playtime_seconds": gm.total_playtime_seconds,
		"warp_drive_built": gm.warp_drive_built,
		"cargo_bay_built": gm.cargo_bay_built,
		"long_scanner_built": gm.long_scanner_built,
		"gem_refinery_built": gm.gem_refinery_built,
		"trade_amplifier_built": gm.trade_amplifier_built,
		"debt_paid": gm.debt_paid,
		"last_overworld_node_name": gm.last_overworld_node_name,
		"ladder_count": gm.ladder_count,
		"equipped_leaf": gm.equipped_leaf,
		"equipped_ice": gm.equipped_ice,
		"equipped_companions": gm.equipped_companions,
		"cat_color": gm.cat_color.to_html(),
		"cat_outline_color": gm.cat_outline_color.to_html(),
		"has_completed_tier_1_mine": gm.has_completed_tier_1_mine,
		"has_completed_tier_2_settlement": gm.has_completed_tier_2_settlement,
		"has_seen_overworld_hint": gm.has_seen_overworld_hint,
		"has_completed_first_run": gm.has_completed_first_run,
		# Perk tree
		"player_xp": gm.player_xp,
		"player_level": gm.player_level,
		"perk_points": gm.perk_points,
		"perk_ranks": gm.perk_ranks.duplicate(),
		# Trinkets
		"trinket_paraglider": gm.trinket_paraglider,
		"trinket_jet_boots": gm.trinket_jet_boots,
		"trinket_stone_of_regen": gm.trinket_stone_of_regen,
		"trinket_spring_boots": gm.trinket_spring_boots,
		"trinket_jumping_bean": gm.trinket_jumping_bean,
		"trinket_sneakers": gm.trinket_sneakers,
		"trinket_gecko_gloves": gm.trinket_gecko_gloves,
		"trinket_boots_of_sprinting": gm.trinket_boots_of_sprinting,
		"trinket_cube_of_curing": gm.trinket_cube_of_curing,
		"trinket_scuba_helmet": gm.trinket_scuba_helmet,
		"trinket_magnet": gm.trinket_magnet,
		"trinket_cosmic_radiation": gm.trinket_cosmic_radiation,
		"trinket_curse_of_core": gm.trinket_curse_of_core,
	}
	# Preserve existing planet config if present
	if active_slot >= 0 and active_slot < MAX_SLOTS and _slots[active_slot] != null:
		var existing_config = _slots[active_slot].get("planet_config", {})
		if existing_config.size() > 0:
			data["planet_config"] = existing_config
	# Mid-run state — allows seamless resume after quitting mid-mine
	data["run_is_in_mining_level"] = gm.run_is_in_mining_level
	data["run_node_name"] = gm.run_node_name
	data["run_player_pos_x"] = gm.run_player_pos_x
	data["run_player_pos_y"] = gm.run_player_pos_y
	data["run_player_health"] = gm.run_player_health
	data["run_terrain_seed"] = gm.terrain_seed
	data["run_terrain_biome"] = gm.terrain_biome
	data["run_planet_size"]   = gm.planet_size
	data["run_current_energy"] = gm.current_energy
	data["run_coins"] = gm.run_coins
	data["run_ore_chunk_counts"] = gm.run_ore_chunk_counts.duplicate()
	data["run_terrain_changes"] = gm.run_terrain_changes.duplicate()
	return data

func _apply_to_game_manager(data: Dictionary) -> void:
	var gm = GameManager
	# Migrate legacy saves that stored mineral_currency + dollars separately
	var legacy_coins: int = data.get("mineral_currency", 0) * 100 + data.get("dollars", 0) * 100
	gm.coins = data.get("coins", legacy_coins)
	gm.carapace_level = data.get("carapace_level", 0)
	gm.legs_level = data.get("legs_level", 0)
	gm.mandibles_level = data.get("mandibles_level", 0)
	gm.mineral_sense_level = data.get("mineral_sense_level", 0)
	gm.claws_level = data.get("claws_level", 0)
	gm.settlement_energy_bonus = data.get("settlement_energy_bonus", 0)
	gm.settlement_forager_bonus = data.get("settlement_forager_bonus", 0)
	gm.settlement_shroom_charges = data.get("settlement_shroom_charges", 0)
	gm.settlement_mandible_bonus = data.get("settlement_mandible_bonus", 0)
	gm.gem_count = data.get("gem_count", 0)
	gm.carapace_gem_socketed = data.get("carapace_gem_socketed", false)
	gm.legs_gem_socketed = data.get("legs_gem_socketed", false)
	gm.mandibles_gem_socketed = data.get("mandibles_gem_socketed", false)
	gm.sense_gem_socketed = data.get("sense_gem_socketed", false)
	gm.total_coins_banked = data.get("total_coins_banked", data.get("total_minerals_banked", 0) * 100)
	gm.bosses_defeated_total = data.get("bosses_defeated_total", 0)
	gm.total_fossils = data.get("total_fossils", 0)
	gm.deepest_row_reached = data.get("deepest_row_reached", 0)
	gm.total_playtime_seconds = data.get("total_playtime_seconds", 0.0)
	gm.warp_drive_built = data.get("warp_drive_built", false)
	gm.cargo_bay_built = data.get("cargo_bay_built", false)
	gm.long_scanner_built = data.get("long_scanner_built", false)
	gm.gem_refinery_built = data.get("gem_refinery_built", false)
	gm.trade_amplifier_built = data.get("trade_amplifier_built", false)
	gm.debt_paid = data.get("debt_paid", 0)
	gm.last_overworld_node_name = data.get("last_overworld_node_name", "")
	gm.ladder_count = data.get("ladder_count", 10)
	gm.equipped_leaf = data.get("equipped_leaf", false)
	gm.equipped_ice = data.get("equipped_ice", false)
	var saved_companions: Variant = data.get("equipped_companions", {})
	gm.equipped_companions = saved_companions if saved_companions is Dictionary else {}
	var color_html: String = data.get("cat_color", "")
	if color_html != "":
		gm.cat_color = Color.from_string(color_html, Color.WHITE)
	else:
		gm.cat_color = Color.WHITE
	var outline_html: String = data.get("cat_outline_color", "")
	if outline_html != "":
		gm.cat_outline_color = Color.from_string(outline_html, Color("2b222a"))
	else:
		gm.cat_outline_color = Color("2b222a")
	gm.has_completed_tier_1_mine = data.get("has_completed_tier_1_mine", false)
	gm.has_completed_tier_2_settlement = data.get("has_completed_tier_2_settlement", false)
	gm.has_seen_overworld_hint = data.get("has_seen_overworld_hint", false)
	gm.has_completed_first_run = data.get("has_completed_first_run", false)
	# Perk tree
	gm.player_xp = data.get("player_xp", 0)
	gm.player_level = data.get("player_level", 1)
	gm.perk_points = data.get("perk_points", 0)
	var saved_ranks: Variant = data.get("perk_ranks", {})
	gm.perk_ranks = saved_ranks if saved_ranks is Dictionary else {}
	# Trinkets
	gm.trinket_paraglider = data.get("trinket_paraglider", false)
	gm.trinket_jet_boots = data.get("trinket_jet_boots", false)
	gm.trinket_stone_of_regen = data.get("trinket_stone_of_regen", false)
	gm.trinket_spring_boots = data.get("trinket_spring_boots", false)
	gm.trinket_jumping_bean = data.get("trinket_jumping_bean", false)
	gm.trinket_sneakers = data.get("trinket_sneakers", false)
	gm.trinket_gecko_gloves = data.get("trinket_gecko_gloves", false)
	gm.trinket_boots_of_sprinting = data.get("trinket_boots_of_sprinting", false)
	gm.trinket_cube_of_curing = data.get("trinket_cube_of_curing", false)
	gm.trinket_scuba_helmet = data.get("trinket_scuba_helmet", false)
	gm.trinket_magnet = data.get("trinket_magnet", false)
	gm.trinket_cosmic_radiation = data.get("trinket_cosmic_radiation", false)
	gm.trinket_curse_of_core = data.get("trinket_curse_of_core", false)
	# Mid-run state
	gm.run_is_in_mining_level = data.get("run_is_in_mining_level", false)
	gm.run_node_name = data.get("run_node_name", "")
	gm.run_player_pos_x = data.get("run_player_pos_x", 0.0)
	gm.run_player_pos_y = data.get("run_player_pos_y", 0.0)
	gm.run_player_health = data.get("run_player_health", 0.0)
	if gm.run_is_in_mining_level:
		# Restore the exact terrain seed, biome, size, energy, currency, and inventory
		# from the saved mid-run state so load_mining_level() can resume rather than reset.
		gm.terrain_seed  = data.get("run_terrain_seed", 0)
		gm.terrain_biome = data.get("run_terrain_biome", "Rock")
		gm.planet_size   = data.get("run_planet_size",   "Medium")
		gm.current_energy = data.get("run_current_energy", gm.get_max_energy())
		gm.run_coins = data.get("run_coins", 0)
		var saved_ore_chunks: Variant = data.get("run_ore_chunk_counts", {})
		gm.run_ore_chunk_counts = saved_ore_chunks if saved_ore_chunks is Dictionary else {}
		var saved_changes: Variant = data.get("run_terrain_changes", [])
		gm.run_terrain_changes = saved_changes if saved_changes is Array else []

func _reset_game_manager() -> void:
	var gm = GameManager
	gm.coins = 0
	gm.run_coins = 0
	gm.run_ore_counts.clear()
	gm.run_ore_earnings.clear()
	gm.run_ore_chunk_count = 0
	gm.last_overworld_node_name = ""
	gm.allowed_ore_types = []
	gm.allowed_hazard_types = []
	gm.current_energy = 100
	gm.settlement_energy_bonus = 0
	gm.settlement_forager_bonus = 0
	gm.settlement_shroom_charges = 0
	gm.settlement_mandible_bonus = 0
	gm.carapace_level = 0
	gm.legs_level = 0
	gm.mandibles_level = 0
	gm.mineral_sense_level = 0
	gm.claws_level = 0
	gm.gem_count = 0
	gm.carapace_gem_socketed = false
	gm.legs_gem_socketed = false
	gm.mandibles_gem_socketed = false
	gm.sense_gem_socketed = false
	gm.total_coins_banked = 0
	gm.bosses_defeated_total = 0
	gm.total_fossils = 0
	gm.deepest_row_reached = 0
	gm.total_playtime_seconds = 0.0
	gm.warp_drive_built = false
	gm.cargo_bay_built = false
	gm.long_scanner_built = false
	gm.gem_refinery_built = false
	gm.trade_amplifier_built = false
	gm.debt_paid = 0
	gm.ladder_count = 10
	gm.equipped_leaf = false
	gm.equipped_ice = false
	gm.equipped_companions = {}
	gm.cat_color = Color.WHITE
	gm.cat_outline_color = Color("2b222a")
	gm.has_completed_tier_1_mine = false
	gm.has_completed_tier_2_settlement = false
	gm.has_seen_overworld_hint = false
	gm.has_completed_first_run = false
	# Perk tree
	gm.player_xp = 0
	gm.player_level = 1
	gm.perk_points = 0
	gm.perk_ranks = {}
	# Trinkets
	gm.trinket_paraglider = false
	gm.trinket_jet_boots = false
	gm.trinket_stone_of_regen = false
	gm.trinket_spring_boots = false
	gm.trinket_jumping_bean = false
	gm.trinket_sneakers = false
	gm.trinket_gecko_gloves = false
	gm.trinket_boots_of_sprinting = false
	gm.trinket_cube_of_curing = false
	gm.trinket_scuba_helmet = false
	gm.trinket_magnet = false
	gm.trinket_cosmic_radiation = false
	gm.trinket_curse_of_core = false
	# Mid-run state
	gm.run_is_in_mining_level = false
	gm.run_node_name = ""
	gm.run_player_pos_x = 0.0
	gm.run_player_pos_y = 0.0
	gm.run_player_health = 0.0
	gm.run_terrain_changes = []
