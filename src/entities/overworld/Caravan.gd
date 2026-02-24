class_name Caravan
extends Node2D

# Player token on the Overworld

@export var speed: float = 200.0
var target_position: Vector2
var is_moving: bool = false
var movement_tween: Tween

signal arrived

func _ready() -> void:
	target_position = position

func move_to(pos: Vector2) -> void:
	target_position = pos
	is_moving = true

	# Kill any existing tween
	if movement_tween:
		movement_tween.kill()

	# Calculate distance and duration based on speed
	var distance = position.distance_to(pos)
	var duration = distance / speed

	# Create smooth animation along the line
	movement_tween = create_tween()
	movement_tween.set_trans(Tween.TRANS_LINEAR)
	movement_tween.set_ease(Tween.EASE_IN_OUT)
	movement_tween.tween_property(self, "position", pos, duration)
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
