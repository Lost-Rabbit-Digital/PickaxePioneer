class_name Asteroid
extends RigidBody2D

# Asteroid Entity

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	health_component.died.connect(_on_died)

func _on_died() -> void:
	# Spawn ore chunks here (TODO)
	EventBus.ore_mined.emit("Iron", 1) # Placeholder
	queue_free()
