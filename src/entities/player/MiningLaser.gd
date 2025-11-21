class_name MiningLaser
extends Area2D

# Mining Laser Projectile

@export var speed: float = 600.0
@export var lifetime: float = 2.0

var direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	rotation = direction.angle() + PI / 2
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_area_entered(area: Area2D) -> void:
	# Hit a mutant's Area2D
	if area.get_parent() is Mutant:
		area.get_parent().take_damage(GameManager.get_laser_damage())
		queue_free()
	elif area is HurtboxComponent:
		area.take_damage(GameManager.get_laser_damage())
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body is Mutant:
		body.take_damage(GameManager.get_laser_damage())
	# Hit a scrap pile or wall or mutant
	queue_free()
