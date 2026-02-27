extends Node

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var mineral_currency: int = 0
var run_mineral_currency: int = 0
# Per-ore tracking for run summary (tile_type_id -> count/minerals)
var run_ore_counts: Dictionary = {}
var run_ore_earnings: Dictionary = {}
var last_overworld_node_name: String = ""

# Ores allowed to spawn in the current level instance (set from MapNode.ore_types).
# Empty array means all ores can spawn (default behaviour).
var allowed_ore_types: Array = []

# Hazard types allowed to spawn in the current level instance (set from MapNode.hazard_types).
# Empty array means all hazards can spawn (default behaviour).
var allowed_hazard_types: Array = []

# Energy system
var current_energy: int = 100

func get_max_energy() -> int:
	return 100 + (legs_level * 25) + (25 if legs_gem_socketed else 0)

# Settlement carry-over bonuses (applied on next mine entry, then cleared)
var settlement_energy_bonus: int = 0       # extra starting energy from Energy Cache purchase
var settlement_forager_bonus: int = 0    # extra scout cat carry capacity for one run
var settlement_shroom_charges: int = 0   # Mining Shroom charges pre-purchased
var settlement_mandible_bonus: int = 0   # temporary +N mandible power for one run

# Upgrade levels
var carapace_level: int = 0
var legs_level: int = 0
var mandibles_level: int = 0
var mineral_sense_level: int = 0

# Gem socketing system — gems collected as items, socketed for passive bonuses
var gem_count: int = 0                       # unspent gems in the colony's stockpile
const GEM_SOCKET_COST: int = 3              # gems required to fill one socket slot
var carapace_gem_socketed: bool = false      # +1 max HP
var legs_gem_socketed: bool = false          # +25 max energy, +15 move speed
var mandibles_gem_socketed: bool = false     # +4 mining power
var sense_gem_socketed: bool = false         # +3 sonar ping radius

# Colony Chamber system — buildable rooms unlocked by milestone conditions
# Unlock conditions are checked at runtime; build costs are spent from mineral_currency.
const CHAMBER_COST_FUNGUS_GARDEN: int   = 200   # unlocks when total_minerals_banked >= 500
const CHAMBER_COST_BROOD_CHAMBER: int   = 150   # unlocks when bosses_defeated_total >= 1
const CHAMBER_COST_ARMORY: int          = 300   # unlocks when total_minerals_banked >= 1000
const CHAMBER_COST_NURSERY_VAULT: int   = 250   # unlocks when total_fossils >= 10
const CHAMBER_COST_DEEP_ANTENNA: int    = 200   # unlocks when deepest_row_reached >= 96

# Cumulative milestone trackers (persisted to save)
var total_minerals_banked: int = 0       # sum of all currency ever banked
var bosses_defeated_total: int = 0       # total boss encounters won
var total_fossils: int = 0               # total fossils found across all runs
var deepest_row_reached: int = 0         # deepest grid row ever reached

# Chamber built flags (persisted to save)
var fungus_garden_built: bool = false    # +10% mineral yield from all tiles
var brood_chamber_built: bool = false    # scout cat carry cap +20
var armory_built: bool = false           # explosive radius +1
var nursery_vault_built: bool = false    # fossil find rate +5% base
var deep_antenna_built: bool = false     # sonar radius +3

const SAVE_PATH = "user://save_data.json"

func _ready() -> void:
	print("GameManager initialized")
	load_game()

func add_currency(amount: int) -> void:
	run_mineral_currency += amount
	EventBus.minerals_changed.emit(run_mineral_currency)

func track_ore_mined(tile_type: int, minerals: int) -> void:
	run_ore_counts[tile_type] = run_ore_counts.get(tile_type, 0) + 1
	run_ore_earnings[tile_type] = run_ore_earnings.get(tile_type, 0) + minerals

func bank_currency() -> void:
	total_minerals_banked += run_mineral_currency
	mineral_currency += run_mineral_currency
	run_mineral_currency = 0
	EventBus.minerals_changed.emit(0)

func change_state(new_state: GameState) -> void:
	current_state = new_state
	EventBus.game_state_changed.emit(current_state)
	print("Game State Changed to: ", new_state)

func start_game() -> void:
	change_state(GameState.PLAYING)
	load_overworld()

func pause_game() -> void:
	change_state(GameState.PAUSED)

func lose_run() -> void:
	run_mineral_currency = 0
	run_ore_counts.clear()
	run_ore_earnings.clear()
	EventBus.minerals_changed.emit(0)
	await _transition_to_scene("res://src/levels/Overworld.tscn")

func complete_run() -> void:
	var summary_scene = load("res://src/ui/RunSummary.tscn")
	var summary = summary_scene.instantiate()
	get_tree().root.add_child(summary)
	# Note: RunSummary handles banking and returning to Overworld

func load_mining_level(scene_path: String = "") -> void:
	run_mineral_currency = 0 # Reset run currency on entry
	run_ore_counts.clear()
	run_ore_earnings.clear()
	current_energy = get_max_energy() # Reset energy on entry

	# Apply settlement carry-over bonuses then clear them
	if settlement_energy_bonus > 0:
		current_energy = mini(current_energy + settlement_energy_bonus, get_max_energy() + settlement_energy_bonus)
		settlement_energy_bonus = 0
	# shroom / mandible / forager bonuses are consumed by MiningLevel on entry

	EventBus.minerals_changed.emit(0)
	EventBus.energy_changed.emit(current_energy, get_max_energy())
	var path = scene_path if scene_path != "" else "res://src/levels/MiningLevel.tscn"
	await _transition_to_scene(path)

func load_settlement_level(scene_path: String) -> void:
	# Visit a settlement without resetting run state — player keeps banked minerals
	await _transition_to_scene(scene_path)

func load_overworld() -> void:
	await _transition_to_scene("res://src/levels/Overworld.tscn")

func _transition_to_scene(scene_path: String) -> void:
	await SceneTransition.fade_to_black(0.5)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().create_timer(0.1).timeout
	await SceneTransition.fade_from_black(0.5)

func upgrade_carapace() -> void:
	carapace_level += 1
	save_game()
	print("Carapace upgraded to level ", carapace_level)

func upgrade_legs() -> void:
	legs_level += 1
	save_game()
	print("Legs upgraded to level ", legs_level)

func upgrade_mandibles() -> void:
	mandibles_level += 1
	save_game()
	print("Mandibles upgraded to level ", mandibles_level)

func upgrade_mineral_sense() -> void:
	mineral_sense_level += 1
	save_game()
	print("Mineral Sense upgraded to level ", mineral_sense_level)

func get_sonar_ping_radius() -> float:
	return 4.0 + mineral_sense_level * 3.0 + (3.0 if sense_gem_socketed else 0.0) \
		+ (3.0 if deep_antenna_built else 0.0)

## Multiplier applied to all mined tile mineral yields (Fungus Garden chamber).
func get_mineral_yield_mult() -> float:
	return 1.10 if fungus_garden_built else 1.0

## Bonus carry capacity added to the Scout Cat (Kitten Den).
func get_forager_carry_bonus() -> int:
	return 20 if brood_chamber_built else 0

## Extra tiles added to each side of the explosive blast radius (Armory).
func get_explosive_radius_bonus() -> int:
	return 1 if armory_built else 0

## Extra base fossil find rate per eligible tile mined (Nursery Vault).
func get_fossil_rate_bonus() -> float:
	return 0.05 if nursery_vault_built else 0.0

func get_sonar_ping_energy_cost() -> int:
	return maxi(3, 10 - mineral_sense_level * 2)

func get_max_health() -> int:
	return 3 + carapace_level + (1 if carapace_gem_socketed else 0)

func get_max_speed() -> float:
	return 300.0 + (legs_level * 30.0) + (15.0 if legs_gem_socketed else 0.0)

func get_mandibles_power() -> int:
	return 5 + (mandibles_level * 3) + (4 if mandibles_gem_socketed else 0)

func consume_energy(amount: int) -> bool:
	current_energy -= amount
	if current_energy < 0:
		current_energy = 0
	EventBus.energy_changed.emit(current_energy, get_max_energy())
	return current_energy > 0

func restore_energy(amount: int) -> void:
	current_energy = min(current_energy + amount, get_max_energy())
	EventBus.energy_changed.emit(current_energy, get_max_energy())

func reenergy_completely(cost: int) -> bool:
	if run_mineral_currency >= cost:
		run_mineral_currency -= cost
		current_energy = get_max_energy()
		EventBus.minerals_changed.emit(run_mineral_currency)
		EventBus.energy_changed.emit(current_energy, get_max_energy())
		return true
	return false

func is_out_of_energy() -> bool:
	return current_energy <= 0

func save_game() -> void:
	var save_data = {
		"mineral_currency": mineral_currency,
		"carapace_level": carapace_level,
		"legs_level": legs_level,
		"mandibles_level": mandibles_level,
		"mineral_sense_level": mineral_sense_level,
		"settlement_energy_bonus": settlement_energy_bonus,
		"settlement_forager_bonus": settlement_forager_bonus,
		"settlement_shroom_charges": settlement_shroom_charges,
		"settlement_mandible_bonus": settlement_mandible_bonus,
		"gem_count": gem_count,
		"carapace_gem_socketed": carapace_gem_socketed,
		"legs_gem_socketed": legs_gem_socketed,
		"mandibles_gem_socketed": mandibles_gem_socketed,
		"sense_gem_socketed": sense_gem_socketed,
		"total_minerals_banked": total_minerals_banked,
		"bosses_defeated_total": bosses_defeated_total,
		"total_fossils": total_fossils,
		"deepest_row_reached": deepest_row_reached,
		"fungus_garden_built": fungus_garden_built,
		"brood_chamber_built": brood_chamber_built,
		"armory_built": armory_built,
		"nursery_vault_built": nursery_vault_built,
		"deep_antenna_built": deep_antenna_built,
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game saved")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found")
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var data = json.data
			mineral_currency = data.get("mineral_currency", 0)
			carapace_level = data.get("carapace_level", 0)
			legs_level = data.get("legs_level", 0)
			mandibles_level = data.get("mandibles_level", 0)
			mineral_sense_level = data.get("mineral_sense_level", 0)
			settlement_energy_bonus = data.get("settlement_energy_bonus", 0)
			settlement_forager_bonus = data.get("settlement_forager_bonus", 0)
			settlement_shroom_charges = data.get("settlement_shroom_charges", 0)
			settlement_mandible_bonus = data.get("settlement_mandible_bonus", 0)
			gem_count = data.get("gem_count", 0)
			carapace_gem_socketed = data.get("carapace_gem_socketed", false)
			legs_gem_socketed = data.get("legs_gem_socketed", false)
			mandibles_gem_socketed = data.get("mandibles_gem_socketed", false)
			sense_gem_socketed = data.get("sense_gem_socketed", false)
			total_minerals_banked = data.get("total_minerals_banked", 0)
			bosses_defeated_total = data.get("bosses_defeated_total", 0)
			total_fossils = data.get("total_fossils", 0)
			deepest_row_reached = data.get("deepest_row_reached", 0)
			fungus_garden_built = data.get("fungus_garden_built", false)
			brood_chamber_built = data.get("brood_chamber_built", false)
			armory_built = data.get("armory_built", false)
			nursery_vault_built = data.get("nursery_vault_built", false)
			deep_antenna_built = data.get("deep_antenna_built", false)
			print("Game loaded")
		else:
			print("Failed to parse save file")
