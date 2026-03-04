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
## Edit the layout visually in src/ui/ChatBox.tscn — changes propagate to
## every scene automatically.

const MAX_MESSAGES: int = 20
const VISIBLE_LINES: int = 6

## Path to the plain-text word list used for chat filtering.
## One word per line; lines starting with # are treated as comments.
## Set to "" to disable filtering.
@export var filter_file: String = "res://assets/chat_filter.txt"

var _messages: Array[String] = []
var _msg_labels: Array[Label] = []
var _chat_open: bool = false
var _text_filter: TextFilter = TextFilter.new()

@onready var _panel: ColorRect = $Control/Panel
@onready var _msg_container: VBoxContainer = $Control/MsgContainer
@onready var _input_bg: ColorRect = $Control/InputBg
@onready var _input_field: LineEdit = $Control/InputField
@onready var _hint_label: Label = $Control/HintLabel

func _ready() -> void:
	if filter_file.length() > 0:
		_text_filter.load_from_file(filter_file)
	EventBus.chat_message_received.connect(_on_chat_message_received)

	# Collect the fixed Label nodes from the scene in order.
	for child in _msg_container.get_children():
		if child is Label:
			_msg_labels.append(child as Label)

	# Update hint text to match the current key binding.
	var chat_events := InputMap.action_get_events("toggle_chat")
	var chat_key := "T"
	if chat_events.size() > 0 and chat_events[0] is InputEventKey:
		chat_key = OS.get_keycode_string((chat_events[0] as InputEventKey).keycode)
	_hint_label.text = "%s — chat" % chat_key

	_input_field.text_submitted.connect(_on_message_submitted)
	_set_chat_open(false)

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

func _on_chat_message_received(sender_name: String, message: String) -> void:
	var clean := _text_filter.filter(message)
	_messages.append("[%s] %s" % [sender_name, clean])
	if _messages.size() > MAX_MESSAGES:
		_messages = _messages.slice(_messages.size() - MAX_MESSAGES)
	_refresh_labels()

func _refresh_labels() -> void:
	var start: int = max(0, _messages.size() - VISIBLE_LINES)
	for i in range(VISIBLE_LINES):
		var msg_index: int = start + i
		_msg_labels[i].text = _messages[msg_index] if msg_index < _messages.size() else ""
