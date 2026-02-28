class_name FarmAnimalNPC
extends Node2D

@export var animal_name: String = "Animal"
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready() and $Sprite2D:
			$Sprite2D.texture = value

const _CAT_REACTIONS: Dictionary = {
	"Chicken": [
		"You eye the chicken. It runs. You resist... for now.",
		"The chicken squawks nervously. Good.",
		"Your tail flicks. The chicken backs away.",
	],
	"Sheep": [
		"Warm. Fluffy. You briefly consider curling up on it.",
		"You head-butt the sheep. It blinks. You blink. Respect.",
		"It smells like wool. You decide it is acceptable.",
	],
	"Pig": [
		"The pig snorts at you. Bold move.",
		"You sniff the pig. It sniffs back. Complicated.",
		"You are unsure about the pig. The pig is unsure about you.",
	],
}

var _wiggle_tween: Tween

# Bouncing movement
var velocity: Vector2 = Vector2.ZERO
var bounce_left: float = 64.0
var bounce_right: float = 1216.0
var _base_y: float = 0.0
var _bounce_time: float = 0.0
const BOUNCE_HEIGHT: float = 8.0
const BOUNCE_FREQ: float = 3.0
const ANIM_SPEED: float = 0.2
var _anim_timer: float = 0.0

func _ready() -> void:
	var spr := $Sprite2D as Sprite2D
	if texture and spr:
		spr.texture = texture
		spr.hframes = 2
		spr.frame = 0
	texture_filter = TEXTURE_FILTER_NEAREST
	_base_y = position.y

func _process(delta: float) -> void:
	var spr := $Sprite2D as Sprite2D
	if not spr or velocity == Vector2.ZERO:
		return

	# Move horizontally and bounce at bounds
	position.x += velocity.x * delta
	if position.x <= bounce_left:
		position.x = bounce_left
		velocity.x = abs(velocity.x)
	elif position.x >= bounce_right:
		position.x = bounce_right
		velocity.x = -abs(velocity.x)

	# Flip sprite to face direction of travel
	spr.flip_h = velocity.x < 0

	# Vertical hop using sine wave (abs keeps it always upward)
	_bounce_time += delta
	position.y = _base_y - abs(sin(_bounce_time * BOUNCE_FREQ * PI)) * BOUNCE_HEIGHT

	# Cycle walk frames
	_anim_timer += delta
	if _anim_timer >= ANIM_SPEED:
		_anim_timer -= ANIM_SPEED
		spr.frame = (spr.frame + 1) % 2

## Returns a cat-themed reaction line for this animal type.
func get_pet_message() -> String:
	var options: Array = _CAT_REACTIONS.get(animal_name, ["You pat the %s." % animal_name])
	return options[randi() % options.size()]

func wiggle() -> void:
	if _wiggle_tween and _wiggle_tween.is_running():
		return
	if _wiggle_tween:
		_wiggle_tween.kill()
	_wiggle_tween = create_tween()
	_wiggle_tween.tween_property(self, "rotation_degrees", 14.0, 0.07)
	_wiggle_tween.tween_property(self, "rotation_degrees", -14.0, 0.07)
	_wiggle_tween.tween_property(self, "rotation_degrees", 10.0, 0.06)
	_wiggle_tween.tween_property(self, "rotation_degrees", -10.0, 0.06)
	_wiggle_tween.tween_property(self, "rotation_degrees", 5.0, 0.05)
	_wiggle_tween.tween_property(self, "rotation_degrees", 0.0, 0.05)
