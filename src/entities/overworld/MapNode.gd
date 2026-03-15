class_name MapNode
extends Area2D

# Represents a location on the Overworld

enum NodeType {
	EMPTY,
	MINE,       # was ASTEROID — ordinal kept at 1 so existing .tscn data is unchanged
	STATION,
	SETTLEMENT  # overworld rest-stop / trader node
}

@export var location_name: String = "Unknown"
@export var node_type: NodeType = NodeType.EMPTY
@export var scene_path: String = ""
@export var description: String = ""
@export var difficulty: int = 1
@export var ore_types: Array = []
@export var hazard_types: Array = []

signal node_clicked(node: MapNode)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var label: Label = $Label
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Base sprite dimensions (64x64 at scale 1.0)
const SPRITE_BASE_SIZE: float = 64.0
const LABEL_HEIGHT: float = 23.0  # offset_bottom - offset_top (55 - 32)

# Base scales before size multiplier is applied
const BASE_SCALE_MINE: float = 2.5
const BASE_SCALE_OTHER: float = 1.0

# Scale multiplier per planet size category
const SIZE_SCALE: Dictionary = {"Small": 0.70, "Medium": 1.0, "Large": 1.40}

# Resolved base scale for this node — set in _update_visuals, used by highlight()
var _base_scale: float = 1.0

# Store the base colour (before locking) so we can restore it when unlocking
var _base_modulate: Color = Color.WHITE

# Biome, temperature, and size data keyed by sprite frame index.
# Sizes: Small <= 13,000 km | Medium 13,001–47,999 km | Large >= 48,000 km
const PLANET_DATA: Array[Dictionary] = [
	{"biome": "Ice",    "temperature": "Cold",   "size": "Medium"},  # 0
	{"biome": "Desert", "temperature": "Hot",    "size": "Small"},   # 1
	{"biome": "Forest", "temperature": "Medium", "size": "Large"},   # 2
	{"biome": "Forest", "temperature": "Medium", "size": "Medium"},  # 3
	{"biome": "Desert", "temperature": "Hot",    "size": "Medium"},  # 4
	{"biome": "Rock",   "temperature": "Hot",    "size": "Large"},   # 5
	{"biome": "Ice",    "temperature": "Cold",   "size": "Small"},   # 6
	{"biome": "Jungle", "temperature": "Hot",    "size": "Large"},   # 7
	{"biome": "Rock",   "temperature": "Hot",    "size": "Medium"},  # 8
	{"biome": "Forest", "temperature": "Medium", "size": "Small"},   # 9
	{"biome": "Rock",   "temperature": "Hot",    "size": "Large"},   # 10
	{"biome": "Ice",    "temperature": "Cold",   "size": "Medium"},  # 11
]

func get_planet_info() -> Dictionary:
	if sprite and sprite.frame >= 0 and sprite.frame < PLANET_DATA.size():
		return PLANET_DATA[sprite.frame]
	return {"biome": "Unknown", "temperature": "Unknown", "size": "Unknown"}

func _ready() -> void:
	input_event.connect(_on_input_event)
	_update_visuals()

func _update_visuals() -> void:
	var frame_count := sprite.sprite_frames.get_frame_count("default")
	sprite.frame = randi() % frame_count
	refresh_visuals()

## Recalculate tint, scale, and label based on the current sprite frame without
## re-randomizing it.  Call this after manually setting sprite.frame (e.g. when
## restoring a saved frame from planet config) to keep the visual scale in sync
## with the planet size category for that frame.
func refresh_visuals() -> void:
	label.text = location_name

	# Resolve size multiplier now that the frame (and thus planet size) is known
	var planet_size: String = get_planet_info().get("size", "Medium")
	var size_factor: float = SIZE_SCALE.get(planet_size, 1.0)

	match node_type:
		NodeType.MINE:
			_base_scale = BASE_SCALE_MINE * size_factor
			_base_modulate = Color(1.0, 0.75, 0.20)  # warm gold tint for mines
		NodeType.STATION:
			_base_scale = BASE_SCALE_OTHER * size_factor
			_base_modulate = Color.CYAN
		NodeType.SETTLEMENT:
			_base_scale = BASE_SCALE_OTHER * size_factor
			_base_modulate = Color(0.85, 0.60, 1.0)  # soft purple for settlements
		NodeType.EMPTY:
			_base_scale = BASE_SCALE_OTHER * size_factor
			_base_modulate = Color.WHITE

	sprite.modulate = _base_modulate
	sprite.scale = Vector2(_base_scale, _base_scale)
	_update_collision_radius(_base_scale)
	_update_label_position()

var neighbors: Array[MapNode] = []

func _update_label_position() -> void:
	# Position label below sprite, accounting for sprite scale
	var half_sprite_height = (SPRITE_BASE_SIZE / 2.0) * sprite.scale.y
	var label_offset_top = half_sprite_height
	var label_offset_bottom = label_offset_top + LABEL_HEIGHT

	label.offset_top = label_offset_top
	label.offset_bottom = label_offset_bottom

func highlight(active: bool) -> void:
	var highlight_scale: float = _base_scale * 1.2 if active else _base_scale
	sprite.scale = Vector2(highlight_scale, highlight_scale)
	_update_collision_radius(highlight_scale)
	label.modulate = Color.YELLOW if active else Color.WHITE
	_update_label_position()

func _update_collision_radius(scale_value: float) -> void:
	var shape := collision_shape.shape as CircleShape2D
	shape.radius = (SPRITE_BASE_SIZE / 2.0) * scale_value

func set_locked(is_locked: bool) -> void:
	# Apply or remove grey modulation based on lock state
	if is_locked:
		sprite.modulate = _base_modulate * Color(0.5, 0.5, 0.5, 1.0)
	else:
		sprite.modulate = _base_modulate

func get_average_pixel_color() -> Color:
	# Sample every non-transparent pixel from the current sprite frame and return
	# their average RGB colour.  The AtlasTexture for each frame covers a 64×64
	# region of the planets spritesheet, so we crop to that region explicitly.
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture("default", sprite.frame)
	if texture == null:
		return Color.WHITE

	var image: Image
	if texture is AtlasTexture:
		var atlas_img: Image = texture.atlas.get_image()
		image = atlas_img.get_region(Rect2i(texture.region))
	else:
		image = texture.get_image()

	if image == null or image.is_empty():
		return Color.WHITE

	var total_r := 0.0
	var total_g := 0.0
	var total_b := 0.0
	var count := 0
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var px: Color = image.get_pixel(x, y)
			if px.a > 0.1:
				total_r += px.r
				total_g += px.g
				total_b += px.b
				count += 1

	if count == 0:
		return Color.WHITE
	return Color(total_r / count, total_g / count, total_b / count)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		node_clicked.emit(self)
