extends Control

const WISHLIST_URL = "https://lost-rabbit-digital.itch.io/pickaxe-pioneer"

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var version_label: Label = $VersionLabel
@onready var master_slider: HSlider = $SettingsPanel/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/VBox/SFXRow/SFXSlider
@onready var master_label: Label = $SettingsPanel/VBox/MasterRow/ValueLabel
@onready var music_label: Label = $SettingsPanel/VBox/MusicRow/ValueLabel
@onready var sfx_label: Label = $SettingsPanel/VBox/SFXRow/ValueLabel

# Save slot popup (built in code)
var _save_popup: Control = null
var _popup_mode: String = ""  # "new_game" or "continue"
var _slot_buttons: Array = []
var _delete_buttons: Array = []

# Confirmation dialog for overwriting saves
var _confirm_dialog: Control = null
var _pending_slot_index: int = -1

func _ready() -> void:
	$VBoxContainer/NewGameButton.pressed.connect(_on_new_game_pressed)
	$VBoxContainer/ContinueButton.pressed.connect(_on_continue_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/WishlistButton.pressed.connect(_on_wishlist_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$SettingsPanel/VBox/CloseButton.pressed.connect(_on_settings_close_pressed)
	$CreditsButton.pressed.connect(_on_credits_pressed)
	$CreditsPanel/VBox/CloseButton.pressed.connect(_on_credits_close_pressed)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	# Initialise sliders from saved settings
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	_update_labels()

	settings_panel.hide()
	credits_panel.hide()

	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")

	# Show/hide Continue based on whether any save exists
	$VBoxContainer/ContinueButton.visible = SaveManager.has_any_save()

	_build_save_popup()
	_build_confirm_dialog()

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
	settings_panel.show()

func _on_wishlist_pressed() -> void:
	OS.shell_open(WISHLIST_URL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if credits_panel.visible:
			_on_credits_close_pressed()
			get_viewport().set_input_as_handled()
		elif settings_panel.visible:
			_on_settings_close_pressed()
			get_viewport().set_input_as_handled()
		elif _save_popup != null and _save_popup.visible:
			_on_popup_close()
			get_viewport().set_input_as_handled()

func _on_settings_close_pressed() -> void:
	SettingsManager.save_settings()
	settings_panel.hide()

func _on_credits_pressed() -> void:
	credits_panel.show()

func _on_credits_close_pressed() -> void:
	credits_panel.hide()

# ---------------------------------------------------------------------------
# Volume sliders
# ---------------------------------------------------------------------------

func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	master_label.text = "%d%%" % int(value * 100)

func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	music_label.text = "%d%%" % int(value * 100)

func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	sfx_label.text = "%d%%" % int(value * 100)

func _update_labels() -> void:
	master_label.text = "%d%%" % int(master_slider.value * 100)
	music_label.text = "%d%%" % int(music_slider.value * 100)
	sfx_label.text = "%d%%" % int(sfx_slider.value * 100)

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
		title_node.text = "SELECT SAVE SLOT"
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
	SaveManager.delete_slot(index)
	_refresh_popup()
	# Update continue button visibility
	$VBoxContainer/ContinueButton.visible = SaveManager.has_any_save()

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
