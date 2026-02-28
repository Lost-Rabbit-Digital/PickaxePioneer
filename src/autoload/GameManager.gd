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
var dollars: int = 0  # Persistent currency earned by selling bars at the smeltery
# Per-ore tracking for run summary (tile_type_id -> count/minerals)
var run_ore_counts: Dictionary = {}
var run_ore_earnings: Dictionary = {}

# Base ore capacity per run (can be expanded by Cargo Bay spaceship upgrade)
const BASE_ORE_CAPACITY: int = 50
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

# Spaceship Upgrade system — permanent ship upgrades unlocked by milestone conditions.
# Unlock conditions are checked at runtime; build costs are spent from dollars.
const SHIP_COST_WARP_DRIVE: int       = 200   # unlocks when total_minerals_banked >= 500
const SHIP_COST_CARGO_BAY: int        = 150   # unlocks when bosses_defeated_total >= 1
const SHIP_COST_LONG_SCANNER: int     = 300   # unlocks when total_minerals_banked >= 1000
const SHIP_COST_GEM_REFINERY: int     = 250   # unlocks when total_fossils >= 10
const SHIP_COST_TRADE_AMPLIFIER: int  = 200   # unlocks when deepest_row_reached >= 96

# Cumulative milestone trackers (persisted to save)
var total_minerals_banked: int = 0       # sum of all currency ever banked
var bosses_defeated_total: int = 0       # total boss encounters won
var total_fossils: int = 0               # total fossils found across all runs
var deepest_row_reached: int = 0         # deepest grid row ever reached

# Spaceship upgrade built flags (persisted to save)
var warp_drive_built: bool = false       # 2x caravan travel speed on overworld
var cargo_bay_built: bool = false        # +25 ore carrying capacity per run
var long_scanner_built: bool = false     # always show both asteroid mines on overworld
var gem_refinery_built: bool = false     # +1 bonus gem per gem ore mined
var trade_amplifier_built: bool = false  # +25% dollar payout when selling bars

const SAVE_PATH = "user://save_data.json"

func _ready() -> void:
	print("GameManager initialized")
	# Legacy load_game() removed — SaveManager now handles slot-based persistence.
	# On first boot, SaveManager._migrate_legacy_save() imports the old file.

func add_currency(amount: int) -> void:
	run_mineral_currency += amount
	EventBus.minerals_changed.emit(run_mineral_currency)

func add_dollars(amount: int) -> void:
	dollars += amount
	EventBus.dollars_changed.emit(dollars)
	save_game()

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
	# Clear planet config so the overworld re-randomizes on next visit
	SaveManager.clear_active_slot_run_data()
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
	return 4.0 + mineral_sense_level * 3.0 + (3.0 if sense_gem_socketed else 0.0)

## Ore carrying capacity per run (boosted by Cargo Bay upgrade).
func get_ore_capacity() -> int:
	return BASE_ORE_CAPACITY + (25 if cargo_bay_built else 0)

## Caravan travel speed multiplier on the overworld (boosted by Warp Drive).
func get_ship_speed_mult() -> float:
	return 2.0 if warp_drive_built else 1.0

## Bonus gems awarded per gem ore mined (boosted by Gem Refinery).
func get_gem_mine_bonus() -> int:
	return 1 if gem_refinery_built else 0

## Dollar sell multiplier for smeltery bars (boosted by Trade Amplifier).
func get_dollar_sell_mult() -> float:
	return 1.25 if trade_amplifier_built else 1.0

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
	SaveManager.save_active_slot()
	print("Game saved (slot %d)" % SaveManager.active_slot)
