class_name OreChunk
extends CharacterBody2D

# Ore chunk — spawned when an ore block is fully mined.
# Falls with gravity, lands on terrain. No automatic magnet — the player must
# physically walk onto the chunk (or the Scout Cat sweeps it up) to collect it.

const GRAVITY: float = 600.0
const CHUNK_SIZE: float = 20.0
const COLLECT_DIST: float = 30.0
const MAGNET_SPEED: float = 220.0  # Pixels/sec toward player when Magnet trinket equipped
# Speed threshold below which a grounded chunk is considered at rest.
const SETTLE_SPEED_THRESHOLD: float = 5.0
# Bitmask for the "settled ore" physics layer (Layer 4 = value 8).
# Settled chunks join this layer so in-flight chunks can land on top of them.
const SETTLED_LAYER: int = 8

# Ore type → chunk colour (mirrors MiningLevel.TILE_PARTICLE_COLORS)
const CHUNK_COLORS: Dictionary = {
	3: Color(0.25, 0.25, 0.28),   # ORE_COAL
	4: Color(0.78, 0.44, 0.20),   # ORE_COPPER
	5: Color(0.65, 0.68, 0.75),   # ORE_IRON
	6: Color(1.00, 0.80, 0.10),   # ORE_GOLD
	7: Color(0.60, 0.90, 1.00),   # ORE_DIAMOND
}

## Set by MiningLevel before adding to the scene tree.
var ore_type: int = 0
var value: int = 1
var is_settled: bool = false
# Cooldown so the "Inventory full!" popup is not emitted every frame.
var _full_warn_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("ore_chunk")
	# Layer 3 (value 4): loot layer — does not block terrain or the player.
	# Mask includes terrain (1) and settled ore (8) so chunks can land on each other.
	collision_layer = 4
	collision_mask = 1 | SETTLED_LAYER

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	shape.shape = rect
	add_child(shape)

	queue_redraw()

func _draw() -> void:
	var color: Color = CHUNK_COLORS.get(ore_type, Color(0.7, 0.7, 0.7))
	var half: float = CHUNK_SIZE * 0.5
	draw_rect(Rect2(-half, -half, CHUNK_SIZE, CHUNK_SIZE), color)
	# Small highlight corner for a mineral-glint look.
	draw_rect(Rect2(-half, -half, CHUNK_SIZE * 0.45, CHUNK_SIZE * 0.45), color.lightened(0.45))

func _physics_process(delta: float) -> void:
	if _full_warn_cooldown > 0.0:
		_full_warn_cooldown -= delta

	# Collect when the player physically walks onto the chunk (settled or not).
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var dist_to_player := global_position.distance_to(players[0].global_position)
		if dist_to_player < COLLECT_DIST:
			if GameManager.is_inventory_full():
				if _full_warn_cooldown <= 0.0:
					EventBus.ore_mined_popup.emit(0, "Inventory full!")
					_full_warn_cooldown = 3.0
				return
			collect()
			return
		# Magnet trinket — pull the chunk toward the player when within range.
		var magnet_range := GameManager.get_magnet_range()
		if magnet_range > 0.0 and dist_to_player < magnet_range:
			if not GameManager.is_inventory_full():
				var dir: Vector2 = (players[0].global_position - global_position).normalized()
				velocity = dir * MAGNET_SPEED
				is_settled = false
				collision_layer = 4
				return

	# Settled chunks keep probing downward so floor detection stays current.
	# If the terrain beneath is mined away, they resume falling.
	if is_settled:
		velocity.y = GRAVITY * delta
		move_and_slide()
		if is_on_floor():
			velocity = Vector2.ZERO
			return
		# Floor removed — resume falling.
		is_settled = false
		collision_layer = 4

	# Gravity — accelerate downward until the chunk lands.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
		# Once horizontal motion dies out, settle and join the stacking layer.
		if abs(velocity.x) < SETTLE_SPEED_THRESHOLD:
			_settle()
			return

	move_and_slide()

# Transition to the settled state: stop moving and join the settled-ore collision
# layer so future falling chunks can land on top of this one, forming a pile.
func _settle() -> void:
	is_settled = true
	velocity = Vector2.ZERO
	collision_layer = 4 | SETTLED_LAYER

# Collected by the player — adds value to run currency and plays a sound.
func collect() -> void:
	GameManager.add_currency(value)
	GameManager.track_ore_chunk_collected_by_type(ore_type)
	SoundManager.play_pickup_sound()
	queue_free()

# Collected silently by the Scout Cat — no sound or popup.
func collect_silent() -> void:
	queue_free()
