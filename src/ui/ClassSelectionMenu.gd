extends CanvasLayer
## Class selection screen shown after choosing a save slot on New Game.
## Displays a horizontal row of class cards.  Emits [signal class_confirmed]
## with the chosen class id when the player clicks "BEGIN RUN".

signal class_confirmed(class_id: String)

## Placeholder class definitions — replace colors / descriptions with real art later.
const CLASSES: Array[Dictionary] = [
	{
		"id": "pioneer",
		"name": "Pioneer",
		"description": "The reliable all-rounder.\nA balanced start for any\nmining expedition.",
		"color": Color(0.35, 0.55, 0.85),
		"locked": false,
		"unlock_hint": "",
	},
	{
		"id": "prospector",
		"name": "Prospector",
		"description": "Nose for riches.\nStarts with enhanced\nWhiskers sonar range.",
		"color": Color(0.25, 0.70, 0.45),
		"locked": false,
		"unlock_hint": "",
	},
	{
		"id": "brawler",
		"name": "Brawler",
		"description": "Sharpened claws,\ntougher hide.  Starts\nwith boosted excavation.",
		"color": Color(0.80, 0.40, 0.25),
		"locked": false,
		"unlock_hint": "",
	},
	{
		"id": "veteran",
		"name": "Veteran",
		"description": "Weathered, wise, ready.\nStarts with extra\nPelt durability.",
		"color": Color(0.65, 0.50, 0.78),
		"locked": true,
		"unlock_hint": "Complete a run to unlock.",
	},
]

const CARD_W: float = 240.0
const CARD_H: float = 370.0
const CARD_IMG_H: float = 160.0
const CARD_GAP: float = 24.0

# Accent colour used for selected card border and title
const ACCENT_COLOR: Color = Color(0.90, 0.70, 0.28)

var _selected_index: int = -1
var _confirm_btn: Button = null
## Parallel array of border ColorRects, one per card (in CLASSES order).
var _card_borders: Array[ColorRect] = []


func _ready() -> void:
	layer = 10
	_build_ui()


func _build_ui() -> void:
	# -----------------------------------------------------------------------
	# Fullscreen dimmer
	# -----------------------------------------------------------------------
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.0, 0.0, 0.0, 0.88)
	add_child(dimmer)

	# -----------------------------------------------------------------------
	# Root control layer
	# -----------------------------------------------------------------------
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	# -----------------------------------------------------------------------
	# Title
	# -----------------------------------------------------------------------
	var title := Label.new()
	title.text = "CHOOSE YOUR CLASS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 32.0
	title.offset_bottom = 72.0
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	root.add_child(title)

	# -----------------------------------------------------------------------
	# Scroll container — spans full viewport width
	# -----------------------------------------------------------------------
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_top = 90.0
	scroll.offset_bottom = 90.0 + CARD_H + 40.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	# MarginContainer inside scroll provides a centering left/right margin.
	var total_cards_w: float = CLASSES.size() * CARD_W + (CLASSES.size() - 1) * CARD_GAP
	var viewport_w: float = 1280.0
	var side_margin: int = max(0, int((viewport_w - total_cards_w) / 2.0))

	var margin_c := MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", side_margin)
	margin_c.add_theme_constant_override("margin_right", side_margin)
	margin_c.add_theme_constant_override("margin_top", 10)
	margin_c.add_theme_constant_override("margin_bottom", 10)
	scroll.add_child(margin_c)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(CARD_GAP))
	margin_c.add_child(hbox)

	for i: int in range(CLASSES.size()):
		var card := _build_card(i, CLASSES[i])
		hbox.add_child(card)

	# -----------------------------------------------------------------------
	# "BEGIN RUN" confirm button
	# -----------------------------------------------------------------------
	_confirm_btn = Button.new()
	_confirm_btn.text = "BEGIN RUN"
	_confirm_btn.custom_minimum_size = Vector2(220.0, 52.0)
	_confirm_btn.add_theme_font_size_override("font_size", 22)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm_pressed)

	var btn_anchor := Control.new()
	btn_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	btn_anchor.offset_top = -90.0
	btn_anchor.offset_bottom = -30.0
	root.add_child(btn_anchor)

	var btn_center := CenterContainer.new()
	btn_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_anchor.add_child(btn_center)
	btn_center.add_child(_confirm_btn)


func _build_card(index: int, data: Dictionary) -> Control:
	# Runtime check: unlock if global progress qualifies
	var locked: bool = data["locked"]
	if locked and GameManager.global_player_level >= 2:
		locked = false

	# -----------------------------------------------------------------------
	# Outer wrapper — gives the card a fixed size for HBoxContainer layout
	# -----------------------------------------------------------------------
	var wrapper := Control.new()
	wrapper.custom_minimum_size = Vector2(CARD_W, CARD_H)

	# Selection border (drawn behind background)
	var border := ColorRect.new()
	border.color = Color(0.0, 0.0, 0.0, 0.0)
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.offset_left = -4.0
	border.offset_top = -4.0
	border.offset_right = 4.0
	border.offset_bottom = 4.0
	wrapper.add_child(border)
	_card_borders.append(border)

	# Card background
	var bg := ColorRect.new()
	bg.color = Color(0.11, 0.09, 0.08, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wrapper.add_child(bg)

	# -----------------------------------------------------------------------
	# Image area (placeholder coloured rect — swap in Texture2D / Sprite later)
	# -----------------------------------------------------------------------
	var img_color: Color = data["color"] if not locked else Color(0.28, 0.28, 0.28)
	var img := ColorRect.new()
	img.color = img_color
	img.position = Vector2(0.0, 0.0)
	img.size = Vector2(CARD_W, CARD_IMG_H)
	wrapper.add_child(img)

	# -----------------------------------------------------------------------
	# Class name label
	# -----------------------------------------------------------------------
	var name_lbl := Label.new()
	name_lbl.text = data["name"]
	name_lbl.position = Vector2(10.0, CARD_IMG_H + 12.0)
	name_lbl.size = Vector2(CARD_W - 20.0, 28.0)
	name_lbl.add_theme_font_size_override("font_size", 20)
	var name_color: Color = Color(0.92, 0.86, 0.74) if not locked else Color(0.48, 0.48, 0.48)
	name_lbl.add_theme_color_override("font_color", name_color)
	wrapper.add_child(name_lbl)

	# -----------------------------------------------------------------------
	# Separator line
	# -----------------------------------------------------------------------
	var sep := ColorRect.new()
	sep.position = Vector2(10.0, CARD_IMG_H + 44.0)
	sep.size = Vector2(CARD_W - 20.0, 1.0)
	sep.color = Color(0.35, 0.30, 0.25, 0.6) if not locked else Color(0.30, 0.30, 0.30, 0.4)
	wrapper.add_child(sep)

	# -----------------------------------------------------------------------
	# Description label
	# -----------------------------------------------------------------------
	var desc_lbl := Label.new()
	desc_lbl.position = Vector2(10.0, CARD_IMG_H + 52.0)
	desc_lbl.size = Vector2(CARD_W - 20.0, CARD_H - CARD_IMG_H - 62.0)
	desc_lbl.add_theme_font_size_override("font_size", 14)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	if locked:
		desc_lbl.text = "To unlock:\n" + data["unlock_hint"]
		desc_lbl.add_theme_color_override("font_color", Color(0.62, 0.50, 0.50))
	else:
		desc_lbl.text = data["description"]
		desc_lbl.add_theme_color_override("font_color", Color(0.78, 0.76, 0.70))
	wrapper.add_child(desc_lbl)

	# -----------------------------------------------------------------------
	# Lock overlay
	# -----------------------------------------------------------------------
	if locked:
		var lock_dim := ColorRect.new()
		lock_dim.color = Color(0.0, 0.0, 0.0, 0.52)
		lock_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wrapper.add_child(lock_dim)

		var lock_lbl := Label.new()
		lock_lbl.text = "LOCKED"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.position = Vector2(0.0, CARD_IMG_H / 2.0 - 14.0)
		lock_lbl.size = Vector2(CARD_W, 28.0)
		lock_lbl.add_theme_font_size_override("font_size", 18)
		lock_lbl.add_theme_color_override("font_color", Color(0.90, 0.38, 0.38))
		wrapper.add_child(lock_lbl)
	else:
		# -----------------------------------------------------------------------
		# Invisible click / hover button layered on top of card contents
		# -----------------------------------------------------------------------
		var click_btn := Button.new()
		click_btn.flat = true
		click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		click_btn.self_modulate = Color(1.0, 1.0, 1.0, 0.0)
		click_btn.pressed.connect(func() -> void: _on_card_clicked(index))
		click_btn.mouse_entered.connect(func() -> void: _on_card_hover(index, true))
		click_btn.mouse_exited.connect(func() -> void: _on_card_hover(index, false))
		wrapper.add_child(click_btn)

	return wrapper


func _on_card_clicked(index: int) -> void:
	_selected_index = index
	_confirm_btn.disabled = false
	_update_selection_visuals()
	SoundManager.play_ui_click_sound()


func _on_card_hover(index: int, entered: bool) -> void:
	if index == _selected_index:
		return
	_card_borders[index].color = Color(0.60, 0.50, 0.28, 0.55) if entered else Color(0.0, 0.0, 0.0, 0.0)


func _update_selection_visuals() -> void:
	for i: int in range(_card_borders.size()):
		_card_borders[i].color = ACCENT_COLOR if i == _selected_index else Color(0.0, 0.0, 0.0, 0.0)


func _on_confirm_pressed() -> void:
	if _selected_index < 0:
		return
	GameManager.player_class = CLASSES[_selected_index]["id"]
	SoundManager.play_ui_click_sound()
	class_confirmed.emit(GameManager.player_class)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _selected_index >= 0:
		_on_confirm_pressed()
