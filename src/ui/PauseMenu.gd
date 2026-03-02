extends CanvasLayer

# Pause menu — shown when Escape is pressed during mining.
# Handles display, audio, and keybind settings with scrollable layout.

@onready var panel: PanelContainer = $Panel

const LABEL_FONT_SIZE := 15
const HEADER_FONT_SIZE := 18
const SECTION_COLOR := Color(0.9, 0.7, 0.3)

# UI references (built in code)
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _master_label: Label
var _music_label: Label
var _sfx_label: Label
var _resolution_option: OptionButton
var _window_mode_option: OptionButton
var _vsync_check: CheckButton
var _fps_option: OptionButton
var _refresh_option: OptionButton
var _keybind_buttons: Dictionary = {}
var _listening_action: String = ""
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

	# Title
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", SECTION_COLOR)
	vbox.add_child(title)

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

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 5)
	scroll.add_child(content)

	# --- DISPLAY SECTION ---
	_add_section_header(content, "DISPLAY")
	_build_display_section(content)
	_add_separator(content)

	# --- AUDIO SECTION ---
	_add_section_header(content, "AUDIO")
	_build_audio_section(content)
	_add_separator(content)

	# --- KEYBINDS SECTION ---
	_add_section_header(content, "KEYBINDS")
	_build_keybinds_section(content)

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

	_version_label = Label.new()
	_version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")
	_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_version_label.add_theme_font_size_override("font_size", 12)
	_version_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	vbox.add_child(_version_label)

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	lbl.add_theme_color_override("font_color", SECTION_COLOR)
	parent.add_child(lbl)

func _add_separator(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	parent.add_child(sep)

# --- Display ---

func _build_display_section(parent: VBoxContainer) -> void:
	# Resolution
	var res_row := _make_option_row("Resolution")
	_resolution_option = res_row.get_node("Option") as OptionButton
	_populate_resolutions()
	_resolution_option.item_selected.connect(_on_resolution_selected)
	parent.add_child(res_row)

	# Window Mode
	var wm_row := _make_option_row("Window Mode")
	_window_mode_option = wm_row.get_node("Option") as OptionButton
	for i in range(SettingsManager.WINDOW_MODE_NAMES.size()):
		_window_mode_option.add_item(SettingsManager.WINDOW_MODE_NAMES[i], i)
	_window_mode_option.item_selected.connect(_on_window_mode_selected)
	parent.add_child(wm_row)

	# V-Sync
	var vsync_row := HBoxContainer.new()
	vsync_row.add_theme_constant_override("separation", 10)
	var vsync_lbl := Label.new()
	vsync_lbl.text = "V-Sync"
	vsync_lbl.custom_minimum_size = Vector2(130, 0)
	vsync_lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	vsync_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vsync_row.add_child(vsync_lbl)
	_vsync_check = CheckButton.new()
	_vsync_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vsync_check.toggled.connect(_on_vsync_toggled)
	vsync_row.add_child(_vsync_check)
	parent.add_child(vsync_row)

	# Framerate Cap
	var fps_row := _make_option_row("Framerate Cap")
	_fps_option = fps_row.get_node("Option") as OptionButton
	for fps in SettingsManager.FRAMERATE_OPTIONS:
		_fps_option.add_item("Unlimited" if fps == 0 else "%d FPS" % fps)
	_fps_option.item_selected.connect(_on_fps_selected)
	parent.add_child(fps_row)

	# Refresh Rate Cap
	var rr_row := _make_option_row("Refresh Rate")
	_refresh_option = rr_row.get_node("Option") as OptionButton
	for rr in SettingsManager.REFRESH_RATE_OPTIONS:
		_refresh_option.add_item("Unlimited" if rr == 0 else "%d Hz" % rr)
	_refresh_option.item_selected.connect(_on_refresh_selected)
	parent.add_child(rr_row)

func _make_option_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(130, 0)
	lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.name = "Option"
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	row.add_child(opt)
	return row

func _populate_resolutions() -> void:
	_resolution_option.clear()
	var resolutions := SettingsManager.get_available_resolutions()
	for r in resolutions:
		_resolution_option.add_item("%dx%d" % [r.x, r.y])

# --- Audio ---

func _build_audio_section(parent: VBoxContainer) -> void:
	var master_row := _make_slider_row("Master")
	_master_slider = master_row.get_node("Slider") as HSlider
	_master_label = master_row.get_node("Value") as Label
	_master_slider.value_changed.connect(_on_master_changed)
	parent.add_child(master_row)

	var music_row := _make_slider_row("Music")
	_music_slider = music_row.get_node("Slider") as HSlider
	_music_label = music_row.get_node("Value") as Label
	_music_slider.value_changed.connect(_on_music_changed)
	parent.add_child(music_row)

	var sfx_row := _make_slider_row("SFX")
	_sfx_slider = sfx_row.get_node("Slider") as HSlider
	_sfx_label = sfx_row.get_node("Value") as Label
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	parent.add_child(sfx_row)

func _make_slider_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(130, 0)
	lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.name = "Slider"
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(160, 0)
	row.add_child(slider)
	var val_lbl := Label.new()
	val_lbl.name = "Value"
	val_lbl.custom_minimum_size = Vector2(48, 0)
	val_lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.text = "100%"
	row.add_child(val_lbl)
	return row

# --- Keybinds ---

func _build_keybinds_section(parent: VBoxContainer) -> void:
	for action in SettingsManager.BINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)

		var lbl := Label.new()
		lbl.text = SettingsManager.ACTION_DISPLAY_NAMES.get(action, action)
		lbl.custom_minimum_size = Vector2(130, 0)
		lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		var bind_btn := Button.new()
		bind_btn.custom_minimum_size = Vector2(130, 30)
		bind_btn.add_theme_font_size_override("font_size", 13)
		bind_btn.pressed.connect(_on_keybind_pressed.bind(action))
		row.add_child(bind_btn)
		_keybind_buttons[action] = bind_btn

		var reset_btn := Button.new()
		reset_btn.text = "Reset"
		reset_btn.custom_minimum_size = Vector2(52, 30)
		reset_btn.add_theme_font_size_override("font_size", 12)
		reset_btn.pressed.connect(_on_keybind_reset.bind(action))
		row.add_child(reset_btn)

		parent.add_child(row)

	var reset_all := Button.new()
	reset_all.text = "Reset All Keybinds"
	reset_all.custom_minimum_size = Vector2(0, 30)
	reset_all.add_theme_font_size_override("font_size", 13)
	reset_all.pressed.connect(_on_reset_all_keybinds)
	parent.add_child(reset_all)

# ---------------------------------------------------------------------------
# Show / Hide
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		if _listening_action != "":
			_cancel_rebind()
		else:
			_on_resume_pressed()
		get_viewport().set_input_as_handled()

func show_menu() -> void:
	_sync_settings_ui()
	show()
	get_tree().paused = true
	GameManager.pause_game()

func hide_menu() -> void:
	_cancel_rebind()
	SettingsManager.save_settings()
	hide()
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.PLAYING)

func _sync_settings_ui() -> void:
	# Audio
	_master_slider.value = SettingsManager.master_volume
	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value = SettingsManager.sfx_volume
	_master_label.text = "%d%%" % int(SettingsManager.master_volume * 100)
	_music_label.text = "%d%%" % int(SettingsManager.music_volume * 100)
	_sfx_label.text = "%d%%" % int(SettingsManager.sfx_volume * 100)

	# Display
	var resolutions := SettingsManager.get_available_resolutions()
	var res_idx := 0
	for i in range(resolutions.size()):
		if resolutions[i] == SettingsManager.resolution:
			res_idx = i
			break
	_resolution_option.selected = res_idx
	_window_mode_option.selected = SettingsManager.window_mode
	_vsync_check.button_pressed = SettingsManager.vsync_enabled

	var fps_idx := 0
	for i in range(SettingsManager.FRAMERATE_OPTIONS.size()):
		if SettingsManager.FRAMERATE_OPTIONS[i] == SettingsManager.framerate_cap:
			fps_idx = i
			break
	_fps_option.selected = fps_idx

	var rr_idx := 0
	for i in range(SettingsManager.REFRESH_RATE_OPTIONS.size()):
		if SettingsManager.REFRESH_RATE_OPTIONS[i] == SettingsManager.refresh_rate_cap:
			rr_idx = i
			break
	_refresh_option.selected = rr_idx

	# Keybinds
	_refresh_keybind_labels()

func _refresh_keybind_labels() -> void:
	for action in SettingsManager.BINDABLE_ACTIONS:
		var btn: Button = _keybind_buttons[action]
		var ev := SettingsManager.get_action_event(action)
		btn.text = SettingsManager.get_event_display_name(ev)

# ---------------------------------------------------------------------------
# Callbacks
# ---------------------------------------------------------------------------

func _on_resume_pressed() -> void:
	hide_menu()

func _on_exit_pressed() -> void:
	_cancel_rebind()
	SettingsManager.save_settings()
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")

func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	_master_label.text = "%d%%" % int(value * 100)

func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	_music_label.text = "%d%%" % int(value * 100)

func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	_sfx_label.text = "%d%%" % int(value * 100)

func _on_resolution_selected(idx: int) -> void:
	var resolutions := SettingsManager.get_available_resolutions()
	if idx >= 0 and idx < resolutions.size():
		SettingsManager.apply_resolution(resolutions[idx])

func _on_window_mode_selected(idx: int) -> void:
	SettingsManager.apply_window_mode(idx)

func _on_vsync_toggled(enabled: bool) -> void:
	SettingsManager.apply_vsync(enabled)

func _on_fps_selected(idx: int) -> void:
	if idx >= 0 and idx < SettingsManager.FRAMERATE_OPTIONS.size():
		SettingsManager.apply_framerate_cap(SettingsManager.FRAMERATE_OPTIONS[idx])

func _on_refresh_selected(idx: int) -> void:
	if idx >= 0 and idx < SettingsManager.REFRESH_RATE_OPTIONS.size():
		SettingsManager.apply_refresh_rate_cap(SettingsManager.REFRESH_RATE_OPTIONS[idx])

# --- Keybind rebinding ---

func _on_keybind_pressed(action: String) -> void:
	if _listening_action != "":
		_cancel_rebind()
	_listening_action = action
	var btn: Button = _keybind_buttons[action]
	btn.text = "Press any key..."
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4))

func _on_keybind_reset(action: String) -> void:
	_cancel_rebind()
	SettingsManager.reset_action(action)
	_refresh_keybind_labels()

func _on_reset_all_keybinds() -> void:
	_cancel_rebind()
	SettingsManager.reset_all_keybinds()
	_refresh_keybind_labels()

func _cancel_rebind() -> void:
	if _listening_action == "":
		return
	var btn: Button = _keybind_buttons[_listening_action]
	btn.remove_theme_color_override("font_color")
	var ev := SettingsManager.get_action_event(_listening_action)
	btn.text = SettingsManager.get_event_display_name(ev)
	_listening_action = ""

func _input(event: InputEvent) -> void:
	if _listening_action == "":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_cancel_rebind()
			get_viewport().set_input_as_handled()
			return
		SettingsManager.rebind_action(_listening_action, event)
		_finish_rebind()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		SettingsManager.rebind_action(_listening_action, event)
		_finish_rebind()
		get_viewport().set_input_as_handled()

func _finish_rebind() -> void:
	var btn: Button = _keybind_buttons[_listening_action]
	btn.remove_theme_color_override("font_color")
	var ev := SettingsManager.get_action_event(_listening_action)
	btn.text = SettingsManager.get_event_display_name(ev)
	_listening_action = ""
