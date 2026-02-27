class_name SonarSystem
extends RefCounted

## Sonar ping system (§3.2)
## Fires an expanding wave that reveals ore tiles for a short duration.
## MiningLevel reads ping_active, ping_center, wave_radius, and ping_elapsed
## for draw calls; all state management lives here.
## The ancient_map_mult parameter (1.0 or 2.0) is passed in from MiningLevel
## so this class has no knowledge of trader item state.

const PING_DURATION: float = 3.0

## Public state read by MiningLevel._draw()
var ping_active: bool = false
var ping_elapsed: float = 0.0
var ping_center: Vector2i = Vector2i(-1, -1)
var wave_radius: float = 0.0


## Attempt to fire a sonar ping at the player's current grid position.
## Consumes energy via GameManager; emits a popup if insufficient.
func try_ping(player_grid_pos: Vector2i) -> void:
	if ping_active:
		return
	var energy_cost := GameManager.get_sonar_ping_energy_cost()
	if GameManager.current_energy < energy_cost:
		EventBus.ore_mined_popup.emit(0, "No energy for ping")
		return
	GameManager.consume_energy(energy_cost)
	ping_active = true
	ping_elapsed = 0.0
	wave_radius = 0.0
	ping_center = player_grid_pos


## Advance the ping wave each frame.
## ancient_map_mult: pass 2.0 if the Ancient Map buff is active, else 1.0.
func update(delta: float, ancient_map_mult: float) -> void:
	if not ping_active:
		return
	ping_elapsed += delta
	var max_radius: float = GameManager.get_sonar_ping_radius() * ancient_map_mult
	wave_radius = (ping_elapsed / PING_DURATION) * max_radius
	if ping_elapsed >= PING_DURATION:
		ping_active = false


## Reset state at the start of a new run.
func reset() -> void:
	ping_active = false
	ping_elapsed = 0.0
	ping_center = Vector2i(-1, -1)
	wave_radius = 0.0
