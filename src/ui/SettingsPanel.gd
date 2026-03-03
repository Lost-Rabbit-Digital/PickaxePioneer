extends VBoxContainer

# SettingsPanel — shared settings UI used by both MainMenu and PauseMenu.
# Contains display, audio (with music player controls), and rebindable keybinds.

signal settings_closed

const LABEL_FONT_SIZE := 16
const HEADER_FONT_SIZE := 20
const SECTION_COLOR := Color(0.9, 0.7, 0.3)
const LABEL_WIDTH := 160.0
const ROW_SPACING := 12

# UI references
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider
var _master_label: Label
var _music_label: Label
var _sfx_label: Label
var _now_playing_label: Label
var _play_pause_btn: Button
var _resolution_option: OptionButton
var _window_mode_option: OptionButton
var _vsync_check: CheckButton
var _fps_option: OptionButton
var _refresh_option: OptionButton
var _keybind_buttons: Dictionary = {}
var _listening_action: String = ""


func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	_build_content()


func _build_content() -> void:
	# --- DISPLAY SECTION ---
	_add_section_header("DISPLAY")
	_build_display_section()
	_add_separator()

	# --- AUDIO SECTION ---
	_add_section_header("AUDIO")
	_build_audio_section()
	_add_separator()

	# --- KEYBINDS SECTION ---
	_add_section_header("KEYBINDS")
	_build_keybinds_section()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _add_section_header(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	lbl.add_theme_color_override("font_color", SECTION_COLOR)
	add_child(lbl)


func _add_separator() -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	add_child(sep)


func _make_option_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_SPACING)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	var opt := OptionButton.new()
	opt.name = "Option"
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	row.add_child(opt)
	return row


func _make_slider_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_SPACING)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
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
	slider.custom_minimum_size = Vector2(200, 0)
	row.add_child(slider)
	var val_lbl := Label.new()
	val_lbl.name = "Value"
	val_lbl.custom_minimum_size = Vector2(52, 0)
	val_lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val_lbl.text = "100%"
	row.add_child(val_lbl)
	return row


# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

func _build_display_section() -> void:
	# Resolution
	var res_row := _make_option_row("Resolution")
	_resolution_option = res_row.get_node("Option") as OptionButton
	_populate_resolutions()
	_resolution_option.item_selected.connect(_on_resolution_selected)
	add_child(res_row)

	# Window Mode
	var wm_row := _make_option_row("Window Mode")
	_window_mode_option = wm_row.get_node("Option") as OptionButton
	for i in range(SettingsManager.WINDOW_MODE_NAMES.size()):
		_window_mode_option.add_item(SettingsManager.WINDOW_MODE_NAMES[i], i)
	_window_mode_option.item_selected.connect(_on_window_mode_selected)
	add_child(wm_row)

	# V-Sync
	var vsync_row := HBoxContainer.new()
	vsync_row.add_theme_constant_override("separation", ROW_SPACING)
	var vsync_lbl := Label.new()
	vsync_lbl.text = "V-Sync"
	vsync_lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	vsync_lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	vsync_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vsync_row.add_child(vsync_lbl)
	_vsync_check = CheckButton.new()
	_vsync_check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_vsync_check.toggled.connect(_on_vsync_toggled)
	vsync_row.add_child(_vsync_check)
	add_child(vsync_row)

	# Framerate Cap
	var fps_row := _make_option_row("Framerate Cap")
	_fps_option = fps_row.get_node("Option") as OptionButton
	for fps in SettingsManager.FRAMERATE_OPTIONS:
		_fps_option.add_item("Unlimited" if fps == 0 else "%d FPS" % fps)
	_fps_option.item_selected.connect(_on_fps_selected)
	add_child(fps_row)

	# Refresh Rate Cap
	var rr_row := _make_option_row("Refresh Rate Cap")
	_refresh_option = rr_row.get_node("Option") as OptionButton
	for rr in SettingsManager.REFRESH_RATE_OPTIONS:
		_refresh_option.add_item("Unlimited" if rr == 0 else "%d Hz" % rr)
	_refresh_option.item_selected.connect(_on_refresh_selected)
	add_child(rr_row)


func _populate_resolutions() -> void:
	_resolution_option.clear()
	var resolutions := SettingsManager.get_available_resolutions()
	for r in resolutions:
		_resolution_option.add_item("%dx%d" % [r.x, r.y])


# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------

func _build_audio_section() -> void:
	var master_row := _make_slider_row("Master")
	_master_slider = master_row.get_node("Slider") as HSlider
	_master_label = master_row.get_node("Value") as Label
	_master_slider.value_changed.connect(_on_master_changed)
	add_child(master_row)

	var music_row := _make_slider_row("Music")
	_music_slider = music_row.get_node("Slider") as HSlider
	_music_label = music_row.get_node("Value") as Label
	_music_slider.value_changed.connect(_on_music_changed)
	add_child(music_row)

	var sfx_row := _make_slider_row("SFX")
	_sfx_slider = sfx_row.get_node("Slider") as HSlider
	_sfx_label = sfx_row.get_node("Value") as Label
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	add_child(sfx_row)

	_build_music_player_controls()


func _build_music_player_controls() -> void:
	var now_playing_row := HBoxContainer.new()
	now_playing_row.add_theme_constant_override("separation", ROW_SPACING)
	var np_lbl := Label.new()
	np_lbl.text = "Now Playing"
	np_lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
	np_lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	np_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	now_playing_row.add_child(np_lbl)
	_now_playing_label = Label.new()
	_now_playing_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_now_playing_label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE - 2)
	_now_playing_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_now_playing_label.clip_text = true
	_now_playing_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	now_playing_row.add_child(_now_playing_label)
	add_child(now_playing_row)

	var ctrl_row := HBoxContainer.new()
	ctrl_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ctrl_row.add_theme_constant_override("separation", 8)
	add_child(ctrl_row)

	var prev_btn := Button.new()
	prev_btn.text = "<<"
	prev_btn.custom_minimum_size = Vector2(52, 32)
	prev_btn.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	prev_btn.tooltip_text = "Previous track"
	prev_btn.pressed.connect(_on_music_prev_pressed)
	ctrl_row.add_child(prev_btn)

	_play_pause_btn = Button.new()
	_play_pause_btn.custom_minimum_size = Vector2(72, 32)
	_play_pause_btn.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	_play_pause_btn.tooltip_text = "Play / Pause"
	_play_pause_btn.pressed.connect(_on_music_play_pause_pressed)
	ctrl_row.add_child(_play_pause_btn)

	var next_btn := Button.new()
	next_btn.text = ">>"
	next_btn.custom_minimum_size = Vector2(52, 32)
	next_btn.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	next_btn.tooltip_text = "Next track"
	next_btn.pressed.connect(_on_music_next_pressed)
	ctrl_row.add_child(next_btn)

	_refresh_music_controls()


func _refresh_music_controls() -> void:
	if not _now_playing_label or not _play_pause_btn:
		return
	var has_music: bool = MusicManager.current_player != null \
		and MusicManager.current_player.stream != null
	if has_music:
		_now_playing_label.text = MusicManager.current_player.stream.resource_path \
			.get_file().get_basename()
	else:
		_now_playing_label.text = "—"
	var is_paused: bool = MusicManager._paused or not has_music
	_play_pause_btn.text = "▶" if is_paused else "⏸"


# ---------------------------------------------------------------------------
# Keybinds
# ---------------------------------------------------------------------------

func _build_keybinds_section() -> void:
	for action in SettingsManager.BINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var lbl := Label.new()
		lbl.text = SettingsManager.ACTION_DISPLAY_NAMES.get(action, action)
		lbl.custom_minimum_size = Vector2(LABEL_WIDTH, 0)
		lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(lbl)

		var bind_btn := Button.new()
		bind_btn.custom_minimum_size = Vector2(160, 32)
		bind_btn.add_theme_font_size_override("font_size", 14)
		bind_btn.pressed.connect(_on_keybind_pressed.bind(action))
		row.add_child(bind_btn)
		_keybind_buttons[action] = bind_btn

		var reset_btn := Button.new()
		reset_btn.text = "Reset"
		reset_btn.custom_minimum_size = Vector2(60, 32)
		reset_btn.add_theme_font_size_override("font_size", 13)
		reset_btn.pressed.connect(_on_keybind_reset.bind(action))
		row.add_child(reset_btn)

		add_child(row)

	var reset_all := Button.new()
	reset_all.text = "Reset All Keybinds"
	reset_all.custom_minimum_size = Vector2(0, 34)
	reset_all.add_theme_font_size_override("font_size", 14)
	reset_all.pressed.connect(_on_reset_all_keybinds)
	add_child(reset_all)


# ---------------------------------------------------------------------------
# Sync UI from SettingsManager
# ---------------------------------------------------------------------------

func sync_settings_ui() -> void:
	# Audio
	_master_slider.value = SettingsManager.master_volume
	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value = SettingsManager.sfx_volume
	_master_label.text = "%d%%" % int(SettingsManager.master_volume * 100)
	_music_label.text = "%d%%" % int(SettingsManager.music_volume * 100)
	_sfx_label.text = "%d%%" % int(SettingsManager.sfx_volume * 100)
	_refresh_music_controls()

	# Display — resolution
	var resolutions := SettingsManager.get_available_resolutions()
	var res_idx := 0
	for i in range(resolutions.size()):
		if resolutions[i] == SettingsManager.resolution:
			res_idx = i
			break
	_resolution_option.selected = res_idx

	# Window mode
	_window_mode_option.selected = SettingsManager.window_mode

	# V-Sync
	_vsync_check.button_pressed = SettingsManager.vsync_enabled

	# Framerate cap
	var fps_idx := 0
	for i in range(SettingsManager.FRAMERATE_OPTIONS.size()):
		if SettingsManager.FRAMERATE_OPTIONS[i] == SettingsManager.framerate_cap:
			fps_idx = i
			break
	_fps_option.selected = fps_idx

	# Refresh rate cap
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


## Call this before hiding/closing to save and clean up rebind state.
func close_settings() -> void:
	cancel_rebind()
	SettingsManager.save_settings()
	settings_closed.emit()


## Returns true if currently listening for a keybind.
func is_listening() -> bool:
	return _listening_action != ""


# ---------------------------------------------------------------------------
# Callbacks — Display
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# Callbacks — Audio
# ---------------------------------------------------------------------------

func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	_master_label.text = "%d%%" % int(value * 100)


func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	_music_label.text = "%d%%" % int(value * 100)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	_sfx_label.text = "%d%%" % int(value * 100)


func _on_music_prev_pressed() -> void:
	MusicManager.prev_song()
	_refresh_music_controls()


func _on_music_play_pause_pressed() -> void:
	MusicManager.toggle_pause()
	_refresh_music_controls()


func _on_music_next_pressed() -> void:
	MusicManager.next_song()
	_refresh_music_controls()


# ---------------------------------------------------------------------------
# Callbacks — Keybinds
# ---------------------------------------------------------------------------

func _on_keybind_pressed(action: String) -> void:
	if _listening_action != "":
		cancel_rebind()
	_listening_action = action
	var btn: Button = _keybind_buttons[action]
	btn.text = "Press any key..."
	btn.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4))


func _on_keybind_reset(action: String) -> void:
	cancel_rebind()
	SettingsManager.reset_action(action)
	_refresh_keybind_labels()


func _on_reset_all_keybinds() -> void:
	cancel_rebind()
	SettingsManager.reset_all_keybinds()
	_refresh_keybind_labels()


func cancel_rebind() -> void:
	if _listening_action == "":
		return
	var btn: Button = _keybind_buttons[_listening_action]
	btn.remove_theme_color_override("font_color")
	var ev := SettingsManager.get_action_event(_listening_action)
	btn.text = SettingsManager.get_event_display_name(ev)
	_listening_action = ""


## Call from the parent's _input to forward key/mouse events during rebinding.
func handle_input(event: InputEvent) -> bool:
	if _listening_action == "":
		return false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			cancel_rebind()
			return true
		SettingsManager.rebind_action(_listening_action, event)
		_finish_rebind()
		return true
	elif event is InputEventMouseButton and event.pressed:
		SettingsManager.rebind_action(_listening_action, event)
		_finish_rebind()
		return true
	return false


func _finish_rebind() -> void:
	var btn: Button = _keybind_buttons[_listening_action]
	btn.remove_theme_color_override("font_color")
	var ev := SettingsManager.get_action_event(_listening_action)
	btn.text = SettingsManager.get_event_display_name(ev)
	_listening_action = ""
