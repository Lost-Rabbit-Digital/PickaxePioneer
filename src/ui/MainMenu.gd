extends Control

const WISHLIST_URL = "https://lost-rabbit-digital.itch.io/pickaxe-pioneer"

@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var version_label: Label = $VersionLabel

# Save slot popup (built in code)
var _save_popup: Control = null
var _popup_mode: String = ""  # "new_game" or "continue"
var _slot_buttons: Array = []
var _delete_buttons: Array = []

# Confirmation dialog for overwriting saves
var _confirm_dialog: Control = null
var _pending_slot_index: int = -1

# Confirmation dialog for deleting saves
var _delete_confirm_dialog: Control = null
var _pending_delete_index: int = -1

# Settings overlay (built in code)
var _settings_overlay: Control = null
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
var _keybind_buttons: Dictionary = {}  # action_name -> Button
var _listening_action: String = ""  # action currently being rebound

func _ready() -> void:
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/WishlistButton.pressed.connect(_on_wishlist_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$CreditsButton.pressed.connect(_on_credits_pressed)
	$CreditsPanel/VBox/CloseButton.pressed.connect(_on_credits_close_pressed)

	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")

	# Show/hide Continue based on whether any save exists
	$VBoxContainer/ContinueButton.visible = SaveManager.has_any_save()

	_build_settings_overlay()
	_build_save_popup()
	_build_confirm_dialog()
	_build_delete_confirm_dialog()

	credits_panel.hide()

# ---------------------------------------------------------------------------
# Menu buttons
# ---------------------------------------------------------------------------

func _on_new_game_pressed() -> void:
	_popup_mode = "new_game"
	_refresh_popup()
	_save_popup.show()

func _on_continue_pressed() -> void:
	_popup_mode = "continue"
	_refresh_popup()
	_save_popup.show()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	_sync_settings_ui()
	_settings_overlay.show()

func _on_wishlist_pressed() -> void:
	OS.shell_open(WISHLIST_URL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if credits_panel.visible:
			_on_credits_close_pressed()
			get_viewport().set_input_as_handled()
		elif _settings_overlay != null and _settings_overlay.visible:
			if _listening_action != "":
				_cancel_rebind()
			else:
				_on_settings_close()
			get_viewport().set_input_as_handled()
		elif _save_popup != null and _save_popup.visible:
			_on_popup_close()
			get_viewport().set_input_as_handled()

func _on_credits_pressed() -> void:
	credits_panel.show()

func _on_credits_close_pressed() -> void:
	credits_panel.hide()

# ---------------------------------------------------------------------------
# Settings overlay — built in code
# ---------------------------------------------------------------------------

const SETTINGS_W := 620.0
const SETTINGS_H := 560.0
const SECTION_COLOR := Color(0.9, 0.7, 0.3)
const LABEL_FONT_SIZE := 16
const HEADER_FONT_SIZE := 20

func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.hide()
	add_child(_settings_overlay)

	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.75)
	_settings_overlay.add_child(dimmer)

	# Panel background
	var px := (1280.0 - SETTINGS_W) / 2.0
	var py := (720.0 - SETTINGS_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(SETTINGS_W + 4, SETTINGS_H + 4)
	border.color = Color(0.5, 0.6, 0.9, 0.85)
	_settings_overlay.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(SETTINGS_W, SETTINGS_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_settings_overlay.add_child(bg)

	# Outer VBox for title + scroll + close button
	var outer_vbox := VBoxContainer.new()
	outer_vbox.position = Vector2(px + 16, py + 12)
	outer_vbox.size = Vector2(SETTINGS_W - 32, SETTINGS_H - 24)
	outer_vbox.add_theme_constant_override("separation", 8)
	_settings_overlay.add_child(outer_vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", SECTION_COLOR)
	outer_vbox.add_child(title)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vbox.add_child(scroll)

	# Content VBox inside scroll
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 6)
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

	# Close button (outside scroll, at bottom)
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_settings_close)
	outer_vbox.add_child(close_btn)

func _add_section_header(parent: VBoxContainer, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", HEADER_FONT_SIZE)
	lbl.add_theme_color_override("font_color", SECTION_COLOR)
	parent.add_child(lbl)

func _add_separator(parent: VBoxContainer) -> void:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
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
	vsync_row.add_theme_constant_override("separation", 12)
	var vsync_lbl := Label.new()
	vsync_lbl.text = "V-Sync"
	vsync_lbl.custom_minimum_size = Vector2(160, 0)
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
	var rr_row := _make_option_row("Refresh Rate Cap")
	_refresh_option = rr_row.get_node("Option") as OptionButton
	for rr in SettingsManager.REFRESH_RATE_OPTIONS:
		_refresh_option.add_item("Unlimited" if rr == 0 else "%d Hz" % rr)
	_refresh_option.item_selected.connect(_on_refresh_selected)
	parent.add_child(rr_row)

func _make_option_row(label_text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
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
	row.add_theme_constant_override("separation", 12)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(160, 0)
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

# --- Keybinds ---

func _build_keybinds_section(parent: VBoxContainer) -> void:
	for action in SettingsManager.BINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var lbl := Label.new()
		lbl.text = SettingsManager.ACTION_DISPLAY_NAMES.get(action, action)
		lbl.custom_minimum_size = Vector2(160, 0)
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

		parent.add_child(row)

	# Reset All button
	var reset_all := Button.new()
	reset_all.text = "Reset All Keybinds"
	reset_all.custom_minimum_size = Vector2(0, 34)
	reset_all.add_theme_font_size_override("font_size", 14)
	reset_all.pressed.connect(_on_reset_all_keybinds)
	parent.add_child(reset_all)

# --- Sync UI from SettingsManager ---

func _sync_settings_ui() -> void:
	# Audio
	_master_slider.value = SettingsManager.master_volume
	_music_slider.value = SettingsManager.music_volume
	_sfx_slider.value = SettingsManager.sfx_volume
	_master_label.text = "%d%%" % int(SettingsManager.master_volume * 100)
	_music_label.text = "%d%%" % int(SettingsManager.music_volume * 100)
	_sfx_label.text = "%d%%" % int(SettingsManager.sfx_volume * 100)

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

# --- Settings callbacks ---

func _on_settings_close() -> void:
	_cancel_rebind()
	SettingsManager.save_settings()
	_settings_overlay.hide()

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
	# Accept key or mouse button presses
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

# ---------------------------------------------------------------------------
# Save Slot Popup — built entirely in code
# ---------------------------------------------------------------------------

const POPUP_W := 520.0
const POPUP_H := 420.0
const SLOT_H := 90.0
const SLOT_GAP := 12.0

func _build_save_popup() -> void:
	# Full-screen dimmer + click blocker
	_save_popup = Control.new()
	_save_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_save_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_save_popup.hide()
	add_child(_save_popup)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	_save_popup.add_child(dimmer)

	# Panel background with border
	var px := (1280.0 - POPUP_W) / 2.0
	var py := (720.0 - POPUP_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(POPUP_W + 4, POPUP_H + 4)
	border.color = Color(0.5, 0.6, 0.9, 0.85)
	_save_popup.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(POPUP_W, POPUP_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_save_popup.add_child(bg)

	# Title label (will be updated in _refresh_popup)
	var title := Label.new()
	title.name = "PopupTitle"
	title.position = Vector2(px, py + 10)
	title.size = Vector2(POPUP_W, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	_save_popup.add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.position = Vector2(px + 20, py + 52)
	sep.size = Vector2(POPUP_W - 40, 2)
	sep.color = Color(0.5, 0.6, 0.9, 0.45)
	_save_popup.add_child(sep)

	# Build 3 slot rows
	var slot_y := py + 64
	for i in range(SaveManager.MAX_SLOTS):
		var row := _build_slot_row(i, px + 20, slot_y, POPUP_W - 40)
		slot_y += SLOT_H + SLOT_GAP

	# Close button
	var close_btn := Button.new()
	close_btn.text = "BACK"
	close_btn.position = Vector2(px + (POPUP_W - 140) / 2.0, py + POPUP_H - 52)
	close_btn.size = Vector2(140, 38)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_popup_close)
	_save_popup.add_child(close_btn)

func _build_slot_row(index: int, rx: float, ry: float, rw: float) -> Control:
	var container := Control.new()
	container.position = Vector2(rx, ry)
	container.size = Vector2(rw, SLOT_H)
	_save_popup.add_child(container)

	# Row background
	var row_bg := ColorRect.new()
	row_bg.position = Vector2.ZERO
	row_bg.size = Vector2(rw, SLOT_H)
	row_bg.color = Color(0.12, 0.11, 0.10, 0.8)
	container.add_child(row_bg)

	# Select button (covers most of the row)
	var select_btn := Button.new()
	select_btn.name = "SelectBtn"
	select_btn.position = Vector2(4, 4)
	select_btn.size = Vector2(rw - 90, SLOT_H - 8)
	select_btn.add_theme_font_size_override("font_size", 14)
	select_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	select_btn.pressed.connect(_on_slot_selected.bind(index))
	container.add_child(select_btn)
	_slot_buttons.append(select_btn)

	# Delete button
	var del_btn := Button.new()
	del_btn.name = "DeleteBtn"
	del_btn.text = "DELETE"
	del_btn.position = Vector2(rw - 82, (SLOT_H - 34) / 2.0)
	del_btn.size = Vector2(76, 34)
	del_btn.add_theme_font_size_override("font_size", 13)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	del_btn.pressed.connect(_on_slot_delete.bind(index))
	container.add_child(del_btn)
	_delete_buttons.append(del_btn)

	return container

func _refresh_popup() -> void:
	# Update title
	var title_node: Label = _save_popup.get_node("PopupTitle")
	if _popup_mode == "new_game":
		title_node.text = "New Game - Select Save"
	else:
		title_node.text = "CONTINUE — SELECT SAVE"

	# Update each slot
	for i in range(SaveManager.MAX_SLOTS):
		var summary := SaveManager.get_slot_summary(i)
		var btn: Button = _slot_buttons[i]
		var del_btn: Button = _delete_buttons[i]

		if summary.is_empty():
			btn.text = "  Slot %d  —  EMPTY" % (i + 1)
			del_btn.visible = false
			# In continue mode, can't select empty slots
			btn.disabled = (_popup_mode == "continue")
		else:
			var lines := "  Slot %d" % (i + 1)
			lines += "  |  $%d" % summary.get("dollars", 0)
			lines += "  |  Minerals: %d" % summary.get("minerals", 0)
			lines += "  |  Depth: %d" % summary.get("deepest_row", 0)
			var lvl_sum: int = summary.get("carapace_level", 0) + summary.get("legs_level", 0) + summary.get("mandibles_level", 0) + summary.get("mineral_sense_level", 0)
			lines += "\n  Upgrades: Lv%d total" % lvl_sum
			var last_node: String = summary.get("last_node", "")
			if last_node != "":
				lines += "  |  Last: %s" % last_node
			btn.text = lines
			btn.disabled = false
			del_btn.visible = true

func _on_slot_selected(index: int) -> void:
	if _popup_mode == "new_game":
		# Check if slot has existing data
		var slot_data = SaveManager.get_slot(index)
		if slot_data != null:
			# Slot has existing data, show confirmation dialog
			_pending_slot_index = index
			_show_confirm_dialog(index)
			return
		# Slot is empty, proceed with new game
		_save_popup.hide()
		SaveManager.new_game(index)
	else:
		_save_popup.hide()
		SaveManager.load_slot(index)
	GameManager.start_game()

func _on_slot_delete(index: int) -> void:
	_pending_delete_index = index
	_delete_confirm_dialog.show()

func _on_popup_close() -> void:
	_save_popup.hide()

# ---------------------------------------------------------------------------
# Confirmation Dialog — for overwriting existing saves
# ---------------------------------------------------------------------------

const CONFIRM_DIALOG_W := 440.0
const CONFIRM_DIALOG_H := 240.0

func _build_confirm_dialog() -> void:
	# Full-screen dimmer + click blocker
	_confirm_dialog = Control.new()
	_confirm_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_dialog.hide()
	add_child(_confirm_dialog)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	_confirm_dialog.add_child(dimmer)

	# Panel background with border
	var px := (1280.0 - CONFIRM_DIALOG_W) / 2.0
	var py := (720.0 - CONFIRM_DIALOG_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(CONFIRM_DIALOG_W + 4, CONFIRM_DIALOG_H + 4)
	border.color = Color(0.8, 0.4, 0.2, 0.85)
	_confirm_dialog.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(CONFIRM_DIALOG_W, CONFIRM_DIALOG_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_confirm_dialog.add_child(bg)

	# Title label
	var title := Label.new()
	title.name = "ConfirmTitle"
	title.position = Vector2(px, py + 15)
	title.size = Vector2(CONFIRM_DIALOG_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	title.text = "OVERWRITE SAVE?"
	_confirm_dialog.add_child(title)

	# Message label
	var message := Label.new()
	message.name = "ConfirmMessage"
	message.position = Vector2(px + 20, py + 60)
	message.size = Vector2(CONFIRM_DIALOG_W - 40, 80)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	message.text = "This save slot already contains data.\nAre you sure you want to overwrite it with a new game?"
	_confirm_dialog.add_child(message)

	# Button container
	var button_container := HBoxContainer.new()
	button_container.position = Vector2(px, py + CONFIRM_DIALOG_H - 50)
	button_container.size = Vector2(CONFIRM_DIALOG_W, 40)
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_dialog.add_child(button_container)

	# Cancel button
	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.size = Vector2(120, 38)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_on_confirm_cancel)
	button_container.add_child(cancel_btn)

	# Confirm button
	var confirm_btn := Button.new()
	confirm_btn.text = "OVERWRITE"
	confirm_btn.size = Vector2(120, 38)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	confirm_btn.pressed.connect(_on_confirm_overwrite)
	button_container.add_child(confirm_btn)

func _show_confirm_dialog(slot_index: int) -> void:
	_pending_slot_index = slot_index
	_confirm_dialog.show()

func _on_confirm_cancel() -> void:
	_confirm_dialog.hide()
	_pending_slot_index = -1

func _on_confirm_overwrite() -> void:
	_confirm_dialog.hide()
	_save_popup.hide()
	if _pending_slot_index >= 0:
		SaveManager.new_game(_pending_slot_index)
		GameManager.start_game()
	_pending_slot_index = -1

# ---------------------------------------------------------------------------
# Delete Confirmation Dialog — for deleting existing saves
# ---------------------------------------------------------------------------

func _build_delete_confirm_dialog() -> void:
	_delete_confirm_dialog = Control.new()
	_delete_confirm_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_delete_confirm_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_delete_confirm_dialog.hide()
	add_child(_delete_confirm_dialog)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	_delete_confirm_dialog.add_child(dimmer)

	var px := (1280.0 - CONFIRM_DIALOG_W) / 2.0
	var py := (720.0 - CONFIRM_DIALOG_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(CONFIRM_DIALOG_W + 4, CONFIRM_DIALOG_H + 4)
	border.color = Color(0.8, 0.2, 0.2, 0.85)
	_delete_confirm_dialog.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(CONFIRM_DIALOG_W, CONFIRM_DIALOG_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_delete_confirm_dialog.add_child(bg)

	var title := Label.new()
	title.position = Vector2(px, py + 15)
	title.size = Vector2(CONFIRM_DIALOG_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	title.text = "DELETE SAVE?"
	_delete_confirm_dialog.add_child(title)

	var message := Label.new()
	message.position = Vector2(px + 20, py + 60)
	message.size = Vector2(CONFIRM_DIALOG_W - 40, 80)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	message.text = "Are you sure you want to delete this save?\nThis action cannot be undone."
	_delete_confirm_dialog.add_child(message)

	var button_container := HBoxContainer.new()
	button_container.position = Vector2(px, py + CONFIRM_DIALOG_H - 50)
	button_container.size = Vector2(CONFIRM_DIALOG_W, 40)
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_delete_confirm_dialog.add_child(button_container)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.size = Vector2(120, 38)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_on_delete_confirm_cancel)
	button_container.add_child(cancel_btn)

	var delete_btn := Button.new()
	delete_btn.text = "DELETE"
	delete_btn.size = Vector2(120, 38)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	delete_btn.pressed.connect(_on_delete_confirm_proceed)
	button_container.add_child(delete_btn)

func _on_delete_confirm_cancel() -> void:
	_delete_confirm_dialog.hide()
	_pending_delete_index = -1

func _on_delete_confirm_proceed() -> void:
	_delete_confirm_dialog.hide()
	if _pending_delete_index >= 0:
		SaveManager.delete_slot(_pending_delete_index)
		_refresh_popup()
		$VBoxContainer/ContinueButton.visible = SaveManager.has_any_save()
	_pending_delete_index = -1
