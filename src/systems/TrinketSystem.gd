class_name TrinketSystem
extends RefCounted

# All trinket definitions — keyed by trinket ID.
# The ID matches the GameManager property suffix: "trinket_<id>".
const TRINKETS: Dictionary = {
	"paraglider": {
		"name": "Paraglider",
		"desc": "Hold Jump while falling to glide slowly. Prevents fall damage.",
		"color": Color(0.35, 0.80, 0.65),
	},
	"jet_boots": {
		"name": "Jet Boots",
		"desc": "Grants a mid-air boost after your double jump. Costs 15 energy.",
		"color": Color(1.00, 0.55, 0.10),
	},
	"stone_of_regen": {
		"name": "Stone of Regeneration",
		"desc": "Restores 1 HP every 4 seconds.",
		"color": Color(0.85, 0.15, 0.25),
	},
	"spring_boots": {
		"name": "Spring Boots",
		"desc": "Increases jump height by 2 meters.",
		"color": Color(0.55, 0.90, 0.20),
	},
	"jumping_bean": {
		"name": "Jumping Bean",
		"desc": "Increases mining power by 20%.",
		"color": Color(0.90, 0.60, 0.10),
	},
	"sneakers": {
		"name": "Sneakers",
		"desc": "Sprint costs no energy.",
		"color": Color(0.65, 0.55, 0.90),
	},
	"gecko_gloves": {
		"name": "Gecko Gloves",
		"desc": "Press into a wall while airborne to slow your descent.",
		"color": Color(0.30, 0.75, 0.30),
	},
	"boots_of_sprinting": {
		"name": "Boots of Sprinting",
		"desc": "Regenerate 1 energy per second while moving on the ground.",
		"color": Color(0.20, 0.70, 1.00),
	},
	"cube_of_curing": {
		"name": "Cube of Curing",
		"desc": "Immune to plasma burn damage.",
		"color": Color(0.20, 0.90, 0.50),
	},
	"scuba_helmet": {
		"name": "Scuba Helmet",
		"desc": "Immunity to hazardous gas clouds underground.",
		"color": Color(0.15, 0.55, 0.85),
	},
	"magnet": {
		"name": "Magnet",
		"desc": "Attracts ore chunks from up to 4 tiles away.",
		"color": Color(0.85, 0.20, 0.20),
	},
	"cosmic_radiation": {
		"name": "Cosmic Radiation",
		"desc": "Every 15 seconds, randomly gain or lose energy or HP.",
		"color": Color(0.70, 0.15, 0.85),
	},
	"curse_of_core": {
		"name": "Curse of the Core",
		"desc": "Suffer 1 damage every 8 seconds underground.",
		"color": Color(0.60, 0.05, 0.10),
	},
}

## Returns true if a trinket with the given ID is currently equipped.
static func is_equipped(id: String) -> bool:
	return GameManager.get("trinket_" + id) == true

## Returns a list of IDs for all currently equipped trinkets.
static func get_equipped_ids() -> Array:
	var result: Array = []
	for id in TRINKETS:
		if is_equipped(id):
			result.append(id)
	return result
