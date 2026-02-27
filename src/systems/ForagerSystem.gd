class_name ForagerSystem
extends RefCounted

## Scout Cat companion system (§3.4)
## Follows the player underground, sweeps up nearby ore chunks that were
## scattered by the ore-breaking mechanic, and returns to the surface when
## full — banking those minerals safely even if the player later dies.
## MiningLevel reads world_pos, state, carry, and capacity for draw calls.
## Chunk sweeping requires get_tree() so MiningLevel performs the scene query
## and calls sweep_chunks() with the results; all state lives here.

const CAPACITY_BASE: int     = 30
const MOVE_SPEED: float      = 140.0  # px/s while following or returning
const DEPOSIT_DELAY: float   = 1.8    # seconds at surface before returning
const COLLECT_RADIUS: float  = 80.0   # px radius within which forager sweeps chunks
const COLLECT_INTERVAL: float = 0.25  # seconds between chunk-sweep passes

## World-space cell size — mirrors MiningLevel.CELL_SIZE
const CELL_SIZE: int = 64

## Public state read by MiningLevel._draw()
var world_pos: Vector2 = Vector2.ZERO
var state: String = "follow"   # "follow" | "return" | "deposit"
var carry: int = 0
var capacity: int = CAPACITY_BASE

## Set to true each time the collect timer fires; MiningLevel reads this to
## trigger _forager_do_sweep() then the flag is cleared automatically.
var sweep_due: bool = false

var _deposit_timer: float = -1.0   # countdown while in "deposit" state; -1 = inactive
var _collect_timer: float = 0.0


## Initialise the forager near the player's spawn position.
## bonus_capacity: extra carry capacity from the settlement Forager Rations consumable.
func setup(spawn_pos: Vector2, bonus_capacity: int) -> void:
	world_pos = spawn_pos
	capacity = CAPACITY_BASE + bonus_capacity
	carry = 0
	state = "follow"
	_deposit_timer = -1.0
	_collect_timer = 0.0
	sweep_due = false


## Process forager movement each frame.
## player_pos: the player's current world position.
## surface_deposit_pos: world position of the surface deposit point
##   (computed by MiningLevel as Vector2(46 * CELL_SIZE, (SURFACE_ROWS-1)*CELL_SIZE + CELL_SIZE*0.5)).
func update(delta: float, player_pos: Vector2, surface_deposit_pos: Vector2) -> void:
	sweep_due = false
	match state:
		"follow":
			# Hover a tile behind and slightly above the player
			var target := player_pos + Vector2(-CELL_SIZE * 1.2, -CELL_SIZE * 0.5)
			world_pos = world_pos.move_toward(target, MOVE_SPEED * delta)
			# Tick the chunk-sweep interval
			_collect_timer -= delta
			if _collect_timer <= 0.0:
				_collect_timer = COLLECT_INTERVAL
				sweep_due = true
		"return":
			world_pos = world_pos.move_toward(surface_deposit_pos, MOVE_SPEED * 1.8 * delta)
			if world_pos.distance_to(surface_deposit_pos) < 12.0:
				_do_deposit()
		"deposit":
			if _deposit_timer > 0.0:
				_deposit_timer -= delta
				if _deposit_timer <= 0.0:
					_deposit_timer = -1.0
					state = "follow"


## Collect ore chunks passed in from MiningLevel's scene-tree query.
## chunk_nodes: Array of nodes in the "ore_chunk" group that are within
##              COLLECT_RADIUS of world_pos (filtered by MiningLevel).
func sweep_chunks(chunk_nodes: Array) -> void:
	for chunk in chunk_nodes:
		if not is_instance_valid(chunk):
			continue
		carry = mini(carry + chunk.value, capacity)
		chunk.collect_silent()
		if is_full:
			start_return()
			return


## True when carry has reached capacity and the forager should head home.
var is_full: bool:
	get:
		return carry >= capacity


## Begin the return journey to the surface.
func start_return() -> void:
	state = "return"
	EventBus.ore_mined_popup.emit(0, "Scout Cat heading home!")


## Reset carry and state at the start of a new run.
func reset(spawn_pos: Vector2, bonus_capacity: int) -> void:
	world_pos = spawn_pos
	capacity = CAPACITY_BASE + bonus_capacity
	carry = 0
	state = "follow"
	_deposit_timer = -1.0
	_collect_timer = 0.0
	sweep_due = false


func _do_deposit() -> void:
	if carry > 0:
		GameManager.mineral_currency += carry
		EventBus.ore_mined_popup.emit(carry, "Scout Cat banked!")
		carry = 0
	state = "deposit"
	_deposit_timer = DEPOSIT_DELAY
