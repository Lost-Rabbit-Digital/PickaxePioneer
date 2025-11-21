class_name QuestItem
extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Add pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property($Sprite2D, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property($Sprite2D, "scale", Vector2(1.0, 1.0), 0.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	QuestManager.collect_item()
	SoundManager.play_pickup_sound()
	
	# Particle effect
	var particles = CPUParticles2D.new()
	particles.position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, 100)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(1.0, 0.9, 0.3, 0.9)
	
	get_parent().add_child(particles)
	
	queue_free()
