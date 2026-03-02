extends GutTest

# Tests for playtime tracking in GameManager.
# Verifies that:
#   1. Playtime accumulates only in PLAYING state (not PAUSED or MENU).
#   2. Pausing stops the timer; resuming restarts it.
#   3. Returning to the main menu stops accumulation.

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
