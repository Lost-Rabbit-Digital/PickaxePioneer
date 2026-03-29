class_name TrinketManager
extends RefCounted

## Centralized trinket state and queries.
## All trinket equipped booleans and effect getters live here.
## GameManager delegates trinket access to this class.

# Trinket names (matching save keys)
const TRINKET_IDS: Array[String] = [
	"trinket_paraglider", "trinket_jet_boots", "trinket_stone_of_regen",
	"trinket_spring_boots", "trinket_jumping_bean", "trinket_sneakers",
	"trinket_gecko_gloves", "trinket_boots_of_sprinting", "trinket_cube_of_curing",
	"trinket_scuba_helmet", "trinket_magnet", "trinket_cosmic_radiation",
	"trinket_curse_of_core",
]

## Equipped state for each trinket, keyed by trinket id string.
var equipped: Dictionary = {}


func _init() -> void:
	for id in TRINKET_IDS:
		equipped[id] = false


## Get whether a trinket is equipped.
func is_equipped(trinket_id: String) -> bool:
	return equipped.get(trinket_id, false)


## Toggle a trinket on or off. Returns the new state.
func toggle(trinket_id: String) -> bool:
	equipped[trinket_id] = not equipped.get(trinket_id, false)
	return equipped[trinket_id]


## Set a trinket to a specific state.
func set_equipped(trinket_id: String, value: bool) -> void:
	equipped[trinket_id] = value


## Magnet attraction radius in pixels (0 when trinket not equipped).
func get_magnet_range() -> float:
	return 256.0 if equipped.get("trinket_magnet", false) else 0.0


## Snapshot all trinket state for saving.
func snapshot() -> Dictionary:
	return equipped.duplicate()


## Apply saved trinket state.
func apply(data: Dictionary) -> void:
	for id in TRINKET_IDS:
		equipped[id] = data.get(id, false)


## Reset all trinkets to unequipped.
func reset() -> void:
	for id in TRINKET_IDS:
		equipped[id] = false
