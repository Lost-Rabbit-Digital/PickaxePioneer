class_name NetworkDebugOverlay
extends CanvasLayer

## Lightweight network debug overlay toggled with F3 during multiplayer sessions.
## Shows peer ID, RTT, connection state, and heartbeat status in the top-right corner.

var _label: RichTextLabel
var _visible: bool = false

func _ready() -> void:
	layer = 100
	_build_ui()
	_label.visible = false

func _build_ui() -> void:
	_label = RichTextLabel.new()
	_label.bbcode_enabled = true
	_label.fit_content = true
	_label.scroll_active = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_label.position = Vector2(-320, 8)
	_label.size = Vector2(310, 200)
	_label.add_theme_font_size_override("normal_font_size", 14)
	_label.add_theme_font_size_override("bold_font_size", 14)
	add_child(_label)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		if (event as InputEventKey).keycode == KEY_F3:
			_visible = not _visible
			_label.visible = _visible
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _visible:
		return
	_label.text = _build_text()

func _build_text() -> String:
	var lines: Array[String] = []
	lines.append("[b]Network Debug[/b]")

	if not NetworkManager.is_multiplayer_session:
		lines.append("[color=#888888]No active session[/color]")
		_label.text = "\n".join(lines)
		return "\n".join(lines)

	# Role & peer ID
	var role := "HOST" if NetworkManager.is_host else "GUEST"
	var pid := multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else -1
	lines.append("Role: [b]%s[/b]  Peer ID: %d" % [role, pid])

	# Remote peer
	if NetworkManager.is_host:
		if NetworkManager.guest_peer_id > 0:
			var name := NetworkManager.get_remote_display_name()
			lines.append("Guest: [b]%s[/b] (peer %d)" % [name, NetworkManager.guest_peer_id])
		else:
			lines.append("Guest: [color=#888888]waiting...[/color]")
	else:
		var name := NetworkManager.get_remote_display_name()
		lines.append("Host: [b]%s[/b] (peer 1)" % name)

	# RTT
	var rtt := NetworkManager.rtt_ms
	var rtt_color := "00ff00"
	if rtt > 100.0:
		rtt_color = "ff4444"
	elif rtt > 50.0:
		rtt_color = "ffaa00"
	elif rtt > 20.0:
		rtt_color = "ffff00"
	lines.append("RTT: [color=#%s]%.1f ms[/color]" % [rtt_color, rtt])

	# Stall status
	if NetworkManager._peer_stalled:
		lines.append("[color=#ff4444][b]PEER STALLED[/b][/color]")
	else:
		lines.append("Heartbeat: [color=#00ff00]OK[/color]")

	# Port
	lines.append("Port: %d" % NetworkManager.DEFAULT_PORT)

	# Local player name
	lines.append("Name: %s" % NetworkManager.get_display_name())

	return "\n".join(lines)
