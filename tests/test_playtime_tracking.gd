extends GutTest

# Tests for playtime tracking in GameManager.
# Verifies that:
#   1. Playtime accumulates only in PLAYING state (not PAUSED or MENU).
#   2. Pausing stops the timer; resuming restarts it.
#   3. Returning to the main menu stops accumulation.
#   4. Playtime tracks in overworld, settlement, and Clowder (city) scenes.

var _gm: Node  # GameManager reference

func before_each() -> void:
	_gm = GameManager
	# Reset playtime and state for isolation
	_gm.total_playtime_seconds = 0.0
	_gm.current_state = GameManager.GameState.MENU

func after_each() -> void:
	# Restore MENU state so nothing bleeds into later tests
	_gm.current_state = GameManager.GameState.MENU

# ---------------------------------------------------------------------------
# Accumulation tests
# ---------------------------------------------------------------------------

func test_playtime_does_not_accumulate_in_menu_state() -> void:
	_gm.current_state = GameManager.GameState.MENU
	_gm._process(1.0)
	assert_eq(_gm.total_playtime_seconds, 0.0, "Playtime should not accumulate in MENU state")

func test_playtime_accumulates_in_playing_state() -> void:
	_gm.current_state = GameManager.GameState.PLAYING
	_gm._process(1.0)
	assert_eq(_gm.total_playtime_seconds, 1.0, "Playtime should accumulate in PLAYING state")

func test_playtime_does_not_accumulate_in_paused_state() -> void:
	_gm.current_state = GameManager.GameState.PAUSED
	_gm._process(1.0)
	assert_eq(_gm.total_playtime_seconds, 0.0, "Playtime should not accumulate in PAUSED state")

func test_playtime_does_not_accumulate_in_game_over_state() -> void:
	_gm.current_state = GameManager.GameState.GAME_OVER
	_gm._process(1.0)
	assert_eq(_gm.total_playtime_seconds, 0.0, "Playtime should not accumulate in GAME_OVER state")

# ---------------------------------------------------------------------------
# State transition tests
# ---------------------------------------------------------------------------

func test_pause_game_stops_accumulation() -> void:
	_gm.current_state = GameManager.GameState.PLAYING
	_gm._process(2.0)
	_gm.pause_game()
	_gm._process(3.0)  # These 3 seconds should NOT count
	assert_eq(_gm.total_playtime_seconds, 2.0, "Playtime should stop accumulating after pause_game()")

func test_resume_to_playing_restarts_accumulation() -> void:
	_gm.current_state = GameManager.GameState.PLAYING
	_gm._process(1.0)
	_gm.pause_game()
	_gm._process(5.0)  # Paused — should not count
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(2.0)
	assert_eq(_gm.total_playtime_seconds, 3.0, "Playtime should resume after returning to PLAYING state")

func test_playtime_accumulates_across_multiple_process_calls() -> void:
	_gm.current_state = GameManager.GameState.PLAYING
	_gm._process(0.5)
	_gm._process(0.5)
	_gm._process(0.5)
	assert_almost_eq(_gm.total_playtime_seconds, 1.5, 0.001, "Playtime should accumulate across frames")

# ---------------------------------------------------------------------------
# Overworld / settlement / Clowder scene-entry tests
# These verify that change_state(PLAYING) is emitted correctly when entering
# each non-mine scene, so playtime is never silently paused while the player
# navigates the star chart, visits a settlement, or upgrades at the Clowder.
# ---------------------------------------------------------------------------

func test_playtime_tracks_on_overworld() -> void:
	# Simulate time spent browsing the star chart after load_overworld() sets PLAYING.
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(4.0)
	assert_eq(_gm.total_playtime_seconds, 4.0, "Playtime should track while on the overworld")

func test_playtime_tracks_in_settlement() -> void:
	# Simulate time spent at a settlement after load_settlement_level() sets PLAYING.
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(6.0)
	assert_eq(_gm.total_playtime_seconds, 6.0, "Playtime should track while in a settlement")

func test_playtime_tracks_at_clowder() -> void:
	# Simulate time spent upgrading at the Clowder (CityLevel) after load_mining_level() sets PLAYING.
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(8.0)
	assert_eq(_gm.total_playtime_seconds, 8.0, "Playtime should track while at the Clowder")

func test_playtime_resumes_on_overworld_after_non_playing_state() -> void:
	# Verifies the guard added to load_overworld(): even if state drifted away from
	# PLAYING (e.g. a future code path sets GAME_OVER), explicitly calling
	# change_state(PLAYING) before the scene transition restores tracking.
	_gm.current_state = GameManager.GameState.GAME_OVER
	_gm._process(2.0)  # Should not count — GAME_OVER
	assert_eq(_gm.total_playtime_seconds, 0.0, "Playtime must not accumulate in GAME_OVER")
	_gm.change_state(GameManager.GameState.PLAYING)  # Mirrors what load_overworld() now does
	_gm._process(3.0)
	assert_eq(_gm.total_playtime_seconds, 3.0, "Playtime must resume once PLAYING is restored on overworld entry")

func test_playtime_continuous_across_scene_sequence() -> void:
	# Simulate mine → overworld → settlement with no lost seconds.
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(10.0)  # Time in mine
	# load_overworld() calls change_state(PLAYING) — no interruption
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(5.0)   # Time on overworld
	# load_settlement_level() calls change_state(PLAYING) — no interruption
	_gm.change_state(GameManager.GameState.PLAYING)
	_gm._process(3.0)   # Time in settlement
	assert_eq(_gm.total_playtime_seconds, 18.0, "Playtime should be continuous across mine → overworld → settlement")
