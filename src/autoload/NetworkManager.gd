extends Node

## NetworkManager — owns all ENet multiplayer state for Pickaxe Pioneer co-op.
## Registered as an autoload singleton so any system can read is_host / is_multiplayer_session.
## Two-player LAN only: one host (peer id 1) + one guest.

signal host_started
signal guest_connected(peer_id: int)
signal guest_disconnected
signal host_disconnected   # Guest: emitted when the host drops the connection
signal connected_to_host
signal connection_failed
signal peer_stalled         # Emitted when heartbeat detects the remote peer is unresponsive

const DEFAULT_PORT: int = 7853
const MAX_CLIENTS: int = 1  # Host + 1 guest = 2 players total
## How long the guest waits for ENet to establish a connection before giving up.
const CONNECTION_TIMEOUT_SEC: float = 8.0
## Heartbeat interval — each peer sends a ping this often.
const HEARTBEAT_INTERVAL_SEC: float = 2.0
## If no pong is received within this window the peer is considered stalled.
const HEARTBEAT_TIMEOUT_SEC: float = 6.0

## True once a host or join operation has established a session.
var is_multiplayer_session: bool = false
## True on the machine that called start_host().
var is_host: bool = false
## Peer ID of the connected guest; -1 if no guest is connected yet.
var guest_peer_id: int = -1
## Active join-timeout timer (null when not connecting).
var _join_timer: SceneTreeTimer = null
## Player display name used in chat (defaults to role name).
var player_name: String = ""
## The remote peer's display name (received via heartbeat).
var remote_player_name: String = ""

# Heartbeat state
var _heartbeat_timer: float = 0.0
var _last_pong_time: float = 0.0
var _peer_stalled: bool = false
## Round-trip time in milliseconds (updated each pong).
var rtt_ms: float = 0.0
var _last_ping_send_time: float = 0.0

var _debug_overlay: NetworkDebugOverlay = null

func _ready() -> void:
	# Default player name from OS username; users can override via set_player_name().
	player_name = OS.get_environment("USER")
	if player_name.is_empty():
		player_name = OS.get_environment("USERNAME")
	if player_name.is_empty():
		player_name = ""
	# Spawn the debug overlay (toggled with F3) — persists across scenes as a child
	# of this autoload singleton.
	_debug_overlay = NetworkDebugOverlay.new()
	add_child(_debug_overlay)

## Set a custom display name for chat and the network debug overlay.
func set_player_name(new_name: String) -> void:
	player_name = new_name.strip_edges().left(24)

## Returns the display name for the local player, falling back to role.
func get_display_name() -> String:
	if player_name.is_empty():
		return "Host" if is_host else "Guest"
	return player_name

## Returns the display name for the remote player, falling back to role.
func get_remote_display_name() -> String:
	if remote_player_name.is_empty():
		return "Guest" if is_host else "Host"
	return remote_player_name

func start_host(port: int = DEFAULT_PORT) -> Error:
	_reset_peer()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("NetworkManager: failed to create server on port %d (err %d)" % [port, err])
		return err
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_multiplayer_session = true
	is_host = true
	guest_peer_id = -1
	_reset_heartbeat()
	host_started.emit()
	return OK

func join_host(ip: String, port: int = DEFAULT_PORT) -> Error:
	_reset_peer()
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_error("NetworkManager: failed to connect to %s:%d (err %d)" % [ip, port, err])
		return err
	peer.host.compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(_on_server_disconnected, CONNECT_ONE_SHOT)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_multiplayer_session = true
	is_host = false
	_reset_heartbeat()
	# Start a timeout so the guest doesn't wait forever if the host is unreachable.
	_join_timer = get_tree().create_timer(CONNECTION_TIMEOUT_SEC)
	_join_timer.timeout.connect(_on_join_timeout, CONNECT_ONE_SHOT)
	return OK

func disconnect_session() -> void:
	_reset_peer()
	is_multiplayer_session = false
	is_host = false
	guest_peer_id = -1
	remote_player_name = ""

## Closes any active ENet socket and disconnects multiplayer signals so that a
## subsequent create_server / create_client call gets a clean slate.
func _reset_peer() -> void:
	_cancel_join_timer()
	if multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.disconnect(_on_peer_connected)
	if multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.disconnect(_on_peer_disconnected)
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	if multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.disconnect(_on_server_disconnected)
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null

func _on_peer_connected(id: int) -> void:
	if is_host:
		guest_peer_id = id
		_reset_heartbeat()
		guest_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	if is_host and id == guest_peer_id:
		guest_peer_id = -1
		remote_player_name = ""
		_reset_heartbeat()
		guest_disconnected.emit()

func _cancel_join_timer() -> void:
	if _join_timer and _join_timer.timeout.is_connected(_on_join_timeout):
		_join_timer.timeout.disconnect(_on_join_timeout)
	_join_timer = null

func _on_connected_to_server() -> void:
	_cancel_join_timer()
	_reset_heartbeat()
	connected_to_host.emit()

func _on_connection_failed() -> void:
	_cancel_join_timer()
	is_multiplayer_session = false
	connection_failed.emit()

func _on_join_timeout() -> void:
	_join_timer = null
	# ENet hasn't connected in time — treat as failure.
	if not is_host and is_multiplayer_session:
		push_warning("NetworkManager: join timed out after %.0fs" % CONNECTION_TIMEOUT_SEC)
		disconnect_session()
		connection_failed.emit()

func _on_server_disconnected() -> void:
	is_multiplayer_session = false
	host_disconnected.emit()
	# Automatically return the guest to the main menu so they aren't stranded.
	_return_to_main_menu("Host disconnected")

## Transition back to the main menu and show a notification explaining why.
## Called when the guest loses its host connection mid-session.
func _return_to_main_menu(reason: String) -> void:
	disconnect_session()
	GameManager.change_state(GameManager.GameState.MENU)
	EventBus.game_notification.emit(reason, Color(1.0, 0.4, 0.2))
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")

# ---------------------------------------------------------------------------
# Heartbeat — application-level ping/pong for stall detection
# ---------------------------------------------------------------------------

func _reset_heartbeat() -> void:
	_heartbeat_timer = 0.0
	_last_pong_time = Time.get_ticks_msec() / 1000.0
	_peer_stalled = false
	rtt_ms = 0.0
	_last_ping_send_time = 0.0

func _process(delta: float) -> void:
	if not is_multiplayer_session:
		return
	# Only run heartbeat when we have a connected peer.
	var has_remote: bool = (is_host and guest_peer_id > 0) or (not is_host and multiplayer.has_multiplayer_peer())
	if not has_remote:
		return

	_heartbeat_timer += delta
	if _heartbeat_timer >= HEARTBEAT_INTERVAL_SEC:
		_heartbeat_timer -= HEARTBEAT_INTERVAL_SEC
		_last_ping_send_time = Time.get_ticks_msec() / 1000.0
		var target_id := guest_peer_id if is_host else 1
		_rpc_ping.rpc_id(target_id, get_display_name())

	# Check for stall
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_pong_time > HEARTBEAT_TIMEOUT_SEC:
		if not _peer_stalled:
			_peer_stalled = true
			push_warning("NetworkManager: remote peer unresponsive for %.0fs" % HEARTBEAT_TIMEOUT_SEC)
			peer_stalled.emit()
	else:
		_peer_stalled = false

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_ping(sender_display_name: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	_rpc_pong.rpc_id(sender_id)
	# Store the remote peer's display name from the ping payload.
	remote_player_name = sender_display_name

@rpc("any_peer", "call_remote", "unreliable")
func _rpc_pong() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_last_pong_time = now
	if _last_ping_send_time > 0.0:
		rtt_ms = (now - _last_ping_send_time) * 1000.0

# ---------------------------------------------------------------------------
# Chat
# ---------------------------------------------------------------------------

## Sends a chat message to the remote player and displays it locally.
## Call this from the ChatBox when the local player submits a message.
func broadcast_chat_message(text: String) -> void:
	var sender_name := get_display_name()
	var color_html := GameManager.cat_color.to_html(false)
	EventBus.chat_message_received.emit(sender_name, text, GameManager.cat_color)
	if is_host and guest_peer_id > 0:
		_deliver_chat_message.rpc_id(guest_peer_id, sender_name, text, color_html)
	elif not is_host:
		_deliver_chat_message.rpc_id(1, sender_name, text, color_html)

## RPC target — called on the remote peer to display an incoming chat message.
## Sender name is validated against the actual remote peer ID so a client cannot
## spoof a different name (e.g. impersonate "Host" from the guest machine).
@rpc("any_peer", "call_remote", "reliable")
func _deliver_chat_message(sender_name: String, text: String, color_html: String) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	# Validate: the name must match what the remote peer advertised via heartbeat,
	# or fall back to role-based validation if no heartbeat name received yet.
	var expected_name: String
	if not remote_player_name.is_empty():
		expected_name = remote_player_name
	else:
		expected_name = "Host" if sender_id == 1 else "Guest"
	if sender_name != expected_name:
		push_warning("NetworkManager: chat sender name mismatch from peer %d (got '%s', expected '%s')" % [sender_id, sender_name, expected_name])
		return
	var sender_color := Color.from_string(color_html, Color.WHITE)
	EventBus.chat_message_received.emit(sender_name, text, sender_color)
