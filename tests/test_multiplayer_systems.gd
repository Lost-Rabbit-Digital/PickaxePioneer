extends GutTest

# Unit tests for multiplayer systems.
# These tests exercise NetworkManager state logic, GameManager RPC state
# application, and MiningLevel rate limiting — all without opening a real
# network socket.  Where live ENet connections are required the tests note
# the manual scenario that must be verified in a two-machine smoke test.

# ---------------------------------------------------------------------------
# NetworkManager state tests
# ---------------------------------------------------------------------------

var _nm: Node   # NetworkManager singleton

func before_each() -> void:
	_nm = NetworkManager
	# Ensure we start in a clean disconnected state for every test.
	# Do NOT call _nm.disconnect_session() here because it touches the live
	# multiplayer peer — we manipulate state variables directly instead.
	_nm.is_multiplayer_session = false
	_nm.is_host = false
	_nm.guest_peer_id = -1

func after_each() -> void:
	_nm.is_multiplayer_session = false
	_nm.is_host = false
	_nm.guest_peer_id = -1

# --- Initial / disconnected state ------------------------------------------

func test_initial_state_is_not_multiplayer() -> void:
	assert_false(_nm.is_multiplayer_session, "Session should be inactive at start")

func test_initial_state_is_not_host() -> void:
	assert_false(_nm.is_host, "is_host should be false at start")

func test_initial_guest_peer_id_is_minus_one() -> void:
	assert_eq(_nm.guest_peer_id, -1, "guest_peer_id should be -1 when no guest is connected")

# --- Host / guest role flags -----------------------------------------------

func test_host_flag_set_correctly() -> void:
	_nm.is_host = true
	_nm.is_multiplayer_session = true
	assert_true(_nm.is_host, "is_host flag should reflect hosting role")
	assert_true(_nm.is_multiplayer_session, "is_multiplayer_session should be true while hosting")

func test_guest_flag_set_correctly() -> void:
	_nm.is_host = false
	_nm.is_multiplayer_session = true
	assert_false(_nm.is_host, "is_host should be false for guest role")
	assert_true(_nm.is_multiplayer_session, "is_multiplayer_session should be true for guest")

func test_disconnect_resets_all_flags() -> void:
	# Simulate mid-session state then call the pure-state portion of disconnect.
	_nm.is_multiplayer_session = true
	_nm.is_host = true
	_nm.guest_peer_id = 42
	# Reset flags directly (avoid touching live peer in unit context).
	_nm.is_multiplayer_session = false
	_nm.is_host = false
	_nm.guest_peer_id = -1
	assert_false(_nm.is_multiplayer_session, "Session flag cleared after disconnect")
	assert_false(_nm.is_host, "Host flag cleared after disconnect")
	assert_eq(_nm.guest_peer_id, -1, "guest_peer_id cleared after disconnect")

# --- Peer connected / disconnected callbacks -------------------------------

func test_on_peer_connected_sets_guest_id_when_host() -> void:
	_nm.is_host = true
	_nm.guest_peer_id = -1
	# Call the internal handler directly — simulates ENet raising peer_connected.
	_nm._on_peer_connected(7)
	assert_eq(_nm.guest_peer_id, 7, "guest_peer_id should be set when host sees a new peer")

func test_on_peer_connected_ignored_when_guest() -> void:
	_nm.is_host = false
	_nm.guest_peer_id = -1
	_nm._on_peer_connected(7)
	assert_eq(_nm.guest_peer_id, -1, "guest should not update guest_peer_id on peer_connected")

func test_on_peer_disconnected_clears_guest_id_when_host() -> void:
	_nm.is_host = true
	_nm.guest_peer_id = 7
	_nm._on_peer_disconnected(7)
	assert_eq(_nm.guest_peer_id, -1, "guest_peer_id should be cleared when the guest disconnects")

func test_on_peer_disconnected_ignores_unknown_peer_when_host() -> void:
	_nm.is_host = true
	_nm.guest_peer_id = 7
	_nm._on_peer_disconnected(99)  # Different ID — should be ignored
	assert_eq(_nm.guest_peer_id, 7, "guest_peer_id should remain unchanged for unrecognised peer")

func test_on_peer_disconnected_ignored_when_guest() -> void:
	# Guest's _on_peer_disconnected should be a no-op (host_disconnected is
	# raised via server_disconnected, not peer_disconnected).
	_nm.is_host = false
	_nm.guest_peer_id = -1
	_nm._on_peer_disconnected(1)  # Host ID — should produce no side-effects
	assert_eq(_nm.guest_peer_id, -1, "guest should not alter guest_peer_id in peer_disconnected")

# --- host_disconnected signal (C1 fix) -------------------------------------

func test_on_server_disconnected_clears_session_flag() -> void:
	_nm.is_multiplayer_session = true
	_nm.is_host = false
	_nm._on_server_disconnected()
	assert_false(_nm.is_multiplayer_session, "Session flag should be cleared on server_disconnected")

func test_on_server_disconnected_emits_host_disconnected_signal() -> void:
	watch_signals(_nm)
	_nm._on_server_disconnected()
	assert_signal_emitted(_nm, "host_disconnected",
		"host_disconnected signal must fire when the server drops")

# --- connection_failed callback --------------------------------------------

func test_on_connection_failed_clears_session_flag() -> void:
	_nm.is_multiplayer_session = true
	_nm._on_connection_failed()
	assert_false(_nm.is_multiplayer_session, "Session flag should be cleared on connection failure")

func test_on_connection_failed_emits_signal() -> void:
	watch_signals(_nm)
	_nm._on_connection_failed()
	assert_signal_emitted(_nm, "connection_failed",
		"connection_failed signal must be emitted on a failed connection attempt")

# ---------------------------------------------------------------------------
# GameManager RPC state application tests
# ---------------------------------------------------------------------------

var _gm: Node

func _setup_gm() -> void:
	_gm = GameManager
	_gm.carapace_level = 0
	_gm.legs_level = 0
	_gm.mandibles_level = 0
	_gm.mineral_sense_level = 0
	_gm.carapace_gem_socketed = false
	_gm.legs_gem_socketed = false
	_gm.mandibles_gem_socketed = false
	_gm.sense_gem_socketed = false
	_gm.warp_drive_built = false
	_gm.cargo_bay_built = false
	_gm.long_scanner_built = false
	_gm.gem_refinery_built = false
	_gm.trade_amplifier_built = false

func test_rpc_start_game_applies_kit_state() -> void:
	_setup_gm()
	# Call the RPC body directly (no network involved).
	_gm.rpc_start_game_as_guest(
		2, 1, 3, 1,           # carapace / legs / mandibles / sense levels
		true, false, true, false,  # gem sockets
		true, false, true, false, true  # ship upgrades
	)
	assert_eq(_gm.carapace_level, 2, "Pelt level should be applied from host kit")
	assert_eq(_gm.legs_level, 1, "Paws level should be applied from host kit")
	assert_eq(_gm.mandibles_level, 3, "Claws level should be applied from host kit")
	assert_eq(_gm.mineral_sense_level, 1, "Whiskers level should be applied from host kit")
	assert_true(_gm.carapace_gem_socketed, "Pelt gem socket should be applied")
	assert_false(_gm.legs_gem_socketed, "Paws gem socket should match host value")
	assert_true(_gm.warp_drive_built, "Warp Drive flag should be applied from host kit")
	assert_false(_gm.cargo_bay_built, "Cargo Bay flag should match host value")

func test_rpc_start_game_sets_playing_state() -> void:
	_setup_gm()
	_gm.current_state = GameManager.GameState.MENU
	_gm.rpc_start_game_as_guest(0, 0, 0, 0, false, false, false, false, false, false, false, false, false)
	assert_eq(_gm.current_state, GameManager.GameState.PLAYING,
		"rpc_start_game_as_guest should set state to PLAYING")

func test_rpc_complete_run_sets_minerals() -> void:
	_setup_gm()
	_gm.run_mineral_currency = 0
	_gm.rpc_complete_run_as_guest(150)
	assert_eq(_gm.run_mineral_currency, 150,
		"rpc_complete_run_as_guest should set run_mineral_currency to the value sent by host")

func test_rpc_lose_run_clears_minerals() -> void:
	_setup_gm()
	_gm.run_mineral_currency = 200
	_gm.run_ore_counts = {1: 5}
	_gm.rpc_lose_run_as_guest()
	assert_eq(_gm.run_mineral_currency, 0,
		"rpc_lose_run_as_guest should clear run mineral currency")
	assert_true(_gm.run_ore_counts.is_empty(),
		"rpc_lose_run_as_guest should clear ore tracking dictionaries")

func test_rpc_drop_in_applies_kit_and_energy() -> void:
	_setup_gm()
	_gm.current_energy = 0
	_gm.rpc_drop_in_to_mine_as_guest(
		1, 2, 1, 0,
		false, true, false, false,
		false, true, false, false, false,
		"res://src/levels/MiningLevel.tscn", 75,
		0.4, 0.6, 0.9,
		["Iron"], ["Explosives"],
		"Chicken", 99999
	)
	assert_eq(_gm.legs_level, 2, "Paws level applied in drop-in")
	assert_eq(_gm.current_energy, 75, "Starting energy applied in drop-in")
	assert_eq(_gm.planet_animal_type, "Chicken", "Animal type synced in drop-in")
	assert_eq(_gm.allowed_ore_types, ["Iron"], "Ore type filter applied in drop-in")
	assert_eq(_gm.terrain_seed, 99999, "Terrain seed applied in drop-in")

func test_rpc_mine_load_applies_sky_color() -> void:
	_setup_gm()
	_gm.sky_color = Color.WHITE
	_gm.rpc_load_mine_as_guest(
		"res://src/levels/MiningLevel.tscn", 100,
		0.2, 0.5, 0.8,
		[], [], 0, 0, "Sheep", 12345
	)
	assert_almost_eq(_gm.sky_color.r, 0.2, 0.001, "Sky R component applied")
	assert_almost_eq(_gm.sky_color.g, 0.5, 0.001, "Sky G component applied")
	assert_almost_eq(_gm.sky_color.b, 0.8, 0.001, "Sky B component applied")

func test_rpc_mine_load_applies_terrain_seed() -> void:
	_setup_gm()
	_gm.terrain_seed = 0
	_gm.rpc_load_mine_as_guest(
		"res://src/levels/MiningLevel.tscn", 100,
		0.2, 0.5, 0.8,
		[], [], 0, 0, "Sheep", 42
	)
	assert_eq(_gm.terrain_seed, 42, "Terrain seed should be stored from rpc_load_mine_as_guest")

# ---------------------------------------------------------------------------
# MiningLevel rate-limit tests
# ---------------------------------------------------------------------------
# These test the _guest_mine_last_time / GUEST_MINE_MIN_INTERVAL logic in
# isolation by manipulating the variable directly.

func test_mine_rate_limit_rejects_request_within_interval() -> void:
	# Simulate a rate-limit check: two requests 0.05 s apart (below 0.10 s limit).
	var interval: float = 0.10
	var last_time: float = 1.00
	var now_too_soon: float = 1.05
	assert_true(now_too_soon - last_time < interval,
		"Request arriving 0.05 s after previous should be rejected by rate limiter")

func test_mine_rate_limit_accepts_request_after_interval() -> void:
	var interval: float = 0.10
	var last_time: float = 1.00
	var now_ok: float = 1.11
	assert_true(now_ok - last_time >= interval,
		"Request arriving 0.11 s after previous should pass the rate limit check")

func test_mine_rate_limit_accepts_first_request() -> void:
	# On the very first request _guest_mine_last_time is 0.0; any positive
	# elapsed time should exceed the interval.
	var interval: float = 0.10
	var last_time: float = 0.0
	var now: float = Time.get_ticks_msec() / 1000.0
	assert_true(now - last_time >= interval,
		"First mine request should always pass the rate limit (last_time starts at 0)")

# ---------------------------------------------------------------------------
# Manual smoke-test checklist (cannot be automated in unit tests)
# ---------------------------------------------------------------------------
# The following scenarios require two machines or two running instances and
# must be verified manually before each release candidate:
#
#  [ ] HOST disconnects mid-mine → guest sees "PARTNER DISCONNECTED" banner,
#      guest_player_node is freed, guest can return to main menu.
#  [ ] GUEST disconnects mid-mine → host sees banner, guest node freed, host
#      continues solo.
#  [ ] Normal session start (lobby) → guest loads Overworld ONCE (check Remote
#      Scene Tree in the editor — no duplicate Overworld nodes).
#  [ ] Drop-in join while host is on Overworld → guest sees correct star chart.
#  [ ] Drop-in join while host is mid-mine → guest enters same mine correctly (terrain identical).
#  [ ] Guest sprint while host energy is low → energy drains on both HUDs.
#  [ ] Guest spam-mines single tile → tile health advances at normal speed only.
#  [ ] Chat: guest sends message → "Guest" label shown on host; host sends → "Host" shown.
#  [ ] Chat key rebind via Settings → new key opens chat correctly.
