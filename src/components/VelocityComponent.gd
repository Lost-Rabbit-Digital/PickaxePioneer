class_name VelocityComponent
extends Node

# Handles physics-based movement for a CharacterBody2D

@export var max_speed: float = 300.0
@export var acceleration: float = 200.0
@export var friction: float = 300.0
@export var rotation_speed: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var rotation_direction: float = 0.0

func _ready() -> void:
	# Apply upgrades from GameManager
	max_speed = GameManager.get_max_speed()

func accelerate(direction: Vector2, delta: float) -> void:
	# Accelerate in the direction the body is facing
	var target_velocity = direction * max_speed
	velocity = velocity.move_toward(target_velocity, acceleration * delta)

func decelerate(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

func turn(direction: float, delta: float) -> float:
	return direction * rotation_speed * delta

func move(body: CharacterBody2D, delta: float) -> void:
	# Apply velocity to the body
	body.velocity = velocity
	body.move_and_slide()
