class_name FarmAnimalNPC
extends Node2D

@export var animal_name: String = "Animal"
@export var texture: Texture2D:
	set(value):
		texture = value
		if is_node_ready() and $Sprite2D:
			$Sprite2D.texture = value

var _wiggle_tween: Tween

func _ready() -> void:
	if texture and $Sprite2D:
		$Sprite2D.texture = texture
	texture_filter = TEXTURE_FILTER_NEAREST

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
