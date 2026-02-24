class_name PlayerProbe
extends Node

# Lightweight player entity for the grid-based mining level.
# Movement is handled by MiningLevel; this node manages health and signals.

@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	add_to_group("player")
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	# Re-emit initial state (HealthComponent fires during its own _ready, before our signal connects)
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)

func take_damage(amount: int) -> void:
	health_component.damage(amount)

func _on_health_changed(current: int, max_hp: int) -> void:
	EventBus.player_health_changed.emit(current, max_hp)

func _on_died() -> void:
	GameManager.lose_run()
