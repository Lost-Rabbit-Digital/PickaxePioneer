extends CharacterBody2D

@export var speed = 300.0

func _ready():
	add_to_group("player")

func _physics_process(delta):
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()

func _on_mineral_collected(value):
	# Implement mineral collection logic here
	print("Mineral collected, increase XP/score: ", value)
	pass
