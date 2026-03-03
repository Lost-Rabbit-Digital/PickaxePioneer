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

const MAX_MESSAGES: int = 20
const PANEL_W: int = 310
const LINE_H: int = 18
const VISIBLE_LINES: int = 6
const MSG_AREA_H: int = VISIBLE_LINES * LINE_H   # 108 px
const INPUT_H: int = 28
const PANEL_H: int = MSG_AREA_H + INPUT_H + 12   # 12 px for inner padding

# Viewport dimensions assumed to match the game's fixed 1280×720 resolution.
const VP_H: int = 720

var _messages: Array[String] = []
var _msg_labels: Array[Label] = []
var _panel: ColorRect
var _msg_container: VBoxContainer
var _input_bg: ColorRect
var _input_field: LineEdit
var _hint_label: Label
var _chat_open: bool = false

func _ready() -> void:
	layer = 15  # Above HUD (1), below pause menu (20)
	EventBus.chat_message_received.connect(_on_chat_message_received)
	_build_ui()

func _build_ui() -> void:
	var panel_y: int = VP_H - PANEL_H - 4

	# Semi-transparent background panel
	_panel = ColorRect.new()
	_panel.color = Color(0.0, 0.0, 0.0, 0.55)
	_panel.position = Vector2(4, panel_y)
	_panel.size = Vector2(PANEL_W, PANEL_H)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	# Message log — VISIBLE_LINES fixed Label nodes updated in-place
	_msg_container = VBoxContainer.new()
	_msg_container.position = Vector2(8, panel_y + 4)
	_msg_container.custom_minimum_size = Vector2(PANEL_W - 12, MSG_AREA_H)
	_msg_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_msg_container.add_theme_constant_override("separation", 0)
	add_child(_msg_container)

	for i in range(VISIBLE_LINES):
		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(PANEL_W - 12, LINE_H)
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(1.0, 1.0, 1.0, 0.92)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.clip_text = true
		_msg_container.add_child(lbl)
		_msg_labels.append(lbl)

	# Input row background
	var input_y: int = panel_y + MSG_AREA_H + 8
	_input_bg = ColorRect.new()
	_input_bg.color = Color(0.05, 0.05, 0.10, 0.80)
	_input_bg.position = Vector2(4, input_y)
	_input_bg.size = Vector2(PANEL_W, INPUT_H)
	_input_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_input_bg)

	_input_field = LineEdit.new()
	_input_field.position = Vector2(6, input_y + 2)
	_input_field.custom_minimum_size = Vector2(PANEL_W - 4, INPUT_H - 4)
	_input_field.placeholder_text = "Say something... (Enter to send, Esc to cancel)"
	_input_field.add_theme_font_size_override("font_size", 12)
	_input_field.text_submitted.connect(_on_message_submitted)
	add_child(_input_field)

	# "T to chat" hint — shown when panel is visible but input is closed
	_hint_label = Label.new()
	_hint_label.text = "T — chat"
	_hint_label.position = Vector2(8, input_y + 6)
	_hint_label.add_theme_font_size_override("font_size", 11)
	_hint_label.modulate = Color(0.7, 0.7, 0.7, 0.70)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint_label)

	_set_chat_open(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_T and not _chat_open:
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

func _on_chat_message_received(sender_name: String, message: String) -> void:
	_messages.append("[%s] %s" % [sender_name, message])
	if _messages.size() > MAX_MESSAGES:
		_messages = _messages.slice(_messages.size() - MAX_MESSAGES)
	_refresh_labels()

func _refresh_labels() -> void:
	var start: int = max(0, _messages.size() - VISIBLE_LINES)
	for i in range(VISIBLE_LINES):
		var msg_index: int = start + i
		_msg_labels[i].text = _messages[msg_index] if msg_index < _messages.size() else ""
