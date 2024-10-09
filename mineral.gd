extends Area2D

@export var speed = 50.0
@export var value = 1

var player: CharacterBody2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(delta):
	if player:
		var direction = (player.global_position - global_position).normalized()
		position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player"):
		body._on_mineral_collected(value)
		queue_free()
