class_name Caravan
extends Node2D

# Player token on the Overworld

@export var speed: float = 200.0
var target_position: Vector2
var is_moving: bool = false

signal arrived

func _ready() -> void:
	target_position = position

func _process(delta: float) -> void:
	if position.distance_to(target_position) > 5.0:
		position = position.move_toward(target_position, speed * delta)
		is_moving = true
	else:
		if is_moving:
			is_moving = false
			arrived.emit()
		# Arrived
		pass

func move_to(pos: Vector2) -> void:
	target_position = pos
	is_moving = true

func teleport_to(pos: Vector2) -> void:
	position = pos
	target_position = pos
	is_moving = false
