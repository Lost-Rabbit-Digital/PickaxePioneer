class_name Mutant
extends CharacterBody2D

@export var speed: float = 100.0
@export var wander_interval: float = 2.0
@export var health: int = 30

var direction: Vector2 = Vector2.ZERO
var timer: Timer

func _ready() -> void:
	timer = Timer.new()
	timer.wait_time = wander_interval
	timer.timeout.connect(_change_direction)
	add_child(timer)
	timer.start()
	_change_direction()
	
	# Connect collision for player damage
	$Area2D.body_entered.connect(_on_body_entered)
	# Connect area detection for laser hits
	$Area2D.area_entered.connect(_on_area_entered)

func _change_direction() -> void:
	direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()

func _physics_process(delta: float) -> void:
	velocity = direction * speed
	move_and_slide()
	
	# Optional: Bounce off walls (if using CharacterBody2D collision)
	if is_on_wall():
		direction = get_wall_normal()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		print("Player hit by Mutant! Run Lost!")
		GameManager.lose_run()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "MiningLaser":
		take_damage(10)
		_spawn_blood_particles()
		# Push back from laser
		var knockback = global_position.direction_to(area.global_position) * -200
		velocity = knockback

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_spawn_blood_particles()
		queue_free()

func _spawn_blood_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.8
	particles.amount = 15
	particles.lifetime = 0.4
	particles.speed_scale = 1.5
	
	# Blood-like appearance
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2(0, 300)
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 150.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color(0.7, 0.1, 0.1, 0.9)  # Dark red blood
	
	get_parent().add_child(particles)
	
	# Auto-cleanup
	await get_tree().create_timer(0.8).timeout
	particles.queue_free()
