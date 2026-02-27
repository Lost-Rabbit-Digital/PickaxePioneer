class_name OreChunk
extends CharacterBody2D

# Ore chunk — spawned when an ore block is fully mined.
# Falls with gravity, lands on terrain. No automatic magnet — the player must
# physically walk onto the chunk (or the forager ant sweeps it up) to collect it.

const GRAVITY: float = 600.0
const CHUNK_SIZE: float = 20.0
const COLLECT_DIST: float = 24.0

# Ore type → chunk colour (mirrors MiningLevel.TILE_COLORS)
const CHUNK_COLORS: Dictionary = {
	3:  Color(0.80, 0.50, 0.20),   # ORE_COPPER
	4:  Color(0.70, 0.40, 0.10),   # ORE_COPPER_DEEP
	5:  Color(0.65, 0.65, 0.72),   # ORE_IRON
	6:  Color(0.55, 0.55, 0.65),   # ORE_IRON_DEEP
	7:  Color(1.00, 0.85, 0.10),   # ORE_GOLD
	8:  Color(0.90, 0.75, 0.05),   # ORE_GOLD_DEEP
	9:  Color(0.15, 0.85, 0.75),   # ORE_GEM
	10: Color(0.10, 0.75, 0.65),   # ORE_GEM_DEEP
}

## Set by MiningLevel before adding to the scene tree.
var ore_type: int = 0
var value: int = 1

func _ready() -> void:
	add_to_group("ore_chunk")
	# Layer 3 (value 4): loot layer — does not block terrain or the player.
	# Mask  1 (value 1): collides with TileMapLayer terrain so it can land.
	collision_layer = 4
	collision_mask = 1

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
	# Gravity — accelerate downward until the chunk lands.
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
		velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)

	# Collect when the player physically walks onto the chunk.
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0 and \
			global_position.distance_to(players[0].global_position) < COLLECT_DIST:
		collect()
		return

	move_and_slide()

# Collected by the player — adds value to run currency and plays a sound.
func collect() -> void:
	GameManager.add_currency(value)
	SoundManager.play_pickup_sound()
	queue_free()

# Collected silently by the forager ant — no sound or popup.
func collect_silent() -> void:
	queue_free()
