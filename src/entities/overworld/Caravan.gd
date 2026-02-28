class_name Caravan
extends Node2D

# Player token on the Overworld

@export var base_speed: float = 200.0
@export var wiggle_amplitude: float = 3.0
@export var wiggle_frequency: float = 4.0
@export var orbit_radius: float = 30.0
@export var orbit_speed: float = 0.15
@export var orbit_scale: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D

var speed: float:
	get: return base_speed * GameManager.get_ship_speed_mult()
var target_position: Vector2
var is_moving: bool = false
var movement_tween: Tween
var _wiggle_time: float = 0.0
var _orbit_time: float = 0.0
var _travel_direction: Vector2 = Vector2.ZERO
var _waypoints_remaining: Array[Vector2] = []

signal arrived

func _ready() -> void:
	target_position = position

func _process(delta: float) -> void:
	if is_moving:
		sprite.scale = Vector2.ONE
		_wiggle_time += delta
		_orbit_time = 0.0
		# Perpendicular wiggle: offset the sprite along the normal of the travel direction
		var perp := Vector2(-_travel_direction.y, _travel_direction.x)
		sprite.position = perp * sin(_wiggle_time * wiggle_frequency * TAU) * wiggle_amplitude
	else:
		_wiggle_time = 0.0
		_orbit_time += delta
		# Half size and orbit slowly around the node
		sprite.scale = Vector2(orbit_scale, orbit_scale)
		sprite.position = Vector2(cos(_orbit_time * orbit_speed * TAU), sin(_orbit_time * orbit_speed * TAU)) * orbit_radius

func move_to(pos: Vector2) -> void:
	move_along_path([pos])

func move_along_path(positions: Array[Vector2]) -> void:
	if positions.is_empty():
		arrived.emit()
		return

	# If already moving, prepend the waypoints not yet reached so the caravan
	# finishes its current road segment(s) before heading to the new destination.
	# This prevents the caravan from cutting across non-road paths on redirect.
	var full_path: Array[Vector2] = []
	if is_moving and not _waypoints_remaining.is_empty():
		full_path.assign(_waypoints_remaining)
	full_path.append_array(positions)

	_waypoints_remaining.assign(full_path)
	target_position = full_path[-1]
	is_moving = true
	_wiggle_time = 0.0
	SoundManager.start_rocket_engine_sound()

	# Flip sprite based on horizontal direction to the first waypoint
	_update_facing(full_path[0])

	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	# Chain each waypoint as a sequential tween step so the caravan
	# visually walks every segment of the path rather than cutting straight.
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_LINEAR)
	movement_tween.set_ease(Tween.EASE_IN_OUT)

	var from := position
	for i in range(full_path.size()):
		var pos := full_path[i]
		var distance := from.distance_to(pos)
		var duration := distance / speed
		# Update facing direction at each waypoint
		if i > 0:
			movement_tween.tween_callback(_update_facing.bind(pos))
		movement_tween.tween_property(self, "position", pos, duration)
		movement_tween.tween_callback(_consume_waypoint)
		from = pos

	movement_tween.tween_callback(func() -> void:
		is_moving = false
		SoundManager.stop_rocket_engine_sound()
		arrived.emit()
	)

func _consume_waypoint() -> void:
	if not _waypoints_remaining.is_empty():
		_waypoints_remaining.pop_front()

func _update_facing(target: Vector2) -> void:
	_travel_direction = position.direction_to(target)
	# Flip sprite horizontally when travelling left
	if abs(_travel_direction.x) > 0.01:
		sprite.flip_h = _travel_direction.x < 0

func teleport_to(pos: Vector2) -> void:
	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	SoundManager.stop_rocket_engine_sound()
	position = pos
	target_position = pos
	is_moving = false
	_waypoints_remaining.clear()
	_orbit_time = 0.0
	sprite.position = Vector2.ZERO
