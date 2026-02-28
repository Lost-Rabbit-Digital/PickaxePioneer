extends Control

const WISHLIST_URL = "https://lost-rabbit-digital.itch.io/pickaxe-pioneer"

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel
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

	# Show/hide Continue based on whether any save exists
	$VBoxContainer/ContinueButton.visible = SaveManager.has_any_save()

	_build_save_popup()

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

func _on_settings_close_pressed() -> void:
	SettingsManager.save_settings()
	settings_panel.hide()

func _on_credits_pressed() -> void:
	credits_panel.show()

func _on_credits_close_pressed() -> void:
	credits_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if credits_panel.visible and event.is_action_pressed("ui_cancel"):
		_on_credits_close_pressed()
		get_viewport().set_input_as_handled()

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
	_save_popup.hide()
	if _popup_mode == "new_game":
		SaveManager.new_game(index)
	else:
		SaveManager.load_slot(index)
	GameManager.start_game()

func _on_slot_delete(index: int) -> void:
	SaveManager.delete_slot(index)
	_refresh_popup()
	# Update continue button visibility
	$VBoxContainer/ContinueButton.visible = SaveManager.has_any_save()

func _on_popup_close() -> void:
	_save_popup.hide()
