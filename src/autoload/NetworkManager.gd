extends Node

## NetworkManager — owns all ENet multiplayer state for Pickaxe Pioneer co-op.
## Registered as an autoload singleton so any system can read is_host / is_multiplayer_session.
## Two-player LAN only: one host (peer id 1) + one guest.

signal host_started
signal guest_connected(peer_id: int)
signal guest_disconnected
signal connected_to_host
signal connection_failed

const DEFAULT_PORT: int = 7777
const MAX_CLIENTS: int = 1  # Host + 1 guest = 2 players total

## True once a host or join operation has established a session.
var is_multiplayer_session: bool = false
## True on the machine that called start_host().
var is_host: bool = false
## Peer ID of the connected guest; -1 if no guest is connected yet.
var guest_peer_id: int = -1

func start_host(port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		push_error("NetworkManager: failed to create server on port %d (err %d)" % [port, err])
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_multiplayer_session = true
	is_host = true
	guest_peer_id = -1
	host_started.emit()
	print("NetworkManager: hosting on port %d" % port)
	return OK

func join_host(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		push_error("NetworkManager: failed to connect to %s:%d (err %d)" % [ip, port, err])
		return err
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	is_multiplayer_session = true
	is_host = false
	print("NetworkManager: connecting to %s:%d" % [ip, port])
	return OK

func disconnect_session() -> void:
	if multiplayer.multiplayer_peer != null:
		var status := multiplayer.multiplayer_peer.get_connection_status()
		if status != MultiplayerPeer.CONNECTION_DISCONNECTED:
			multiplayer.multiplayer_peer.close()
	is_multiplayer_session = false
	is_host = false
	guest_peer_id = -1
	print("NetworkManager: session disconnected")

func _on_peer_connected(id: int) -> void:
	print("NetworkManager: peer connected id=%d" % id)
	if is_host:
		guest_peer_id = id
		guest_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("NetworkManager: peer disconnected id=%d" % id)
	if is_host and id == guest_peer_id:
		guest_peer_id = -1
		guest_disconnected.emit()

func _on_connected_to_server() -> void:
	print("NetworkManager: connected to host")
	connected_to_host.emit()

func _on_connection_failed() -> void:
	print("NetworkManager: connection failed")
	is_multiplayer_session = false
	connection_failed.emit()
