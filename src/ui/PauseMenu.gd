extends CanvasLayer

# Pause menu — shown when Escape is pressed during gameplay.
# Delegates display, audio, and keybind settings to the shared SettingsPanel.

@onready var panel: PanelContainer = $Panel

const SECTION_COLOR := Color(0.9, 0.7, 0.3)

var _settings_panel: Node = null
var _version_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_ui()

func _build_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Title row with X close button at top-right
	var title_row := HBoxContainer.new()
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(title_row)

	var title_spacer := Control.new()
	title_spacer.custom_minimum_size = Vector2(28, 0)
	title_row.add_child(title_spacer)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", SECTION_COLOR)
	title_row.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(28, 28)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(_on_resume_pressed)
	title_row.add_child(close_btn)

	# Resume button
	var resume_btn := Button.new()
	resume_btn.text = "Resume"
	resume_btn.custom_minimum_size = Vector2(0, 36)
	resume_btn.add_theme_font_size_override("font_size", 18)
	resume_btn.tooltip_text = "Back to digging. Those ores won't mine themselves."
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	# Scroll container for settings
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	# Load shared SettingsPanel inside the scroll
	var settings_scene := preload("res://src/ui/SettingsPanel.tscn")
	_settings_panel = settings_scene.instantiate()
	_settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_settings_panel)

	# Bottom buttons
	var sep := HSeparator.new()
	vbox.add_child(sep)

	var exit_btn := Button.new()
	exit_btn.text = "Exit to Main Menu"
	exit_btn.custom_minimum_size = Vector2(0, 36)
	exit_btn.add_theme_font_size_override("font_size", 16)
	exit_btn.tooltip_text = "Abandon your mission. The minerals will miss you."
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

	var version_panel := PanelContainer.new()
	var version_style := StyleBoxFlat.new()
	version_style.bg_color = Color(0.05, 0.05, 0.05, 0.6)
	version_style.corner_radius_top_left = 4
	version_style.corner_radius_top_right = 4
	version_style.corner_radius_bottom_right = 4
	version_style.corner_radius_bottom_left = 4
	version_style.content_margin_left = 8.0
	version_style.content_margin_top = 3.0
	version_style.content_margin_right = 8.0
	version_style.content_margin_bottom = 3.0
	version_panel.add_theme_stylebox_override("panel", version_style)
	version_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_version_label = Label.new()
	_version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	version_panel.add_child(_version_label)
	vbox.add_child(version_panel)

# ---------------------------------------------------------------------------
# Show / Hide
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _settings_panel and _settings_panel.is_listening():
			_settings_panel.cancel_rebind()
		else:
			_on_resume_pressed()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	_settings_panel.sync_settings_ui()
	show()
	if not NetworkManager.is_multiplayer_session:
		get_tree().paused = true
		GameManager.pause_game()

func hide_menu() -> void:
	_settings_panel.close_settings()
	hide()
	if not NetworkManager.is_multiplayer_session:
		get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_resume_pressed() -> void:
	SoundManager.play_ui_click_sound()
	hide_menu()

func _on_exit_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_settings_panel.close_settings()
	if not NetworkManager.is_multiplayer_session:
		get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")

func _input(event: InputEvent) -> void:
	if _settings_panel:
		if _settings_panel.handle_input(event):
			get_viewport().set_input_as_handled()
