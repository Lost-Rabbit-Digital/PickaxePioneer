class_name HitboxComponent
extends Area2D

# Component to deal damage

@export var damage: int = 10

func _ready() -> void:
	# Apply upgrades from GameManager
	damage = GameManager.get_drill_damage()

func on_hit() -> void:
	# Optional: Destroy projectile on hit, play sound, etc.
	pass
