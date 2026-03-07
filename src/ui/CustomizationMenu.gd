class_name CustomizationMenu
extends Control

# Customization Menu — toggle with X key during a mining run.
# Static UI structure lives in CustomizationMenu.tscn (edit it directly in the Godot editor).
# The colour palette swatches are built dynamically in _ready() from PALETTE.
# Selecting a colour tints the player sprite via modulate and persists via GameManager.

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

# Set by MiningLevel after the scene is ready
var player: PlayerProbe = null

@onready var _preview_sprite: AnimatedSprite2D = $Panel/PreviewSprite
@onready var _swatch_container: Control = $Panel/SwatchContainer

var _selected_index: int = -1
var _swatch_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_load_preview_frames()
	_build_swatches()
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

func _build_swatches() -> void:
	for i in range(PALETTE.size()):
		var row: int = i / SWATCHES_PER_ROW
		var col: int = i % SWATCHES_PER_ROW
		var sx: int = col * (BTN_W + BTN_GAP)
		var sy: int = row * (BTN_H + BTN_GAP)
		_create_swatch(i, sx, sy)

func _create_swatch(index: int, sx: int, sy: int) -> void:
	var btn := Button.new()
	btn.position = Vector2(sx, sy)
	btn.size = Vector2(BTN_W, BTN_H)
	btn.text = ""
	btn.clip_contents = true

	# Normal style: dark neutral background
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

	# RichTextLabel with BBCode: hex code text rendered in its own colour
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

	btn.pressed.connect(_on_swatch_pressed.bind(index))
	_swatch_container.add_child(btn)
	_swatch_buttons.append(btn)

func _on_swatch_pressed(index: int) -> void:
	_selected_index = index
	var color := PALETTE[index]
	GameManager.cat_color = color
	GameManager.save_game()
	_update_preview_color()
	_apply_to_player()
	_refresh_swatch_borders()

func _on_reset() -> void:
	_selected_index = -1
	GameManager.cat_color = Color.WHITE
	GameManager.save_game()
	_update_preview_color()
	_apply_to_player()
	_refresh_swatch_borders()

func _update_preview_color() -> void:
	if _preview_sprite:
		_preview_sprite.modulate = GameManager.cat_color

func _apply_to_player() -> void:
	if player and player.sprite:
		player.sprite.modulate = GameManager.cat_color

func _refresh_swatch_borders() -> void:
	for i in range(_swatch_buttons.size()):
		var btn := _swatch_buttons[i]
		var is_selected := false
		if _selected_index >= 0 and i == _selected_index:
			is_selected = true
		elif _selected_index < 0 and GameManager.cat_color != Color.WHITE:
			if PALETTE[i].is_equal_approx(GameManager.cat_color):
				is_selected = true

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
	_find_selected_index()
	_refresh_swatch_borders()
	_update_preview_color()
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

func _find_selected_index() -> void:
	_selected_index = -1
	if GameManager.cat_color == Color.WHITE:
		return
	for i in range(PALETTE.size()):
		if PALETTE[i].is_equal_approx(GameManager.cat_color):
			_selected_index = i
			return

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_customization_menu"):
		close()
		get_viewport().set_input_as_handled()
