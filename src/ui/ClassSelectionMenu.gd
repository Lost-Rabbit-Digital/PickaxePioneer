extends CanvasLayer
## Class selection screen shown after choosing a save slot on New Game.
## Displays a horizontal scrollable row of class cards.  Emits [signal class_confirmed]
## with the chosen class id when the player clicks "BEGIN RUN".
## Emits [signal cancelled] when the player clicks "BACK".

signal class_confirmed(class_id: String)
signal cancelled

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
	{
		"id": "scout",
		"name": "Scout",
		"description": "Swift paws, keen eyes.\nStarts with boosted\nmovement speed.",
		"color": Color(0.85, 0.78, 0.20),
		"locked": true,
		"unlock_hint": "Complete a run to unlock.",
	},
	{
		"id": "engineer",
		"name": "Engineer",
		"description": "Built not born.\nStarts with improved\nmining efficiency.",
		"color": Color(0.40, 0.60, 0.72),
		"locked": true,
		"unlock_hint": "Complete a run to unlock.",
	},
	{
		"id": "alchemist",
		"name": "Alchemist",
		"description": "Worth more than weight.\nStarts with bonus\nore sell value.",
		"color": Color(0.72, 0.38, 0.68),
		"locked": true,
		"unlock_hint": "Complete a run to unlock.",
	},
	{
		"id": "sentinel",
		"name": "Sentinel",
		"description": "Standing guard.\nStarts with reinforced\nPelt and slow descent.",
		"color": Color(0.45, 0.55, 0.45),
		"locked": true,
		"unlock_hint": "Complete a run to unlock.",
	},
	{
		"id": "wanderer",
		"name": "Wanderer",
		"description": "Always further down.\nStarts with extended\nWhiskers scan radius.",
		"color": Color(0.78, 0.52, 0.30),
		"locked": true,
		"unlock_hint": "Complete a run to unlock.",
	},
	{
		"id": "phantom",
		"name": "Phantom",
		"description": "Unseen, unstoppable.\nStarts with rare ore\ndetection Claws.",
		"color": Color(0.30, 0.30, 0.48),
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
	# Fullscreen solid background — completely hides anything behind this menu
	# -----------------------------------------------------------------------
	var bg_fill := ColorRect.new()
	bg_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_fill.color = Color(0.07, 0.06, 0.05, 1.0)
	add_child(bg_fill)

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
	# Scroll container — spans full viewport width, horizontally scrollable
	# -----------------------------------------------------------------------
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_TOP_WIDE)
	scroll.offset_top = 90.0
	scroll.offset_bottom = 90.0 + CARD_H + 40.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	# CenterContainer inside scroll so cards are centered when they fit
	# and naturally overflow (scroll) when they don't.
	var center_c := CenterContainer.new()
	center_c.use_top_left = false
	center_c.set_h_size_flags(Control.SIZE_EXPAND_FILL)
	center_c.set_v_size_flags(Control.SIZE_EXPAND_FILL)
	scroll.add_child(center_c)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", int(CARD_GAP))
	hbox.set_v_size_flags(Control.SIZE_SHRINK_CENTER)
	center_c.add_child(hbox)

	for i: int in range(CLASSES.size()):
		var card := _build_card(i, CLASSES[i])
		hbox.add_child(card)

	# -----------------------------------------------------------------------
	# Bottom button row — BACK on left, BEGIN RUN centered
	# -----------------------------------------------------------------------
	var bottom_anchor := Control.new()
	bottom_anchor.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_anchor.offset_top = -90.0
	bottom_anchor.offset_bottom = -30.0
	root.add_child(bottom_anchor)

	# BACK button — left side
	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.custom_minimum_size = Vector2(140.0, 52.0)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	back_btn.offset_left = 48.0
	back_btn.offset_right = 48.0 + 140.0
	back_btn.offset_top = -26.0
	back_btn.offset_bottom = 26.0
	back_btn.pressed.connect(_on_back_pressed)
	bottom_anchor.add_child(back_btn)

	# BEGIN RUN button — centered
	_confirm_btn = Button.new()
	_confirm_btn.text = "BEGIN RUN"
	_confirm_btn.custom_minimum_size = Vector2(220.0, 52.0)
	_confirm_btn.add_theme_font_size_override("font_size", 22)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm_pressed)

	var btn_center := CenterContainer.new()
	btn_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bottom_anchor.add_child(btn_center)
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


func _on_back_pressed() -> void:
	SoundManager.play_ui_close_sound()
	cancelled.emit()
	queue_free()


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
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
