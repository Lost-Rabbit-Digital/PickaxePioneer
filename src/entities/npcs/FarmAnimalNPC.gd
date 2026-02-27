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

func _ready() -> void:
	if texture and $Sprite2D:
		$Sprite2D.texture = texture
	texture_filter = TEXTURE_FILTER_NEAREST

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
