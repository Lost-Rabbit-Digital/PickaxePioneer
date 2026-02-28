class_name HatMenu
extends CanvasLayer

# Companion Menu — toggle with H key during a mining run.
# Displays Leaf and Ice elemental followers; each can be independently equipped.
# Selection persists across runs via GameManager.equipped_leaf / equipped_ice.

const PANEL_W: int = 620
const PANEL_H: int = 340

const FOLLOWER_NAMES: Array = ["Leaf Elemental", "Ice Elemental"]
const FOLLOWER_DESCS: Array = [
	"A curious forest sprite that drifts through the mines beside you.",
	"A frosty companion born from deep-mine cold. Cool and determined.",
]
const FOLLOWER_SHEETS: Array = [
	"res://assets/elemental_followers/leaf_elemental_spritesheet.png",
	"res://assets/elemental_followers/ice_elemental_spritesheet.png",
]

# Set by MiningLevel after instantiation
var player: PlayerProbe = null

var _leaf_toggle_btn: Button
var _ice_toggle_btn: Button
var _leaf_card_border: ColorRect
var _ice_card_border: ColorRect

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
	title.text = "COMPANIONS"
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

	# Two follower cards
	var card_w: int = 260
	var card_h: int = 230
	var card_y: int = py + 56
	var gap: int = 20
	var total_cards_w: int = card_w * 2 + gap
	var card_start_x: int = px + (PANEL_W - total_cards_w) / 2

	_build_follower_card(0, card_start_x, card_y, card_w, card_h)
	_build_follower_card(1, card_start_x + card_w + gap, card_y, card_w, card_h)

	# Close button at bottom center
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.position = Vector2(px + (PANEL_W - 90) / 2, py + PANEL_H - 46)
	close_btn.size = Vector2(90, 32)
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.pressed.connect(close)
	add_child(close_btn)

func _build_follower_card(index: int, cx: int, cy: int, w: int, h: int) -> void:
	var is_leaf: bool = (index == 0)

	# Card background
	var card := ColorRect.new()
	card.color = Color(0.13, 0.11, 0.17, 1.0)
	card.position = Vector2(cx, cy)
	card.size = Vector2(w, h)
	add_child(card)

	# Card border (updated on open to show equip state)
	var border := ColorRect.new()
	border.position = Vector2(cx - 1, cy - 1)
	border.size = Vector2(w + 2, h + 2)
	border.z_index = -1
	add_child(border)
	if is_leaf:
		_leaf_card_border = border
	else:
		_ice_card_border = border

	# Preview icon (first idle frame from spritesheet)
	var icon_size: int = 88
	var icon_x: int = cx + (w - icon_size) / 2
	var icon_y: int = cy + 12
	var preview := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(FOLLOWER_SHEETS[index]) as Texture2D
	atlas.region = Rect2(0, 0, 32, 32)
	preview.texture = atlas
	preview.position = Vector2(icon_x, icon_y)
	preview.size = Vector2(icon_size, icon_size)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(preview)

	# Name label
	var name_lbl := Label.new()
	name_lbl.text = FOLLOWER_NAMES[index]
	name_lbl.position = Vector2(cx + 8, cy + icon_size + 18)
	name_lbl.custom_minimum_size = Vector2(w - 16, 24)
	name_lbl.add_theme_font_size_override("font_size", 15)
	name_lbl.modulate = Color(1.0, 0.82, 0.35)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_lbl)

	# Description label
	var desc_lbl := Label.new()
	desc_lbl.text = FOLLOWER_DESCS[index]
	desc_lbl.position = Vector2(cx + 8, cy + icon_size + 44)
	desc_lbl.custom_minimum_size = Vector2(w - 16, 44)
	desc_lbl.add_theme_font_size_override("font_size", 11)
	desc_lbl.modulate = Color(0.70, 0.70, 0.75)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(desc_lbl)

	# Toggle button
	var toggle_btn := Button.new()
	toggle_btn.position = Vector2(cx + (w - 120) / 2, cy + h - 44)
	toggle_btn.size = Vector2(120, 32)
	toggle_btn.add_theme_font_size_override("font_size", 13)
	if is_leaf:
		_leaf_toggle_btn = toggle_btn
		toggle_btn.pressed.connect(_on_toggle_leaf)
	else:
		_ice_toggle_btn = toggle_btn
		toggle_btn.pressed.connect(_on_toggle_ice)
	add_child(toggle_btn)

func _on_toggle_leaf() -> void:
	GameManager.equipped_leaf = not GameManager.equipped_leaf
	GameManager.save_game()
	if player:
		player.update_follower_visibility()
	_refresh_cards()

func _on_toggle_ice() -> void:
	GameManager.equipped_ice = not GameManager.equipped_ice
	GameManager.save_game()
	if player:
		player.update_follower_visibility()
	_refresh_cards()

func _refresh_cards() -> void:
	var equipped_color := Color(0.20, 0.55, 0.20, 0.90)
	var unequipped_color := Color(0.28, 0.24, 0.36, 0.60)

	if GameManager.equipped_leaf:
		_leaf_toggle_btn.text = "UNEQUIP"
		_leaf_card_border.color = equipped_color
	else:
		_leaf_toggle_btn.text = "EQUIP"
		_leaf_card_border.color = unequipped_color

	if GameManager.equipped_ice:
		_ice_toggle_btn.text = "UNEQUIP"
		_ice_card_border.color = equipped_color
	else:
		_ice_toggle_btn.text = "EQUIP"
		_ice_card_border.color = unequipped_color

func open() -> void:
	_refresh_cards()
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
