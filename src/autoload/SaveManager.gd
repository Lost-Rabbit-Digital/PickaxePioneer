extends Node

# SaveManager — Manages 3 save slots with full game state + planet configuration.
# Planet config (mine names, ores, hazards) is persisted per run so the overworld
# stays consistent until the player dies.

const SAVE_PATH := "user://save_slots.json"
const MAX_SLOTS := 3

# Currently active slot index (-1 = no slot loaded)
var active_slot: int = -1

# In-memory slot data: Array of 3 Dictionaries (or null for empty slots)
var _slots: Array = [null, null, null]

func _ready() -> void:
	_load_all_slots()

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
	return {
		"minerals": slot.get("mineral_currency", 0),
		"ore_capacity": ore_capacity,
		"dollars": slot.get("dollars", 0),
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

## Clear the active save slot (called on player death).
func clear_active_slot_run_data() -> void:
	if active_slot < 0 or active_slot >= MAX_SLOTS:
		return
	if _slots[active_slot] != null:
		# Clear planet config so overworld re-randomizes next run
		_slots[active_slot].erase("planet_config")
		_slots[active_slot]["last_overworld_node_name"] = ""
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
		print("SaveManager: Migrated legacy save to slot 0")

# ---------------------------------------------------------------------------
# Snapshot / Apply
# ---------------------------------------------------------------------------

func _snapshot_game_manager() -> Dictionary:
	var gm = GameManager
	var data := {
		"mineral_currency": gm.mineral_currency,
		"dollars": gm.dollars,
		"carapace_level": gm.carapace_level,
		"legs_level": gm.legs_level,
		"mandibles_level": gm.mandibles_level,
		"mineral_sense_level": gm.mineral_sense_level,
		"settlement_energy_bonus": gm.settlement_energy_bonus,
		"settlement_forager_bonus": gm.settlement_forager_bonus,
		"settlement_shroom_charges": gm.settlement_shroom_charges,
		"settlement_mandible_bonus": gm.settlement_mandible_bonus,
		"gem_count": gm.gem_count,
		"carapace_gem_socketed": gm.carapace_gem_socketed,
		"legs_gem_socketed": gm.legs_gem_socketed,
		"mandibles_gem_socketed": gm.mandibles_gem_socketed,
		"sense_gem_socketed": gm.sense_gem_socketed,
		"total_minerals_banked": gm.total_minerals_banked,
		"bosses_defeated_total": gm.bosses_defeated_total,
		"total_fossils": gm.total_fossils,
		"deepest_row_reached": gm.deepest_row_reached,
		"total_playtime_seconds": gm.total_playtime_seconds,
		"warp_drive_built": gm.warp_drive_built,
		"cargo_bay_built": gm.cargo_bay_built,
		"long_scanner_built": gm.long_scanner_built,
		"gem_refinery_built": gm.gem_refinery_built,
		"trade_amplifier_built": gm.trade_amplifier_built,
		"last_overworld_node_name": gm.last_overworld_node_name,
		"ladder_count": gm.ladder_count,
		"equipped_leaf": gm.equipped_leaf,
		"equipped_ice": gm.equipped_ice,
		"cat_color": gm.cat_color.to_html(),
	}
	# Preserve existing planet config if present
	if active_slot >= 0 and active_slot < MAX_SLOTS and _slots[active_slot] != null:
		var existing_config = _slots[active_slot].get("planet_config", {})
		if existing_config.size() > 0:
			data["planet_config"] = existing_config
	return data

func _apply_to_game_manager(data: Dictionary) -> void:
	var gm = GameManager
	gm.mineral_currency = data.get("mineral_currency", 0)
	gm.dollars = data.get("dollars", 0)
	gm.carapace_level = data.get("carapace_level", 0)
	gm.legs_level = data.get("legs_level", 0)
	gm.mandibles_level = data.get("mandibles_level", 0)
	gm.mineral_sense_level = data.get("mineral_sense_level", 0)
	gm.settlement_energy_bonus = data.get("settlement_energy_bonus", 0)
	gm.settlement_forager_bonus = data.get("settlement_forager_bonus", 0)
	gm.settlement_shroom_charges = data.get("settlement_shroom_charges", 0)
	gm.settlement_mandible_bonus = data.get("settlement_mandible_bonus", 0)
	gm.gem_count = data.get("gem_count", 0)
	gm.carapace_gem_socketed = data.get("carapace_gem_socketed", false)
	gm.legs_gem_socketed = data.get("legs_gem_socketed", false)
	gm.mandibles_gem_socketed = data.get("mandibles_gem_socketed", false)
	gm.sense_gem_socketed = data.get("sense_gem_socketed", false)
	gm.total_minerals_banked = data.get("total_minerals_banked", 0)
	gm.bosses_defeated_total = data.get("bosses_defeated_total", 0)
	gm.total_fossils = data.get("total_fossils", 0)
	gm.deepest_row_reached = data.get("deepest_row_reached", 0)
	gm.total_playtime_seconds = data.get("total_playtime_seconds", 0.0)
	gm.warp_drive_built = data.get("warp_drive_built", false)
	gm.cargo_bay_built = data.get("cargo_bay_built", false)
	gm.long_scanner_built = data.get("long_scanner_built", false)
	gm.gem_refinery_built = data.get("gem_refinery_built", false)
	gm.trade_amplifier_built = data.get("trade_amplifier_built", false)
	gm.last_overworld_node_name = data.get("last_overworld_node_name", "")
	gm.ladder_count = data.get("ladder_count", 10)
	gm.equipped_leaf = data.get("equipped_leaf", false)
	gm.equipped_ice = data.get("equipped_ice", false)
	var color_html: String = data.get("cat_color", "")
	if color_html != "":
		gm.cat_color = Color.from_string(color_html, Color.WHITE)
	else:
		gm.cat_color = Color.WHITE

func _reset_game_manager() -> void:
	var gm = GameManager
	gm.mineral_currency = 0
	gm.run_mineral_currency = 0
	gm.dollars = 0
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
	gm.gem_count = 0
	gm.carapace_gem_socketed = false
	gm.legs_gem_socketed = false
	gm.mandibles_gem_socketed = false
	gm.sense_gem_socketed = false
	gm.total_minerals_banked = 0
	gm.bosses_defeated_total = 0
	gm.total_fossils = 0
	gm.deepest_row_reached = 0
	gm.total_playtime_seconds = 0.0
	gm.warp_drive_built = false
	gm.cargo_bay_built = false
	gm.long_scanner_built = false
	gm.gem_refinery_built = false
	gm.trade_amplifier_built = false
	gm.ladder_count = 10
	gm.equipped_leaf = false
	gm.equipped_ice = false
	gm.cat_color = Color.WHITE
