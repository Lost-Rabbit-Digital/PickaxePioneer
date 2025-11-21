class_name HurtboxComponent
extends Area2D

# Component to detect incoming damage

@export var health_component: HealthComponent

signal hit(damage: int)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	# We expect the other area to be a HitboxComponent
	if area is HitboxComponent:
		take_damage(area.damage)
		area.on_hit()

func take_damage(amount: int) -> void:
	if health_component:
		health_component.damage(amount)
	emit_signal("hit", amount)
