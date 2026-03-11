class_name HatMenu
extends CanvasLayer

# Companion Menu — toggle with C key during a mining run.
# Shows all companions in a paginated 3×2 grid (6 per page).
# Leaf/Ice Elementals use real spritesheets; all others use a white placeholder
# until their art is ready.  Equip state persists via GameManager.

const PANEL_W: int = 920
const PANEL_H: int = 560

const COLS: int = 3
const ROWS: int = 2
const CARDS_PER_PAGE: int = COLS * ROWS

# Card geometry — computed from panel dimensions
const CARD_MARGIN_X: int = 20
const CARD_GAP: int = 14
const CARD_AREA_Y_START: int = 58   # Below title + separator
const CARD_AREA_Y_END: int = 56     # Space for pagination bar at bottom

# ---------- companion roster ------------------------------------------------
# Each entry: { id, name, desc, sheet }
# sheet = "" → blank white placeholder icon (stub)
const COMPANIONS: Array = [
	{
		"id": "leaf",
		"name": "Leaf Elemental",
		"desc": "A curious forest sprite that drifts through the mines beside you.",
		"sheet": "res://assets/elemental_followers/leaf_elemental_spritesheet.png",
	},
	{
		"id": "ice",
		"name": "Ice Elemental",
		"desc": "A frosty companion born from deep-mine cold. Cool and determined.",
		"sheet": "res://assets/elemental_followers/ice_elemental_spritesheet.png",
	},
	{
		"id": "baby_observer",
		"name": "Baby Observer",
		"desc": "A tiny floating eye that watches everything with boundless curiosity.",
		"sheet": "",
	},
	{
		"id": "magic_book",
		"name": "Magic Book",
		"desc": "An enchanted tome that levitates faithfully at your side.",
		"sheet": "",
	},
	{
		"id": "bulldog",
		"name": "Bulldog",
		"desc": "A stout and loyal hound who refuses to leave your side.",
		"sheet": "",
	},
	{
		"id": "living_cactus",
		"name": "Living Cactus",
		"desc": "A prickly desert companion with a surprisingly gentle heart.",
		"sheet": "",
	},
	{
		"id": "goblin_carrier",
		"name": "Goblin Carrier",
		"desc": "A resourceful goblin who happily hauls your extra gear.",
		"sheet": "",
	},
	{
		"id": "cherub",
		"name": "Cherub",
		"desc": "A chubby winged cherub who blesses your every mining strike.",
		"sheet": "",
	},
	{
		"id": "dog_chest",
		"name": "Dog-like Chest",
		"desc": "A mysterious chest that trots along on a pair of stubby legs.",
		"sheet": "",
	},
	{
		"id": "magic_cloud",
		"name": "Magic Cloud",
		"desc": "A small storm cloud that crackles with restless arcane energy.",
		"sheet": "",
	},
	{
		"id": "draco",
		"name": "Draco",
		"desc": "A young dragon hatchling brimming with fiery spirit.",
		"sheet": "",
	},
	{
		"id": "doppelganger_egg",
		"name": "Doppelganger Egg",
		"desc": "An eerie egg that subtly mirrors your every movement.",
		"sheet": "",
	},
	{
		"id": "hive_bees",
		"name": "Hive and Bees",
		"desc": "A mobile hive with its loyal swarm buzzing protectively around you.",
		"sheet": "",
	},
	{
		"id": "stubby_lizard",
		"name": "Stubby Lizard",
		"desc": "A short-legged lizard who scrambles valiantly to keep up.",
		"sheet": "",
	},
	{
		"id": "elemental_orbs",
		"name": "Elemental Orbs",
		"desc": "Orbiting spheres of pure elemental energy that hum softly as they circle.",
		"sheet": "",
	},
	{
		"id": "rolling_stone",
		"name": "Rolling Stone",
		"desc": "A sentient boulder that rolls wherever you lead it.",
		"sheet": "",
	},
	{
		"id": "shadow",
		"name": "Shadow",
		"desc": "A detached shadow that follows you silently through the darkness.",
		"sheet": "",
	},
	{
		"id": "flying_skull",
		"name": "Flying Skull",
		"desc": "A cheerful skull that bobs and floats gleefully behind you.",
		"sheet": "",
	},
	{
		"id": "sprite",
		"name": "Sprite",
		"desc": "A shimmering fairy-like creature full of mischief and warmth.",
		"sheet": "",
	},
	{
		"id": "enchanted_sword",
		"name": "Enchanted Sword",
		"desc": "A floating blade bound by ancient magic to protect its chosen companion.",
		"sheet": "",
	},
]
# ----------------------------------------------------------------------------

# Set by MiningLevel after instantiation
var player: PlayerProbe = null

var _page: int = 0
var _page_count: int = 0

# Persistent UI nodes (live for the full scene lifetime)
var _cards_root: Node = null
var _page_label: Label = null
var _prev_btn: Button = null
var _next_btn: Button = null
var _panel_x: int = 0
var _panel_y: int = 0

# Per-page references (rebuilt on every page change)
var _toggle_buttons: Dictionary = {}  # id -> Button
var _card_borders: Dictionary = {}    # id -> ColorRect

# Cached white placeholder texture shared by all stub icons
var _stub_tex: ImageTexture = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_page_count = ceili(float(COMPANIONS.size()) / float(CARDS_PER_PAGE))
	_build_stub_texture()
	_build_ui()


func _build_stub_texture() -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	_stub_tex = ImageTexture.create_from_image(img)


func _build_ui() -> void:
	var vp_w: int = 1280
	var vp_h: int = 720
	_panel_x = (vp_w - PANEL_W) / 2
	_panel_y = (vp_h - PANEL_H) / 2
	var px: int = _panel_x
	var py: int = _panel_y

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
	hint.text = "[C] Close"
	hint.position = Vector2(px + PANEL_W - 110, py + 14)
	hint.add_theme_font_size_override("font_size", 13)
	hint.modulate = Color(0.55, 0.55, 0.65, 0.90)
	add_child(hint)

	# Separator under title
	var sep := ColorRect.new()
	sep.color = Color(0.80, 0.62, 0.22, 0.40)
	sep.position = Vector2(px + 16, py + 44)
	sep.size = Vector2(PANEL_W - 32, 1)
	add_child(sep)

	# Cards container — rebuilt each page
	_cards_root = Node.new()
	add_child(_cards_root)

	# ---- Bottom navigation bar ----
	var nav_y: int = py + PANEL_H - 50

	_prev_btn = Button.new()
	_prev_btn.text = "< PREV"
	_prev_btn.position = Vector2(px + 20, nav_y)
	_prev_btn.size = Vector2(88, 30)
	_prev_btn.add_theme_font_size_override("font_size", 13)
	_prev_btn.pressed.connect(_on_prev_page)
	add_child(_prev_btn)

	_page_label = Label.new()
	_page_label.position = Vector2(px + (PANEL_W - 80) / 2, nav_y + 5)
	_page_label.custom_minimum_size = Vector2(80, 22)
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_size_override("font_size", 13)
	_page_label.modulate = Color(0.70, 0.70, 0.75)
	add_child(_page_label)

	_next_btn = Button.new()
	_next_btn.text = "NEXT >"
	_next_btn.position = Vector2(px + PANEL_W - 108, nav_y)
	_next_btn.size = Vector2(88, 30)
	_next_btn.add_theme_font_size_override("font_size", 13)
	_next_btn.pressed.connect(_on_next_page)
	add_child(_next_btn)

	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.position = Vector2(px + (PANEL_W - 88) / 2, nav_y)
	close_btn.size = Vector2(88, 30)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(close)
	add_child(close_btn)


func _build_page(page: int) -> void:
	# Discard previous page cards
	for child in _cards_root.get_children():
		child.queue_free()
	_toggle_buttons.clear()
	_card_borders.clear()

	var px: int = _panel_x
	var py: int = _panel_y

	var card_area_w: int = PANEL_W - CARD_MARGIN_X * 2
	var card_w: int = (card_area_w - CARD_GAP * (COLS - 1)) / COLS
	var available_h: int = PANEL_H - CARD_AREA_Y_START - CARD_AREA_Y_END
	var card_h: int = (available_h - CARD_GAP * (ROWS - 1)) / ROWS

	var area_x: int = px + CARD_MARGIN_X
	var area_y: int = py + CARD_AREA_Y_START

	var start_idx: int = page * CARDS_PER_PAGE
	var end_idx: int = mini(start_idx + CARDS_PER_PAGE, COMPANIONS.size())

	for i: int in range(start_idx, end_idx):
		var slot: int = i - start_idx
		var col: int = slot % COLS
		var row: int = slot / COLS
		var cx: int = area_x + col * (card_w + CARD_GAP)
		var cy: int = area_y + row * (card_h + CARD_GAP)
		_build_companion_card(COMPANIONS[i], cx, cy, card_w, card_h)

	_page_label.text = "%d / %d" % [page + 1, _page_count]
	_prev_btn.disabled = (page == 0)
	_next_btn.disabled = (page >= _page_count - 1)


func _build_companion_card(data: Dictionary, cx: int, cy: int, w: int, h: int) -> void:
	var id: String = data["id"]
	var has_sheet: bool = data["sheet"] != ""

	# Card background
	var card := ColorRect.new()
	card.color = Color(0.13, 0.11, 0.17, 1.0)
	card.position = Vector2(cx, cy)
	card.size = Vector2(w, h)
	_cards_root.add_child(card)

	# Card border (colour reflects equip state)
	var border := ColorRect.new()
	border.position = Vector2(cx - 1, cy - 1)
	border.size = Vector2(w + 2, h + 2)
	border.z_index = -1
	_cards_root.add_child(border)
	_card_borders[id] = border

	# Preview icon
	const ICON_SIZE: int = 64
	var icon_x: int = cx + (w - ICON_SIZE) / 2
	var icon_y: int = cy + 10
	var preview := TextureRect.new()
	preview.position = Vector2(icon_x, icon_y)
	preview.size = Vector2(ICON_SIZE, ICON_SIZE)
	preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if has_sheet:
		var atlas := AtlasTexture.new()
		atlas.atlas = load(data["sheet"]) as Texture2D
		atlas.region = Rect2(0, 0, 32, 32)
		preview.texture = atlas
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	else:
		preview.texture = _stub_tex
		preview.modulate = Color(1.0, 1.0, 1.0, 0.55)
	_cards_root.add_child(preview)

	# Name
	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.position = Vector2(cx + 4, cy + ICON_SIZE + 14)
	name_lbl.custom_minimum_size = Vector2(w - 8, 20)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.modulate = Color(1.0, 0.82, 0.35)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	_cards_root.add_child(name_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = data["desc"]
	desc_lbl.position = Vector2(cx + 4, cy + ICON_SIZE + 36)
	desc_lbl.custom_minimum_size = Vector2(w - 8, 46)
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.modulate = Color(0.70, 0.70, 0.75)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cards_root.add_child(desc_lbl)

	# Toggle button
	var toggle_btn := Button.new()
	toggle_btn.position = Vector2(cx + (w - 100) / 2, cy + h - 36)
	toggle_btn.size = Vector2(100, 28)
	toggle_btn.add_theme_font_size_override("font_size", 12)
	toggle_btn.pressed.connect(_on_toggle_companion.bind(id))
	_cards_root.add_child(toggle_btn)
	_toggle_buttons[id] = toggle_btn

	_refresh_card(id)


# ---- equip state helpers ---------------------------------------------------

func _is_equipped(id: String) -> bool:
	match id:
		"leaf": return GameManager.equipped_leaf
		"ice":  return GameManager.equipped_ice
		_:      return GameManager.equipped_companions.get(id, false)


func _set_equipped(id: String, val: bool) -> void:
	match id:
		"leaf": GameManager.equipped_leaf = val
		"ice":  GameManager.equipped_ice  = val
		_:      GameManager.equipped_companions[id] = val


# ---- callbacks -------------------------------------------------------------

func _on_toggle_companion(id: String) -> void:
	_set_equipped(id, not _is_equipped(id))
	GameManager.save_game()
	if player and (id == "leaf" or id == "ice"):
		player.update_follower_visibility()
	_refresh_card(id)


func _on_prev_page() -> void:
	_page = maxi(0, _page - 1)
	_build_page(_page)


func _on_next_page() -> void:
	_page = mini(_page_count - 1, _page + 1)
	_build_page(_page)


# ---- card refresh ----------------------------------------------------------

func _refresh_card(id: String) -> void:
	if not _toggle_buttons.has(id):
		return
	var equipped: bool = _is_equipped(id)
	_toggle_buttons[id].text = "UNEQUIP" if equipped else "EQUIP"
	_card_borders[id].color = (
		Color(0.20, 0.55, 0.20, 0.90) if equipped
		else Color(0.28, 0.24, 0.36, 0.60)
	)


func _refresh_cards() -> void:
	for id: String in _toggle_buttons.keys():
		_refresh_card(id)


# ---- open / close ----------------------------------------------------------

func open() -> void:
	_build_page(_page)
	show()
	get_tree().paused = true


func close() -> void:
	hide()
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_companions_menu"):
		close()
		get_viewport().set_input_as_handled()


# ---- utility ---------------------------------------------------------------

func _border_rects(x: int, y: int, w: int, h: int, t: int) -> Array:
	return [
		[Vector2(x, y),         Vector2(w, t)],
		[Vector2(x, y + h - t), Vector2(w, t)],
		[Vector2(x, y),         Vector2(t, h)],
		[Vector2(x + w - t, y), Vector2(t, h)],
	]
