extends Node

# SettingsManager
# Manages audio, display, and keybind settings with persistence.

const SETTINGS_PATH = "user://settings.cfg"

# Audio
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

# Display
var window_mode: int = 0  # 0=Windowed, 1=Fullscreen, 2=Borderless Fullscreen
var resolution: Vector2i = Vector2i(1280, 720)
var vsync_enabled: bool = true
var framerate_cap: int = 0  # 0=Unlimited
var refresh_rate_cap: int = 0  # 0=Unlimited

# Keybinds — stores custom overrides as {action_name: {keycode: int, ...}}
var _default_binds: Dictionary = {}
var custom_binds: Dictionary = {}

# Actions exposed for rebinding
const BINDABLE_ACTIONS: Array[String] = [
	"move_left", "move_right", "jump", "mine", "sprint",
	"interact", "sonar_ping", "toggle_inventory", "toggle_companions_menu",
]

const ACTION_DISPLAY_NAMES: Dictionary = {
	"move_left": "Move Left",
	"move_right": "Move Right",
	"jump": "Jump",
	"mine": "Mine",
	"sprint": "Sprint",
	"interact": "Interact",
	"sonar_ping": "Sonar Ping",
	"toggle_inventory": "Inventory",
	"toggle_companions_menu": "Companions",
}

const FRAMERATE_OPTIONS: Array[int] = [0, 30, 60, 120, 144, 240]
const REFRESH_RATE_OPTIONS: Array[int] = [0, 60, 75, 120, 144, 165, 240]
const WINDOW_MODE_NAMES: Array[String] = ["Windowed", "Fullscreen", "Borderless Fullscreen"]

func _ready() -> void:
	_ensure_audio_buses()
	_capture_default_binds()
	load_settings()

# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_send(idx, "Master")

	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_send(idx, "Master")

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	var db = linear_to_db(master_volume) if master_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	var db = linear_to_db(music_volume) if music_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), db)

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	var db = linear_to_db(sfx_volume) if sfx_volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)

# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

func get_available_resolutions() -> Array[Vector2i]:
	var resolutions: Array[Vector2i] = []
	var screen_size := DisplayServer.screen_get_size()
	var common: Array[Vector2i] = [
		Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1366, 768),
		Vector2i(1280, 720), Vector2i(1024, 768), Vector2i(800, 600),
		Vector2i(2560, 1440), Vector2i(3840, 2160), Vector2i(1440, 900),
		Vector2i(1680, 1050), Vector2i(1920, 1200), Vector2i(2560, 1080),
		Vector2i(3440, 1440),
	]
	for r in common:
		if r.x <= screen_size.x and r.y <= screen_size.y:
			resolutions.append(r)
	resolutions.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x * a.y > b.x * b.y
	)
	if resolutions.is_empty():
		resolutions.append(Vector2i(1280, 720))
	return resolutions

func apply_window_mode(mode: int) -> void:
	window_mode = mode
	match mode:
		0:  # Windowed
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_size(resolution)
			_center_window()
		1:  # Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:  # Borderless Fullscreen
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen_size := DisplayServer.screen_get_size()
			DisplayServer.window_set_size(screen_size)
			DisplayServer.window_set_position(Vector2i.ZERO)

func apply_resolution(res: Vector2i) -> void:
	resolution = res
	if window_mode == 0:  # Only resize in windowed mode
		DisplayServer.window_set_size(res)
		_center_window()

func apply_vsync(enabled: bool) -> void:
	vsync_enabled = enabled
	if enabled:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func apply_framerate_cap(fps: int) -> void:
	framerate_cap = fps
	Engine.max_fps = fps

func apply_refresh_rate_cap(rate: int) -> void:
	refresh_rate_cap = rate
	# Godot doesn't have a direct refresh rate cap API;
	# we approximate by capping max_fps to the refresh rate if it's lower.
	if rate > 0 and (framerate_cap == 0 or rate < framerate_cap):
		Engine.max_fps = rate
	else:
		Engine.max_fps = framerate_cap

func _center_window() -> void:
	var screen_size := DisplayServer.screen_get_size()
	var win_size := DisplayServer.window_get_size()
	DisplayServer.window_set_position((screen_size - win_size) / 2)

# ---------------------------------------------------------------------------
# Keybinds
# ---------------------------------------------------------------------------

func _capture_default_binds() -> void:
	for action in BINDABLE_ACTIONS:
		if InputMap.has_action(action):
			var events := InputMap.action_get_events(action)
			_default_binds[action] = events.duplicate()

func get_action_event(action: String) -> InputEvent:
	var events := InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0]
	return null

func get_event_display_name(event: InputEvent) -> String:
	if event == null:
		return "None"
	if event is InputEventKey:
		var k: InputEventKey = event
		return OS.get_keycode_string(k.keycode) if k.keycode != 0 else OS.get_keycode_string(k.physical_keycode)
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		match mb.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel Up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
			_: return "Mouse %d" % mb.button_index
	return event.as_text()

func rebind_action(action: String, new_event: InputEvent) -> void:
	if not InputMap.has_action(action):
		return
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	custom_binds[action] = _serialize_event(new_event)

func reset_action(action: String) -> void:
	if not _default_binds.has(action):
		return
	InputMap.action_erase_events(action)
	for ev in _default_binds[action]:
		InputMap.action_add_event(action, ev)
	custom_binds.erase(action)

func reset_all_keybinds() -> void:
	for action in BINDABLE_ACTIONS:
		reset_action(action)

func _serialize_event(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "keycode": event.keycode, "physical_keycode": event.physical_keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse", "button_index": event.button_index}
	return {}

func _deserialize_event(data: Dictionary) -> InputEvent:
	match data.get("type", ""):
		"key":
			var ev := InputEventKey.new()
			ev.keycode = data.get("keycode", 0) as Key
			ev.physical_keycode = data.get("physical_keycode", 0) as Key
			return ev
		"mouse":
			var ev := InputEventMouseButton.new()
			ev.button_index = data.get("button_index", 1) as MouseButton
			return ev
	return null

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func save_settings() -> void:
	var config = ConfigFile.new()
	# Audio
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	# Display
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "resolution_x", resolution.x)
	config.set_value("display", "resolution_y", resolution.y)
	config.set_value("display", "vsync", vsync_enabled)
	config.set_value("display", "framerate_cap", framerate_cap)
	config.set_value("display", "refresh_rate_cap", refresh_rate_cap)
	# Keybinds
	for action in custom_binds:
		var d: Dictionary = custom_binds[action]
		config.set_value("keybinds", action + "_type", d.get("type", ""))
		config.set_value("keybinds", action + "_keycode", d.get("keycode", 0))
		config.set_value("keybinds", action + "_physical_keycode", d.get("physical_keycode", 0))
		config.set_value("keybinds", action + "_button_index", d.get("button_index", 0))
	config.save(SETTINGS_PATH)

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		# First run — apply defaults
		apply_vsync(vsync_enabled)
		apply_framerate_cap(framerate_cap)
		set_master_volume(master_volume)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)
		return
	# Audio
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	set_master_volume(master_volume)
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	# Display
	window_mode = config.get_value("display", "window_mode", 0)
	resolution = Vector2i(
		config.get_value("display", "resolution_x", 1280),
		config.get_value("display", "resolution_y", 720)
	)
	vsync_enabled = config.get_value("display", "vsync", true)
	framerate_cap = config.get_value("display", "framerate_cap", 0)
	refresh_rate_cap = config.get_value("display", "refresh_rate_cap", 0)
	apply_vsync(vsync_enabled)
	apply_framerate_cap(framerate_cap)
	apply_refresh_rate_cap(refresh_rate_cap)
	apply_window_mode(window_mode)
	if window_mode == 0:
		apply_resolution(resolution)
	# Keybinds
	if config.has_section("keybinds"):
		for action in BINDABLE_ACTIONS:
			var t: String = config.get_value("keybinds", action + "_type", "")
			if t == "":
				continue
			var data := {
				"type": t,
				"keycode": config.get_value("keybinds", action + "_keycode", 0),
				"physical_keycode": config.get_value("keybinds", action + "_physical_keycode", 0),
				"button_index": config.get_value("keybinds", action + "_button_index", 0),
			}
			var ev := _deserialize_event(data)
			if ev:
				custom_binds[action] = data
				rebind_action(action, ev)
