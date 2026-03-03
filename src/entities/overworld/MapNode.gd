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

# Base sprite dimensions (64x64 at scale 1.0)
const SPRITE_BASE_SIZE: float = 64.0
const LABEL_HEIGHT: float = 23.0  # offset_bottom - offset_top (55 - 32)

func _ready() -> void:
	input_event.connect(_on_input_event)
	_update_visuals()

func _update_visuals() -> void:
	label.text = location_name

	var frame_count := sprite.sprite_frames.get_frame_count("default")
	sprite.frame = randi() % frame_count

	match node_type:
		NodeType.MINE:
			sprite.scale = Vector2(2.5, 2.5)
			sprite.modulate = Color(1.0, 0.75, 0.20)  # warm gold tint for mines
		NodeType.STATION:
			sprite.modulate = Color.CYAN
		NodeType.SETTLEMENT:
			sprite.modulate = Color(0.85, 0.60, 1.0)  # soft purple for settlements
		NodeType.EMPTY:
			sprite.modulate = Color.WHITE

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
	if active:
		sprite.scale = Vector2(3.0, 3.0) if node_type == NodeType.MINE else Vector2(1.2, 1.2)
		label.modulate = Color.YELLOW
	else:
		sprite.scale = Vector2(2.5, 2.5) if node_type == NodeType.MINE else Vector2(1.0, 1.0)
		label.modulate = Color.WHITE

	_update_label_position()

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
