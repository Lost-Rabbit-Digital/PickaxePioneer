class_name CustomizationMenu
extends CanvasLayer

# Customization Menu — toggle with X key during a mining run.
# Displays a player cat preview on the left and a colour palette on the right.
# Selecting a colour tints the player sprite via modulate and persists via GameManager.

const PANEL_W: int = 620
const PANEL_H: int = 440

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

const SWATCH_SIZE: int = 36
const SWATCH_GAP: int = 4
const SWATCHES_PER_ROW: int = 8

# Set by MiningLevel after instantiation
var player: PlayerProbe = null

var _preview_sprite: AnimatedSprite2D
var _selected_index: int = -1
var _swatch_buttons: Array[Button] = []
var _reset_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_build_ui()

func _build_ui() -> void:
	var vp_w: int = 1280
	var vp_h: int = 720
	var px: int = (vp_w - PANEL_W) / 2
	var py: int = (vp_h - PANEL_H) / 2

	# Dark backdrop
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.72)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)

	# Main panel
	var panel := ColorRect.new()
	panel.color = Color(0.10, 0.09, 0.14, 0.97)
	panel.position = Vector2(px, py)
	panel.size = Vector2(PANEL_W, PANEL_H)
	add_child(panel)

	# Border
	for side in _border_rects(px, py, PANEL_W, PANEL_H, 2):
		var br := ColorRect.new()
		br.color = Color(0.80, 0.62, 0.22, 0.85)
		br.position = side[0]
		br.size = side[1]
		add_child(br)

	# Title
	var title := Label.new()
	title.text = "CUSTOMIZATION"
	title.position = Vector2(px + 20, py + 12)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.00, 0.82, 0.35)
	add_child(title)

	# Close hint
	var hint := Label.new()
	hint.text = "[X] Close"
	hint.position = Vector2(px + PANEL_W - 100, py + 14)
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.55, 0.55, 0.65, 0.90)
	add_child(hint)

	# Separator under title
	var sep := ColorRect.new()
	sep.color = Color(0.80, 0.62, 0.22, 0.40)
	sep.position = Vector2(px + 16, py + 44)
	sep.size = Vector2(PANEL_W - 32, 1)
	add_child(sep)

	# --- Left side: player preview ---
	var preview_x: int = px + 30
	var preview_y: int = py + 60
	var preview_w: int = 160
	var preview_h: int = 320

	# Preview background
	var preview_bg := ColorRect.new()
	preview_bg.color = Color(0.07, 0.06, 0.10, 1.0)
	preview_bg.position = Vector2(preview_x, preview_y)
	preview_bg.size = Vector2(preview_w, preview_h)
	add_child(preview_bg)

	# Preview border
	var pborder := ColorRect.new()
	pborder.color = Color(0.28, 0.24, 0.36, 0.60)
	pborder.position = Vector2(preview_x - 1, preview_y - 1)
	pborder.size = Vector2(preview_w + 2, preview_h + 2)
	pborder.z_index = -1
	add_child(pborder)

	# Animated player preview — loads the same SpriteFrames from the scene
	_preview_sprite = AnimatedSprite2D.new()
	var player_scene := load("res://src/entities/player/PlayerProbe.tscn") as PackedScene
	if player_scene:
		var temp := player_scene.instantiate()
		var source_sprite: AnimatedSprite2D = temp.get_node("AnimatedSprite2D")
		if source_sprite:
			_preview_sprite.sprite_frames = source_sprite.sprite_frames
		temp.queue_free()
	_preview_sprite.scale = Vector2(5.0, 5.0)
	_preview_sprite.position = Vector2(preview_x + preview_w / 2, preview_y + preview_h / 2 - 10)
	_preview_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_preview_sprite.play(&"idle")
	add_child(_preview_sprite)

	# "Your Cat" label under preview
	var preview_label := Label.new()
	preview_label.text = "Your Cat"
	preview_label.position = Vector2(preview_x, preview_y + preview_h + 6)
	preview_label.custom_minimum_size = Vector2(preview_w, 20)
	preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_label.add_theme_font_size_override("font_size", 13)
	preview_label.modulate = Color(0.70, 0.70, 0.75)
	add_child(preview_label)

	# --- Right side: colour palette ---
	var palette_x: int = px + 220
	var palette_y: int = py + 60

	var palette_label := Label.new()
	palette_label.text = "COLOUR"
	palette_label.position = Vector2(palette_x, palette_y - 2)
	palette_label.add_theme_font_size_override("font_size", 14)
	palette_label.modulate = Color(0.80, 0.75, 0.90)
	add_child(palette_label)

	var swatch_start_y: int = palette_y + 24
	for i in range(PALETTE.size()):
		var row: int = i / SWATCHES_PER_ROW
		var col: int = i % SWATCHES_PER_ROW
		var sx: int = palette_x + col * (SWATCH_SIZE + SWATCH_GAP)
		var sy: int = swatch_start_y + row * (SWATCH_SIZE + SWATCH_GAP)
		_create_swatch(i, sx, sy)

	# Reset button (below the swatches)
	var total_rows: int = ceili(float(PALETTE.size()) / SWATCHES_PER_ROW)
	var reset_y: int = swatch_start_y + total_rows * (SWATCH_SIZE + SWATCH_GAP) + 12

	_reset_btn = Button.new()
	_reset_btn.text = "RESET"
	_reset_btn.position = Vector2(palette_x, reset_y)
	_reset_btn.size = Vector2(90, 30)
	_reset_btn.add_theme_font_size_override("font_size", 13)
	_reset_btn.pressed.connect(_on_reset)
	add_child(_reset_btn)

	# Close button at bottom center
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.position = Vector2(px + (PANEL_W - 90) / 2, py + PANEL_H - 46)
	close_btn.size = Vector2(90, 32)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(close)
	add_child(close_btn)

func _create_swatch(index: int, sx: int, sy: int) -> void:
	var btn := Button.new()
	btn.position = Vector2(sx, sy)
	btn.size = Vector2(SWATCH_SIZE, SWATCH_SIZE)
	btn.flat = true

	# Colour fill via a StyleBoxFlat
	var style := StyleBoxFlat.new()
	style.bg_color = PALETTE[index]
	style.border_color = Color(0.30, 0.30, 0.35, 0.60)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.border_color = Color(1.0, 1.0, 1.0, 0.80)
	hover_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.border_color = Color(1.0, 0.82, 0.35, 1.0)
	pressed_style.set_border_width_all(2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	btn.pressed.connect(_on_swatch_pressed.bind(index))
	add_child(btn)
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
			# Match by colour if index not tracked
			if PALETTE[i].is_equal_approx(GameManager.cat_color):
				is_selected = true

		var style := StyleBoxFlat.new()
		style.bg_color = PALETTE[i]
		style.set_corner_radius_all(3)
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

func _border_rects(x: int, y: int, w: int, h: int, t: int) -> Array:
	return [
		[Vector2(x, y),             Vector2(w, t)],
		[Vector2(x, y + h - t),     Vector2(w, t)],
		[Vector2(x, y),             Vector2(t, h)],
		[Vector2(x + w - t, y),     Vector2(t, h)],
	]
