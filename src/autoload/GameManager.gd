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
var last_overworld_node_name: String = ""

# Fuel system
var max_fuel: int = 100
var current_fuel: int = 100

# Upgrade levels
var carapace_level: int = 0
var legs_level: int = 0
var mandibles_level: int = 0

const SAVE_PATH = "user://save_data.json"

func _ready() -> void:
	print("GameManager initialized")
	load_game()

func add_currency(amount: int) -> void:
	run_mineral_currency += amount
	EventBus.minerals_changed.emit(run_mineral_currency)

func bank_currency() -> void:
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
	EventBus.minerals_changed.emit(0)
	await _transition_to_scene("res://src/levels/Overworld.tscn")

func complete_run() -> void:
	var summary_scene = load("res://src/ui/RunSummary.tscn")
	var summary = summary_scene.instantiate()
	get_tree().root.add_child(summary)
	# Note: RunSummary handles banking and returning to Overworld

func load_mining_level(scene_path: String = "") -> void:
	run_mineral_currency = 0 # Reset run currency on entry
	current_fuel = max_fuel # Reset fuel on entry
	EventBus.minerals_changed.emit(0)
	EventBus.fuel_changed.emit(current_fuel, max_fuel)
	var path = scene_path if scene_path != "" else "res://src/levels/MiningLevel.tscn"
	await _transition_to_scene(path)

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

func get_max_health() -> int:
	return 3 + carapace_level

func get_max_speed() -> float:
	return 300.0 + (legs_level * 30.0)

func get_mandibles_power() -> int:
	return 5 + (mandibles_level * 3)

func consume_fuel(amount: int) -> bool:
	current_fuel -= amount
	if current_fuel < 0:
		current_fuel = 0
	EventBus.fuel_changed.emit(current_fuel, max_fuel)
	return current_fuel > 0

func restore_fuel(amount: int) -> void:
	current_fuel = min(current_fuel + amount, max_fuel)
	EventBus.fuel_changed.emit(current_fuel, max_fuel)

func refuel_completely(cost: int) -> bool:
	if run_mineral_currency >= cost:
		run_mineral_currency -= cost
		current_fuel = max_fuel
		EventBus.minerals_changed.emit(run_mineral_currency)
		EventBus.fuel_changed.emit(current_fuel, max_fuel)
		return true
	return false

func is_out_of_fuel() -> bool:
	return current_fuel <= 0

func save_game() -> void:
	var save_data = {
		"mineral_currency": mineral_currency,
		"carapace_level": carapace_level,
		"legs_level": legs_level,
		"mandibles_level": mandibles_level
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
			print("Game loaded")
		else:
			print("Failed to parse save file")
