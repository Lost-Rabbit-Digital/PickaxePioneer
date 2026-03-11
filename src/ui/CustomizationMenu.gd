class_name CustomizationMenu
extends Control

# Customization Menu — toggle with X key during a mining run.
# Static UI structure lives in CustomizationMenu.tscn (edit it directly in the Godot editor).
# The colour palette swatches are built dynamically in _ready() from PALETTE.
# BASE row: tints non-outline pixels (multiply, like modulate).
# OUTLINE row: replaces the #2B222A outline pixels with the chosen colour.
# Both values are persisted via GameManager and applied via cat_color.gdshader.

const PALETTE: Array[Color] = [
	Color("3f4328"), Color("5f7132"), Color("94ad39"), Color("c2d64f"),
	Color("eff37c"), Color("e3e6ac"), Color("a5c67c"), Color("739a70"),
	Color("4d6659"), Color("343f41"), Color("282e3b"), Color("1a1f2e"),
	Color("1e314b"), Color("2f4c6c"), Color("3d80a3"), Color("63c4cc"),
	Color("9ae5d5"), Color("e5efef"), Color("bac9cd"), Color("8d99a4"),
	Color("696f80"), Color("414453"), Color("b8a1c2"), Color("7e659b"),
	Color("5c3a6f"), Color("39275e"), Color("2f193e"), Color("4e1a49"),
	Color("7b234c"), Color("b23657"), Color("d16974"), Color("edaaa3"),
	Color("eecb90"), Color("e1a845"), Color("c57835"), Color("8d4830"),
	Color("e47259"), Color("c33c40"), Color("8d3649"), Color("5c2b34"),
	Color("3c252b"), Color("684039"), Color("825646"), Color("b77862"),
	Color("7d595d"), Color("533b41"), Color("3f333b"), Color("2b222a"),
	Color("6d4e4b"), Color("867066"), Color("b49d7e"), Color("c4c6b8"),
]

const BTN_W: int = 78
const BTN_H: int = 24
const BTN_GAP: int = 3
const SWATCHES_PER_ROW: int = 4
const SWATCH_FONT_SIZE: int = 12

const DEFAULT_OUTLINE: Color = Color("2b222a")

# Emitted after any colour change so external scenes (e.g. MainMenu) can react
signal color_changed

# Set by MiningLevel after the scene is ready
var player: PlayerProbe = null

@onready var _preview_sprite: AnimatedSprite2D = $Panel/PreviewSprite
@onready var _base_swatch_container: Control = $Panel/BaseSwatchContainer
@onready var _outline_swatch_container: Control = $Panel/OutlineSwatchContainer

var _selected_base_index: int = -1
var _selected_outline_index: int = -1
var _base_swatch_buttons: Array[Button] = []
var _outline_swatch_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_load_preview_frames()
	_build_swatches(_base_swatch_container, _base_swatch_buttons, _on_base_swatch_pressed)
	_build_swatches(_outline_swatch_container, _outline_swatch_buttons, _on_outline_swatch_pressed)
	$Panel/CloseButton.pressed.connect(close)
	$Panel/ResetButton.pressed.connect(_on_reset)

func _load_preview_frames() -> void:
	var player_scene := load("res://src/entities/player/PlayerProbe.tscn") as PackedScene
	if player_scene:
		var temp := player_scene.instantiate()
		var source_sprite: AnimatedSprite2D = temp.get_node("AnimatedSprite2D")
		if source_sprite:
			_preview_sprite.sprite_frames = source_sprite.sprite_frames
		temp.queue_free()
	_preview_sprite.play(&"idle")
	# Apply shader to preview sprite
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/cat_color.gdshader")
	_preview_sprite.material = mat

func _build_swatches(container: Control, buttons: Array[Button], callback: Callable) -> void:
	for i in range(PALETTE.size()):
		var row: int = i / SWATCHES_PER_ROW
		var col: int = i % SWATCHES_PER_ROW
		var sx: int = col * (BTN_W + BTN_GAP)
		var sy: int = row * (BTN_H + BTN_GAP)
		_create_swatch(i, sx, sy, container, buttons, callback)

func _create_swatch(index: int, sx: int, sy: int, container: Control, buttons: Array[Button], callback: Callable) -> void:
	var btn := Button.new()
	btn.position = Vector2(sx, sy)
	btn.size = Vector2(BTN_W, BTN_H)
	btn.text = ""
	btn.clip_contents = true

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.11, 0.16, 1.0)
	style.border_color = Color(0.30, 0.30, 0.35, 0.60)
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.20, 0.19, 0.26, 1.0)
	hover_style.border_color = Color(1.0, 1.0, 1.0, 0.60)
	hover_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.15, 0.14, 0.20, 1.0)
	pressed_style.border_color = Color(1.0, 0.82, 0.35, 1.0)
	pressed_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.add_theme_stylebox_override("focus", style.duplicate())

	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	var hex: String = PALETTE[index].to_html(false).to_lower()
	rtl.text = "[center][color=#%s]#%s[/color][/center]" % [hex, hex]
	rtl.size = Vector2(BTN_W, BTN_H)
	rtl.position = Vector2(0, 4)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.scroll_active = false
	rtl.add_theme_font_size_override("normal_font_size", SWATCH_FONT_SIZE)
	btn.add_child(rtl)

	btn.pressed.connect(callback.bind(index))
	container.add_child(btn)
	buttons.append(btn)

func _on_base_swatch_pressed(index: int) -> void:
	_selected_base_index = index
	GameManager.cat_color = PALETTE[index]
	GameManager.save_game()
	_update_preview_shader()
	_apply_to_player()
	_refresh_swatch_borders(_base_swatch_buttons, _selected_base_index)
	color_changed.emit()

func _on_outline_swatch_pressed(index: int) -> void:
	_selected_outline_index = index
	GameManager.cat_outline_color = PALETTE[index]
	GameManager.save_game()
	_update_preview_shader()
	_apply_to_player()
	_refresh_swatch_borders(_outline_swatch_buttons, _selected_outline_index)
	color_changed.emit()

func _on_reset() -> void:
	_selected_base_index = -1
	_selected_outline_index = -1
	GameManager.cat_color = Color.WHITE
	GameManager.cat_outline_color = DEFAULT_OUTLINE
	GameManager.save_game()
	_update_preview_shader()
	_apply_to_player()
	_refresh_swatch_borders(_base_swatch_buttons, _selected_base_index)
	_refresh_swatch_borders(_outline_swatch_buttons, _selected_outline_index)
	color_changed.emit()

func _update_preview_shader() -> void:
	if _preview_sprite and _preview_sprite.material is ShaderMaterial:
		var mat := _preview_sprite.material as ShaderMaterial
		mat.set_shader_parameter("base_color", GameManager.cat_color)
		mat.set_shader_parameter("outline_color", GameManager.cat_outline_color)

func _apply_to_player() -> void:
	if player and player.sprite and player.sprite.material is ShaderMaterial:
		var mat := player.sprite.material as ShaderMaterial
		mat.set_shader_parameter("base_color", GameManager.cat_color)
		mat.set_shader_parameter("outline_color", GameManager.cat_outline_color)

func _refresh_swatch_borders(buttons: Array[Button], selected_index: int) -> void:
	for i in range(buttons.size()):
		var btn := buttons[i]
		var is_selected := (selected_index >= 0 and i == selected_index)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.11, 0.16, 1.0)
		style.set_corner_radius_all(2)
		if is_selected:
			style.border_color = Color(1.0, 0.82, 0.35, 1.0)
			style.set_border_width_all(2)
		else:
			style.border_color = Color(0.30, 0.30, 0.35, 0.60)
			style.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", style)

func open() -> void:
	_find_selected_indices()
	_refresh_swatch_borders(_base_swatch_buttons, _selected_base_index)
	_refresh_swatch_borders(_outline_swatch_buttons, _selected_outline_index)
	_update_preview_shader()
	show()
	get_tree().paused = true

func close() -> void:
	SoundManager.play_ui_close_sound()
	hide()
	get_tree().paused = false

func _find_selected_indices() -> void:
	_selected_base_index = -1
	if GameManager.cat_color != Color.WHITE:
		for i in range(PALETTE.size()):
			if PALETTE[i].is_equal_approx(GameManager.cat_color):
				_selected_base_index = i
				break

	_selected_outline_index = -1
	if not GameManager.cat_outline_color.is_equal_approx(DEFAULT_OUTLINE):
		for i in range(PALETTE.size()):
			if PALETTE[i].is_equal_approx(GameManager.cat_outline_color):
				_selected_outline_index = i
				break

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_customization_menu"):
		close()
		get_viewport().set_input_as_handled()
