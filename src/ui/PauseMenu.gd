extends CanvasLayer

# Pause menu — shown when Escape is pressed during mining.
# Handles audio settings (Master + Music volume) and exit to main menu.

@onready var master_slider: HSlider  = $Panel/VBox/MasterSlider
@onready var music_slider: HSlider   = $Panel/VBox/MusicSlider
@onready var resume_button: Button   = $Panel/VBox/ResumeButton
@onready var exit_button: Button     = $Panel/VBox/ExitButton
@onready var version_label: Label    = $Panel/VBox/VersionLabel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")
	resume_button.pressed.connect(_on_resume_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)

func _unhandled_input(event: InputEvent) -> void:
	# Close pause menu with Escape when visible
	if visible and event.is_action_pressed("ui_cancel"):
		_on_resume_pressed()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	# Sync sliders to current bus volumes before showing
	master_slider.value = _db_to_percent(AudioServer.get_bus_volume_db(0))
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		music_slider.value = _db_to_percent(AudioServer.get_bus_volume_db(music_idx))
		music_slider.editable = true
	else:
		music_slider.value = 100.0
		music_slider.editable = false
	show()
	get_tree().paused = true

func hide_menu() -> void:
	hide()
	get_tree().paused = false

func _db_to_percent(db: float) -> float:
	if db <= -80.0:
		return 0.0
	return db_to_linear(db) * 100.0

func _percent_to_db(percent: float) -> float:
	if percent <= 0.0:
		return -80.0
	return linear_to_db(percent / 100.0)

func _on_resume_pressed() -> void:
	hide_menu()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")

func _on_master_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, _percent_to_db(value))

func _on_music_volume_changed(value: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, _percent_to_db(value))
