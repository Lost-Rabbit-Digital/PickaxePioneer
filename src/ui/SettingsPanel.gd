extends VBoxContainer

# SettingsPanel — shared settings UI used by both MainMenu and PauseMenu.
# Contains display, audio (with music player controls), and rebindable keybinds.

signal settings_closed

# Display
@onready var _resolution_option: OptionButton = $ResolutionRow/ResolutionOption
@onready var _window_mode_option: OptionButton = $WindowModeRow/WindowModeOption
@onready var _vsync_check: CheckButton = $VSyncRow/VSyncCheck
@onready var _fps_option: OptionButton = $FramerateCapRow/FramerateCapOption
@onready var _refresh_option: OptionButton = $RefreshRateCapRow/RefreshRateCapOption

# Audio
@onready var _master_slider: HSlider = $MasterRow/MasterSlider
@onready var _master_label: Label = $MasterRow/MasterValue
@onready var _music_slider: HSlider = $MusicRow/MusicSlider
@onready var _music_label: Label = $MusicRow/MusicValue
@onready var _sfx_slider: HSlider = $SFXRow/SFXSlider
@onready var _sfx_label: Label = $SFXRow/SFXValue

# Music player controls
@onready var _now_playing_label: Label = $NowPlayingRow/NowPlayingTrack
@onready var _play_pause_btn: Button = $MusicControlsRow/PlayPauseButton

var _keybind_buttons: Dictionary = {}
var _listening_action: String = ""


func _ready() -> void:
	# Display — populate dynamic options
	_populate_resolutions()
	for i in range(SettingsManager.WINDOW_MODE_NAMES.size()):
		_window_mode_option.add_item(SettingsManager.WINDOW_MODE_NAMES[i], i)
	for fps in SettingsManager.FRAMERATE_OPTIONS:
		_fps_option.add_item("Unlimited" if fps == 0 else "%d FPS" % fps)
	for rr in SettingsManager.REFRESH_RATE_OPTIONS:
		_refresh_option.add_item("Unlimited" if rr == 0 else "%d Hz" % rr)

	# Connect display signals
	_resolution_option.item_selected.connect(_on_resolution_selected)
	_window_mode_option.item_selected.connect(_on_window_mode_selected)
	_vsync_check.toggled.connect(_on_vsync_toggled)
	_fps_option.item_selected.connect(_on_fps_selected)
	_refresh_option.item_selected.connect(_on_refresh_selected)

	# Connect audio signals
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	$MusicControlsRow/PrevButton.pressed.connect(_on_music_prev_pressed)
	_play_pause_btn.pressed.connect(_on_music_play_pause_pressed)
	$MusicControlsRow/NextButton.pressed.connect(_on_music_next_pressed)

	# Connect keybind rows
	for action in SettingsManager.BINDABLE_ACTIONS:
		var row := get_node("KeybindRow_" + action) as HBoxContainer
		var bind_btn := row.get_node("BindBtn") as Button
		_keybind_buttons[action] = bind_btn
		bind_btn.pressed.connect(_on_keybind_pressed.bind(action))
		row.get_node("ResetBtn").pressed.connect(_on_keybind_reset.bind(action))

	$ResetAllKeybinds.pressed.connect(_on_reset_all_keybinds)

	_refresh_music_controls()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _populate_resolutions() -> void:
	_resolution_option.clear()
	var resolutions := SettingsManager.get_available_resolutions()
	for r in resolutions:
		_resolution_option.add_item("%dx%d" % [r.x, r.y])


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
