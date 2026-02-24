extends Node

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.MENU
var scrap_currency: int = 0
var run_scrap_currency: int = 0
var last_overworld_node_name: String = ""

# Upgrade levels
var hull_level: int = 0
var engine_level: int = 0
var drill_level: int = 0

const SAVE_PATH = "user://save_data.json"

func _ready() -> void:
	print("GameManager initialized")
	load_game()

func add_currency(amount: int) -> void:
	run_scrap_currency += amount
	EventBus.scrap_changed.emit(run_scrap_currency)

func bank_currency() -> void:
	scrap_currency += run_scrap_currency
	run_scrap_currency = 0
	EventBus.scrap_changed.emit(0)

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
	run_scrap_currency = 0
	EventBus.scrap_changed.emit(0)
	await _transition_to_scene("res://src/levels/Overworld.tscn")

func complete_run() -> void:
	var summary_scene = load("res://src/ui/RunSummary.tscn")
	var summary = summary_scene.instantiate()
	get_tree().root.add_child(summary)
	# Note: RunSummary handles banking and returning to Overworld

func load_mining_level(scene_path: String = "") -> void:
	run_scrap_currency = 0 # Reset run currency on entry
	EventBus.scrap_changed.emit(0)
	var path = scene_path if scene_path != "" else "res://src/levels/MiningLevel.tscn"
	await _transition_to_scene(path)

func load_overworld() -> void:
	await _transition_to_scene("res://src/levels/Overworld.tscn")

func _transition_to_scene(scene_path: String) -> void:
	await SceneTransition.fade_to_black(0.5)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().create_timer(0.1).timeout
	await SceneTransition.fade_from_black(0.5)

func upgrade_hull() -> void:
	hull_level += 1
	save_game()
	print("Hull upgraded to level ", hull_level)

func upgrade_engine() -> void:
	engine_level += 1
	save_game()
	print("Engine upgraded to level ", engine_level)

func upgrade_drill() -> void:
	drill_level += 1
	save_game()
	print("Drill upgraded to level ", drill_level)

func get_max_health() -> int:
	return 3 + hull_level

func get_max_speed() -> float:
	return 300.0 + (engine_level * 30.0)

func get_drill_damage() -> int:
	return 5 + (drill_level * 3)

func save_game() -> void:
	var save_data = {
		"scrap_currency": scrap_currency,
		"hull_level": hull_level,
		"engine_level": engine_level,
		"drill_level": drill_level
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
			scrap_currency = data.get("scrap_currency", 0)
			hull_level = data.get("hull_level", 0)
			engine_level = data.get("engine_level", 0)
			drill_level = data.get("drill_level", 0)
			print("Game loaded")
		else:
			print("Failed to parse save file")
