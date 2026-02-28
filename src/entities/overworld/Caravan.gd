class_name Caravan
extends Node2D

# Player token on the Overworld

@export var base_speed: float = 200.0
@export var wiggle_amplitude: float = 3.0
@export var wiggle_frequency: float = 4.0

@onready var sprite: Sprite2D = $Sprite2D

var speed: float:
	get: return base_speed * GameManager.get_ship_speed_mult()
var target_position: Vector2
var is_moving: bool = false
var movement_tween: Tween
var _wiggle_time: float = 0.0
var _travel_direction: Vector2 = Vector2.ZERO

signal arrived

func _ready() -> void:
	target_position = position

func _process(delta: float) -> void:
	if is_moving:
		_wiggle_time += delta
		# Perpendicular wiggle: offset the sprite along the normal of the travel direction
		var perp := Vector2(-_travel_direction.y, _travel_direction.x)
		sprite.position = perp * sin(_wiggle_time * wiggle_frequency * TAU) * wiggle_amplitude
	else:
		# Smoothly settle the sprite back to center
		sprite.position = sprite.position.lerp(Vector2.ZERO, 0.2)
		_wiggle_time = 0.0

func move_to(pos: Vector2) -> void:
	move_along_path([pos])

func move_along_path(positions: Array[Vector2]) -> void:
	if positions.is_empty():
		arrived.emit()
		return

	target_position = positions[-1]
	is_moving = true
	_wiggle_time = 0.0

	# Flip sprite based on horizontal direction to the first waypoint
	_update_facing(positions[0])

	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	# Chain each waypoint as a sequential tween step so the caravan
	# visually walks every segment of the path rather than cutting straight.
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_LINEAR)
	movement_tween.set_ease(Tween.EASE_IN_OUT)

	var from := position
	for i in range(positions.size()):
		var pos := positions[i]
		var distance := from.distance_to(pos)
		var duration := distance / speed
		# Update facing direction at each waypoint
		if i > 0:
			movement_tween.tween_callback(_update_facing.bind(pos))
		movement_tween.tween_property(self, "position", pos, duration)
		from = pos

	movement_tween.tween_callback(func() -> void:
		is_moving = false
		arrived.emit()
	)

func _update_facing(target: Vector2) -> void:
	_travel_direction = position.direction_to(target)
	# Flip sprite horizontally when travelling left
	if abs(_travel_direction.x) > 0.01:
		sprite.flip_h = _travel_direction.x < 0

func teleport_to(pos: Vector2) -> void:
	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	position = pos
	target_position = pos
	is_moving = false
	sprite.position = Vector2.ZERO
