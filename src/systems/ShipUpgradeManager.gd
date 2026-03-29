class_name ShipUpgradeManager
extends RefCounted

## Centralized spaceship upgrade state and queries.
## Costs, built flags, unlock conditions, and bonus getters live here.

## Spaceship upgrade costs in copper (100 copper = 1g).
const COST_WARP_DRIVE: int       = 20000
const COST_CARGO_BAY: int        = 15000
const COST_LONG_SCANNER: int     = 30000
const COST_GEM_REFINERY: int     = 25000
const COST_TRADE_AMPLIFIER: int  = 20000

## Built flags (persisted to save).
var warp_drive_built: bool = false
var cargo_bay_built: bool = false
var long_scanner_built: bool = false
var gem_refinery_built: bool = false
var trade_amplifier_built: bool = false


## Bonus gems awarded per gem ore mined.
func get_gem_mine_bonus() -> int:
	return 1 if gem_refinery_built else 0


## Dollar sell multiplier for smeltery bars.
func get_dollar_sell_mult() -> float:
	return 1.25 if trade_amplifier_built else 1.0


## Snapshot all ship upgrade state for saving.
func snapshot() -> Dictionary:
	return {
		"warp_drive_built": warp_drive_built,
		"cargo_bay_built": cargo_bay_built,
		"long_scanner_built": long_scanner_built,
		"gem_refinery_built": gem_refinery_built,
		"trade_amplifier_built": trade_amplifier_built,
	}


## Apply saved ship upgrade state.
func apply(data: Dictionary) -> void:
	warp_drive_built = data.get("warp_drive_built", false)
	cargo_bay_built = data.get("cargo_bay_built", false)
	long_scanner_built = data.get("long_scanner_built", false)
	gem_refinery_built = data.get("gem_refinery_built", false)
	trade_amplifier_built = data.get("trade_amplifier_built", false)


## Reset all upgrades to unbuilt.
func reset() -> void:
	warp_drive_built = false
	cargo_bay_built = false
	long_scanner_built = false
	gem_refinery_built = false
	trade_amplifier_built = false
