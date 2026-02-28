class_name HatMenu
extends CanvasLayer

# Hat Wardrobe — toggle with H key during a mining run.
# Displays all 24 hats in a 6×4 grid; click to preview, Equip to apply.
# Hat selection persists across runs via GameManager.equipped_hat.

const HAT_COUNT: int = 24
const COLS: int = 6
const ROWS: int = 4
const BTN_SZ: int = 72
const BTN_GAP: int = 6
const PANEL_W: int = 720
const PANEL_H: int = 520

# Per-frame offsets [x, y] for the Hat AnimatedSprite2D on the player.
const HAT_OFFSETS: Array = [
	Vector2(2.75, 4.1),    # 0
	Vector2(4.0, 5.1),     # 1
	Vector2(2.75, 3.28),   # 2
	Vector2(3.5, -5.45),   # 3
	Vector2(3.75, 5.0),    # 4
	Vector2(3.75, 3.75),   # 5
	Vector2(3.75, 5.75),   # 6
	Vector2(4.65, 10.12),  # 7
	Vector2(3.75, 9.15),   # 8
	Vector2(3.75, 6.78),   # 9
	Vector2(3.65, 1.4),    # 10
	Vector2(3.39, 0.4),    # 11
	Vector2(3.39, 0.4),    # 12
	Vector2(5.0, -0.7),    # 13
	Vector2(5.0, -0.7),    # 14
	Vector2(5.0, -0.7),    # 15
	Vector2(3.75, -1.6),   # 16
	Vector2(3.75, -2.7),   # 17
	Vector2(3.75, 1.37),   # 18
	Vector2(3.75, 1.37),   # 19
	Vector2(3.75, 1.37),   # 20
	Vector2(3.75, 1.37),   # 21
	Vector2(3.75, 0.29),   # 22
	Vector2(3.75, 1.285),  # 23
]

const HAT_NAMES: Array = [
	"Miner's Cap",
	"Top Hat",
	"Knit Beanie",
	"Royal Crown",
	"Witch Hat",
	"Cowboy Hat",
	"Party Hat",
	"Sombrero",
	"Viking Helm",
	"Knight Helm",
	"Chef's Toque",
	"Fez",
	"Beret",
	"Hard Hat",
	"Miner's Lamp",
	"Pirate Hat",
	"Jester Cap",
	"Cat Ears",
	"Fox Hood",
	"Bunny Ears",
	"Bear Ears",
	"Wizard Hat",
	"Space Helmet",
	"Halo",
]

const HAT_DESCS: Array = [
	"A sturdy cap worn by seasoned miners.",
	"Elegant and distinguished. Pure class.",
	"Keeps your head warm on cold digs.",
	"For the feline of royal heritage.",
	"Magical and mysterious. Beware.",
	"Howdy, partner! Giddy up.",
	"Every day underground is a celebration!",
	"A big, bold statement piece.",
	"Fear me, for I mine with fury!",
	"Honor and steel, deep in the rock.",
	"Whip up something delicious down here.",
	"Stylish and tasseled. Very distinguished.",
	"Mon dieu, tres chic in the mines.",
	"Safety first in the deep dark.",
	"Light the way through the darkness.",
	"Yo ho ho and a pickaxe.",
	"Three jokes for the price of one.",
	"Purrfect for any occasion.",
	"Cunning and swift as a fox.",
	"Hoppy and cheerful underground.",
	"Fluffy and cozy. Very huggable.",
	"Ancient power flows through the brim.",
	"One small step for cats, one giant dig.",
	"Blessed by the stars above the surface.",
]

var _selected_frame: int = -1
var _equipped_frame: int = -1
var _hat_buttons: Array = []

var _preview_icon: TextureRect
var _hat_name_label: Label
var _hat_desc_label: Label
var _currently_label: Label
var _equip_btn: Button

# Set by MiningLevel after instantiation
var player: PlayerProbe = null

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
	var border_color := Color(0.80, 0.62, 0.22, 0.85)
	for side in _border_rects(px, py, PANEL_W, PANEL_H, 2):
		var br := ColorRect.new()
		br.color = border_color
		br.position = side[0]
		br.size = side[1]
		add_child(br)

	# Title
	var title := Label.new()
	title.text = "HAT WARDROBE"
	title.position = Vector2(px + 20, py + 12)
	title.add_theme_font_size_override("font_size", 20)
	title.modulate = Color(1.00, 0.82, 0.35)
	add_child(title)

	# Close hint
	var hint := Label.new()
	hint.text = "[H] Close"
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

	# Hat grid
	_build_grid(px, py)

	# Bottom section separator
	var info_y: int = py + PANEL_H - 136
	var bot_sep := ColorRect.new()
	bot_sep.color = Color(0.80, 0.62, 0.22, 0.35)
	bot_sep.position = Vector2(px + 16, info_y)
	bot_sep.size = Vector2(PANEL_W - 32, 1)
	add_child(bot_sep)

	# Preview icon
	_preview_icon = TextureRect.new()
	_preview_icon.position = Vector2(px + 20, info_y + 10)
	_preview_icon.size = Vector2(88, 88)
	_preview_icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_preview_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_preview_icon)

	# Preview icon border
	for side in _border_rects(px + 20, info_y + 10, 88, 88, 1):
		var br := ColorRect.new()
		br.color = Color(0.80, 0.62, 0.22, 0.30)
		br.position = side[0]
		br.size = side[1]
		add_child(br)

	# Hat name
	_hat_name_label = Label.new()
	_hat_name_label.text = "Select a hat to preview"
	_hat_name_label.position = Vector2(px + 124, info_y + 12)
	_hat_name_label.custom_minimum_size = Vector2(360, 28)
	_hat_name_label.add_theme_font_size_override("font_size", 17)
	_hat_name_label.modulate = Color(1.0, 0.82, 0.35)
	add_child(_hat_name_label)

	# Hat description
	_hat_desc_label = Label.new()
	_hat_desc_label.text = ""
	_hat_desc_label.position = Vector2(px + 124, info_y + 44)
	_hat_desc_label.custom_minimum_size = Vector2(360, 36)
	_hat_desc_label.add_theme_font_size_override("font_size", 12)
	_hat_desc_label.modulate = Color(0.75, 0.75, 0.80)
	_hat_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_hat_desc_label)

	# Currently wearing label
	_currently_label = Label.new()
	_currently_label.text = "No hat equipped"
	_currently_label.position = Vector2(px + 124, info_y + 86)
	_currently_label.custom_minimum_size = Vector2(340, 22)
	_currently_label.add_theme_font_size_override("font_size", 11)
	_currently_label.modulate = Color(0.55, 0.55, 0.60, 0.85)
	add_child(_currently_label)

	# Equip button
	_equip_btn = Button.new()
	_equip_btn.text = "EQUIP"
	_equip_btn.position = Vector2(px + PANEL_W - 192, info_y + 24)
	_equip_btn.size = Vector2(80, 34)
	_equip_btn.add_theme_font_size_override("font_size", 14)
	_equip_btn.pressed.connect(_on_equip_pressed)
	_equip_btn.disabled = true
	add_child(_equip_btn)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.position = Vector2(px + PANEL_W - 100, info_y + 24)
	close_btn.size = Vector2(80, 34)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(close)
	add_child(close_btn)

	# Remove hat button
	var remove_btn := Button.new()
	remove_btn.text = "Remove Hat"
	remove_btn.position = Vector2(px + PANEL_W - 192, info_y + 68)
	remove_btn.size = Vector2(172, 28)
	remove_btn.add_theme_font_size_override("font_size", 11)
	remove_btn.pressed.connect(_on_remove_pressed)
	add_child(remove_btn)

func _build_grid(px: int, py: int) -> void:
	var grid_w: int = COLS * BTN_SZ + (COLS - 1) * BTN_GAP
	var grid_start_x: int = px + (PANEL_W - grid_w) / 2
	var grid_start_y: int = py + 54

	for i in HAT_COUNT:
		var col := i % COLS
		var row := i / COLS
		var bx: int = grid_start_x + col * (BTN_SZ + BTN_GAP)
		var by: int = grid_start_y + row * (BTN_SZ + BTN_GAP)
		var frame_idx := i

		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.15, 0.13, 0.18, 1.0)
		style_normal.set_content_margin_all(8.0)
		style_normal.border_width_left = 1
		style_normal.border_width_right = 1
		style_normal.border_width_top = 1
		style_normal.border_width_bottom = 1
		style_normal.border_color = Color(0.30, 0.26, 0.36, 0.60)

		var style_hover := StyleBoxFlat.new()
		style_hover.bg_color = Color(0.22, 0.19, 0.28, 1.0)
		style_hover.set_content_margin_all(8.0)
		style_hover.border_width_left = 1
		style_hover.border_width_right = 1
		style_hover.border_width_top = 1
		style_hover.border_width_bottom = 1
		style_hover.border_color = Color(0.80, 0.62, 0.22, 0.70)

		var btn := Button.new()
		btn.position = Vector2(bx, by)
		btn.size = Vector2(BTN_SZ, BTN_SZ)
		btn.custom_minimum_size = Vector2(BTN_SZ, BTN_SZ)
		btn.add_theme_stylebox_override("normal", style_normal)
		btn.add_theme_stylebox_override("hover", style_hover)
		btn.add_theme_stylebox_override("pressed", style_hover)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.pressed.connect(func(): _on_hat_selected(frame_idx))

		var tex: Texture2D = load(_get_hat_tex_path(i)) as Texture2D
		var tex_rect := TextureRect.new()
		tex_rect.texture = tex
		tex_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex_rect)

		add_child(btn)
		_hat_buttons.append({"btn": btn, "style": style_normal, "frame": i})

# Maps hat frame index to the hat texture file path.
# Frames 0-16 → hat1-hat17; frames 17-23 → hat19-hat25 (hat18.png unused).
func _get_hat_tex_path(frame: int) -> String:
	var hat_num: int = frame + 1 if frame <= 16 else frame + 2
	return "res://assets/hats/hat%d.png" % hat_num

func _on_hat_selected(frame: int) -> void:
	_selected_frame = frame
	_preview_icon.texture = load(_get_hat_tex_path(frame)) as Texture2D
	_hat_name_label.text = HAT_NAMES[frame]
	_hat_desc_label.text = HAT_DESCS[frame]
	_equip_btn.disabled = false
	_refresh_highlights()

func _refresh_highlights() -> void:
	for entry in _hat_buttons:
		var style: StyleBoxFlat = entry["style"]
		var f: int = entry["frame"]
		if f == _selected_frame:
			style.bg_color = Color(0.32, 0.24, 0.48, 1.0)
			style.border_color = Color(0.80, 0.62, 0.22, 1.0)
		elif f == _equipped_frame:
			style.bg_color = Color(0.14, 0.28, 0.14, 1.0)
			style.border_color = Color(0.30, 0.80, 0.30, 0.70)
		else:
			style.bg_color = Color(0.15, 0.13, 0.18, 1.0)
			style.border_color = Color(0.30, 0.26, 0.36, 0.60)

func _on_equip_pressed() -> void:
	if _selected_frame < 0:
		return
	_equipped_frame = _selected_frame
	GameManager.equipped_hat = _equipped_frame
	GameManager.save_game()
	if player:
		player.equip_hat(_equipped_frame)
	_update_currently_label()
	_refresh_highlights()

func _on_remove_pressed() -> void:
	_equipped_frame = -1
	GameManager.equipped_hat = -1
	GameManager.save_game()
	if player:
		player.equip_hat(-1)
	_update_currently_label()
	_refresh_highlights()

func _update_currently_label() -> void:
	if _equipped_frame < 0:
		_currently_label.text = "No hat equipped"
	else:
		_currently_label.text = "Wearing: " + HAT_NAMES[_equipped_frame]

func open() -> void:
	_equipped_frame = GameManager.equipped_hat
	_selected_frame = -1
	_preview_icon.texture = null
	_hat_name_label.text = "Select a hat to preview"
	_hat_desc_label.text = ""
	_equip_btn.disabled = true
	_update_currently_label()
	_refresh_highlights()
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_hat_menu"):
		close()
		get_viewport().set_input_as_handled()

func _border_rects(x: int, y: int, w: int, h: int, t: int) -> Array:
	return [
		[Vector2(x, y),             Vector2(w, t)],
		[Vector2(x, y + h - t),     Vector2(w, t)],
		[Vector2(x, y),             Vector2(t, h)],
		[Vector2(x + w - t, y),     Vector2(t, h)],
	]
