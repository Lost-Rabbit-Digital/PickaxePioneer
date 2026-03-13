class_name ChatBox
extends CanvasLayer

## Multiplayer chat panel — bottom-left corner of the screen.
## Instantiated by Overworld, SettlementLevel, and MiningLevel when a
## multiplayer session is active. Press T to open the text input; Enter
## sends the message; Escape cancels without sending.
##
## Messages are broadcast via NetworkManager.broadcast_chat_message() which
## uses an RPC to deliver them to the remote peer, then each peer displays
## them locally by listening to EventBus.chat_message_received.
##
## Chat history is preserved across level transitions via a static variable.
## The message area supports mouse-wheel scrolling to view older messages.
##
## Edit the layout visually in src/ui/ChatBox.tscn — changes propagate to
## every scene automatically.

const MAX_MESSAGES: int = 100

## Persists across level transitions for the duration of the session.
static var _history: Array[String] = []

## Path to the plain-text word list used for chat filtering.
## One word per line; lines starting with # are treated as comments.
## Set to "" to disable filtering.
@export var filter_file: String = "res://assets/chat_filter.txt"

var _chat_open: bool = false
var _at_bottom: bool = true
var _text_filter: TextFilter = TextFilter.new()

@onready var _panel: ColorRect = $Control/Panel
@onready var _scroll: ScrollContainer = $Control/ScrollContainer
@onready var _msg_container: VBoxContainer = $Control/ScrollContainer/MsgContainer
@onready var _input_bg: ColorRect = $Control/InputBg
@onready var _input_field: LineEdit = $Control/InputField
@onready var _hint_label: Label = $Control/HintLabel

func _ready() -> void:
	if filter_file.length() > 0:
		_text_filter.load_from_file(filter_file)
	EventBus.chat_message_received.connect(_on_chat_message_received)
	EventBus.game_notification.connect(_on_game_notification)

	# Restore history from previous levels in this session.
	for msg in _history:
		_add_label(msg)

	# Update hint text to match the current key binding.
	var chat_events := InputMap.action_get_events("toggle_chat")
	var chat_key := "T"
	if chat_events.size() > 0 and chat_events[0] is InputEventKey:
		chat_key = OS.get_keycode_string((chat_events[0] as InputEventKey).keycode)
	_hint_label.text = "%s — chat" % chat_key

	_input_field.text_submitted.connect(_on_message_submitted)
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	_set_chat_open(false)

	# Wait one frame for layout to settle before scrolling to the bottom.
	await get_tree().process_frame
	_scroll_to_bottom()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.is_action("toggle_chat") and not _chat_open:
		_set_chat_open(true)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and _chat_open:
		_set_chat_open(false)
		get_viewport().set_input_as_handled()

func _set_chat_open(open: bool) -> void:
	_chat_open = open
	_input_bg.visible = open
	_input_field.visible = open
	_hint_label.visible = not open
	if open:
		_input_field.clear()
		_input_field.grab_focus()

func _on_message_submitted(text: String) -> void:
	var trimmed := text.strip_edges()
	if trimmed.length() > 0:
		NetworkManager.broadcast_chat_message(trimmed)
	_set_chat_open(false)

func _on_chat_message_received(sender_name: String, message: String, sender_color: Color) -> void:
	var clean := _text_filter.filter(message)
	var color_hex := sender_color.to_html(false)
	var bbcode := "[color=#%s][%s][/color] %s" % [color_hex, sender_name, clean]
	_history.append(bbcode)
	if _history.size() > MAX_MESSAGES:
		_history = _history.slice(_history.size() - MAX_MESSAGES)
		var oldest := _msg_container.get_child(0)
		if oldest:
			oldest.queue_free()
	_add_label(bbcode)
	if _at_bottom:
		await get_tree().process_frame
		_scroll_to_bottom()

func _on_game_notification(message: String, color: Color) -> void:
	var color_hex := color.to_html(false)
	var bbcode := "[color=#%s][i]%s[/i][/color]" % [color_hex, message]
	_history.append(bbcode)
	if _history.size() > MAX_MESSAGES:
		_history = _history.slice(_history.size() - MAX_MESSAGES)
		var oldest := _msg_container.get_child(0)
		if oldest:
			oldest.queue_free()
	_add_label(bbcode)
	if _at_bottom:
		await get_tree().process_frame
		_scroll_to_bottom()

func _add_label(bbcode: String) -> void:
	var lbl := RichTextLabel.new()
	lbl.bbcode_enabled = true
	lbl.text = bbcode
	lbl.fit_content = true
	lbl.scroll_active = false
	lbl.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	lbl.size_flags_horizontal = Control.SIZE_FILL
	lbl.modulate = Color(1.0, 1.0, 1.0, 0.92)
	lbl.add_theme_font_size_override("normal_font_size", 12)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_container.add_child(lbl)

func _scroll_to_bottom() -> void:
	_scroll.scroll_vertical = _scroll.get_v_scroll_bar().max_value

func _on_scroll_changed(value: float) -> void:
	var sb := _scroll.get_v_scroll_bar()
	_at_bottom = value >= sb.max_value - sb.page - 1.0
