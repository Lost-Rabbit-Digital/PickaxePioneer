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

## True once a host or join operation has established a session.
var is_multiplayer_session: bool = false
## True on the machine that called start_host().
var is_host: bool = false
## Peer ID of the connected guest; -1 if no guest is connected yet.
var guest_peer_id: int = -1

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
	return OK

func disconnect_session() -> void:
	_reset_peer()
	is_multiplayer_session = false
	is_host = false
	guest_peer_id = -1

## Closes any active ENet socket and disconnects multiplayer signals so that a
## subsequent create_server / create_client call gets a clean slate.
func _reset_peer() -> void:
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

func _on_connected_to_server() -> void:
	connected_to_host.emit()

func _on_connection_failed() -> void:
	is_multiplayer_session = false
	connection_failed.emit()

func _on_server_disconnected() -> void:
	is_multiplayer_session = false
	host_disconnected.emit()

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
