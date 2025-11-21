class_name ScrapPile
extends RigidBody2D

# Scrap Pile Entity (formerly Asteroid)

@onready var health_component: HealthComponent = $HealthComponent

var loot_scene = preload("res://src/entities/loot/ScrapLoot.tscn")

func _ready() -> void:
	health_component.died.connect(_on_died)

func _on_died() -> void:
	SoundManager.play_explosion_sound()
	_spawn_particles()
	_spawn_loot()
	queue_free()

func _spawn_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.position = position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 20
	particles.lifetime = 0.5
	particles.speed_scale = 2.0
	
	# Dust-like appearance
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.scale_amount_min = 3.0
	particles.scale_amount_max = 6.0
	particles.color = Color(0.6, 0.5, 0.4, 0.8)  # Dusty brown
	
	get_parent().add_child(particles)
	
	# Auto-cleanup
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func _spawn_loot() -> void:
	# Spawn loot
	var loot_count = randi_range(2, 5)
	for i in range(loot_count):
		var loot = loot_scene.instantiate()
		loot.position = position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().call_deferred("add_child", loot)
