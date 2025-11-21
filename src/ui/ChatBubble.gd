class_name ChatBubble
extends Control

@onready var label: Label = $Panel/Label
func _ready() -> void:
	modulate.a = 0.0
	
	# Float up
	var move_tween = create_tween()
	move_tween.tween_property(self, "position:y", position.y - 50.0, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	# Fade in and out
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, 0.5)
	fade_tween.tween_interval(3.5)
	fade_tween.tween_property(self, "modulate:a", 0.0, 1.0)
	
	await fade_tween.finished
	queue_free()

func set_text(text: String) -> void:
	$Panel/Label.text = text
