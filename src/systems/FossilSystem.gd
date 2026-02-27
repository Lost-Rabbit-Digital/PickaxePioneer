class_name FossilSystem
extends RefCounted

## Fossil forgiveness system (§3.6)
## Each block type tracks a hidden drought counter per run.
## Fossil probability rises as the drought counter increases,
## resetting to 0 when a fossil is found.
## MiningLevel passes the resolved fossil data dict (or empty dict if the
## tile type cannot yield fossils), so this class has no TileType dependency.

const BASE_RATE: float    = 0.005
const DROUGHT_SCALE: float = 0.005
const CAP_RATE: float     = 0.30

# Per-tile-type drought counters; keys are raw TileType int values
var _drought: Dictionary = {}


## Check whether a mined tile yields a fossil.
## tile:        raw TileType int (used as drought key only)
## fossil_data: {"name": String, "minerals": int} if this tile type can carry
##              a fossil, or {} if it cannot.
## Awards minerals and emits popup via EventBus when a fossil is found.
func check(tile: int, fossil_data: Dictionary) -> void:
	if fossil_data.is_empty():
		_drought[tile] = _drought.get(tile, 0) + 1
		return
	var drought: int = _drought.get(tile, 0)
	var roll_rate := minf(CAP_RATE, BASE_RATE + drought * DROUGHT_SCALE)
	if randf() < roll_rate:
		var minerals: int = fossil_data["minerals"]
		GameManager.add_currency(minerals)
		EventBus.ore_mined_popup.emit(minerals, fossil_data["name"] + " Fossil!")
		_drought[tile] = 0
	else:
		_drought[tile] = drought + 1


## Reset drought counters at the start of a new run.
func reset() -> void:
	_drought.clear()
