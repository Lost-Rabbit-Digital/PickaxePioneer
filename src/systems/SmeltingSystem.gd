class_name SmeltingSystem
extends RefCounted

## Consecutive smelting system (§3.5)
## Mine ores of the same type consecutively for chain bonuses,
## or two different ore types in sequence for combo bonuses.
## MiningLevel passes the pre-resolved ore group string (from SMELT_ORE_GROUPS)
## rather than raw tile IDs, so this class has no TileType dependency.

# Chain bonuses at 3 consecutive same-group mines: [bonus_pct, popup_label]
const CHAIN_BONUSES: Dictionary = {
	"copper": [0.50, "Bronze Ingot"],
	"iron":   [0.50, "Steel Ingot"],
	"gold":   [0.75, "Pure Gold"],
	"gem":    [1.00, "Faceted Gem"],
}

# Two-ore cross-combos: "first+second" -> [bonus_pct, popup_label]
const COMBOS: Dictionary = {
	"copper+iron": [1.00, "Alloy Ore"],
	"iron+copper": [1.00, "Alloy Ore"],
	"iron+gold":   [2.00, "Gilded Steel"],
	"gold+iron":   [2.00, "Gilded Steel"],
	"copper+gold": [1.50, "Fool's Gold"],
	"gold+copper": [1.50, "Fool's Gold"],
}

## The ore group last fed into this system.
## Exposed so MiningLevel (and the Stone Golem phase check) can read it.
var last_ore_group: String = ""

var _chain_count: int = 0
var _prev_ore_group: String = ""


## Process a mined ore. Awards any chain / combo bonus via GameManager and
## EventBus.  Call with the ore group string resolved from SMELT_ORE_GROUPS
## in MiningLevel; pass "" for neutral tiles (dirt, stone) which do not break
## the chain.
func process(ore_group: String, base_minerals: int) -> void:
	if ore_group == "":
		# Neutral tile — does not break the chain
		return

	# Check for a cross-ore combo BEFORE updating chain state
	if last_ore_group != "" and last_ore_group != ore_group:
		var combo_key := last_ore_group + "+" + ore_group
		if COMBOS.has(combo_key):
			var combo: Array = COMBOS[combo_key]
			var bonus := maxi(1, roundi(base_minerals * combo[0]))
			GameManager.add_currency(bonus)
			EventBus.ore_mined_popup.emit(bonus, combo[1] + "!")
			# Combo resets chain
			_prev_ore_group = ""
			last_ore_group = ore_group
			_chain_count = 1
			return

	# Same ore: advance chain
	if ore_group == last_ore_group:
		_chain_count += 1
		if _chain_count == 3:
			var chain_data: Array = CHAIN_BONUSES.get(ore_group, [0.5, "Ingot"])
			var bonus := maxi(1, roundi(base_minerals * chain_data[0]))
			GameManager.add_currency(bonus)
			EventBus.ore_mined_popup.emit(bonus, chain_data[1] + "!")
	else:
		# Different ore breaks chain, start fresh
		_prev_ore_group = last_ore_group
		last_ore_group = ore_group
		_chain_count = 1


## Reset state at the start of a new run.
func reset() -> void:
	last_ore_group = ""
	_chain_count = 0
	_prev_ore_group = ""
