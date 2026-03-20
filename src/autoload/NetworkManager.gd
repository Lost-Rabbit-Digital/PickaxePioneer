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

const DEFAULT_PORT: int = 25565
const MAX_CLIENTS: int = 1  # Host + 1 guest = 2 players total
## How long the guest waits for ENet to establish a connection before giving up.
const CONNECTION_TIMEOUT_SEC: float = 8.0

## True once a host or join operation has established a session.
var is_multiplayer_session: bool = false
## True on the machine that called start_host().
var is_host: bool = false
## Peer ID of the connected guest; -1 if no guest is connected yet.
var guest_peer_id: int = -1
## Active join-timeout timer (null when not connecting).
var _join_timer: SceneTreeTimer = null

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
	# Start a timeout so the guest doesn't wait forever if the host is unreachable.
	_join_timer = get_tree().create_timer(CONNECTION_TIMEOUT_SEC)
	_join_timer.timeout.connect(_on_join_timeout, CONNECT_ONE_SHOT)
	return OK

func disconnect_session() -> void:
	_reset_peer()
	is_multiplayer_session = false
	is_host = false
	guest_peer_id = -1

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
		guest_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	if is_host and id == guest_peer_id:
		guest_peer_id = -1
		guest_disconnected.emit()

func _cancel_join_timer() -> void:
	if _join_timer and _join_timer.timeout.is_connected(_on_join_timeout):
		_join_timer.timeout.disconnect(_on_join_timeout)
	_join_timer = null

func _on_connected_to_server() -> void:
	_cancel_join_timer()
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

## Sends a chat message to the remote player and displays it locally.
## Call this from the ChatBox when the local player submits a message.
func broadcast_chat_message(text: String) -> void:
	var sender_name := "Host" if is_host else "Guest"
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
	var expected_name := "Host" if sender_id == 1 else "Guest"
	if sender_name != expected_name:
		push_warning("NetworkManager: chat sender name mismatch from peer %d (got '%s')" % [sender_id, sender_name])
		return
	var sender_color := Color.from_string(color_html, Color.WHITE)
	EventBus.chat_message_received.emit(sender_name, text, sender_color)
