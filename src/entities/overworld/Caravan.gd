class_name Caravan
extends Node2D

# Player token on the Overworld

@export var base_speed: float = 200.0
var speed: float:
	get: return base_speed * GameManager.get_ship_speed_mult()
var target_position: Vector2
var is_moving: bool = false
var movement_tween: Tween

signal arrived

func _ready() -> void:
	target_position = position

func move_to(pos: Vector2) -> void:
	move_along_path([pos])

func move_along_path(positions: Array[Vector2]) -> void:
	if positions.is_empty():
		arrived.emit()
		return

	target_position = positions[-1]
	is_moving = true

	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	# Chain each waypoint as a sequential tween step so the caravan
	# visually walks every segment of the path rather than cutting straight.
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_LINEAR)
	movement_tween.set_ease(Tween.EASE_IN_OUT)

	var from := position
	for pos in positions:
		var distance := from.distance_to(pos)
		var duration := distance / speed
		movement_tween.tween_property(self, "position", pos, duration)
		from = pos

	movement_tween.tween_callback(func() -> void:
		is_moving = false
		arrived.emit()
	)

func teleport_to(pos: Vector2) -> void:
	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	position = pos
	target_position = pos
	is_moving = false
