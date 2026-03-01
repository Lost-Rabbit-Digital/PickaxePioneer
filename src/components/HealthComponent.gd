class_name HealthComponent
extends Node

# Reusable Health Component

@export var max_health: int = 100
var current_health: float

signal health_changed(new_health: float, max_health: int)
signal died

func _ready() -> void:
	# Apply upgrades from GameManager
	max_health = GameManager.get_max_health()
	current_health = float(max_health)
	emit_signal("health_changed", current_health, max_health)

func damage(amount: float) -> void:
	current_health = maxf(0.0, current_health - amount)
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0.0:
		emit_signal("died")

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	emit_signal("health_changed", current_health, max_health)
