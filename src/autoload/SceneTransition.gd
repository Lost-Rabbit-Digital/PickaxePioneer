extends CanvasLayer

# SceneTransition
# Handles fade to black transitions between scenes

@onready var color_rect: ColorRect = $ColorRect
var is_transitioning: bool = false

func _ready() -> void:
	# Start transparent
	color_rect.modulate.a = 0.0
	process_mode = Node.PROCESS_MODE_ALWAYS

func fade_to_black(duration: float = 0.5) -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_from_black(duration: float = 0.5) -> void:
	var tween = create_tween()
	tween.tween_property(color_rect, "modulate:a", 0.0, duration)
	await tween.finished
	is_transitioning = false

func transition(duration: float = 0.5) -> void:
	await fade_to_black(duration)
	await get_tree().create_timer(0.1).timeout  # Brief pause at black
	await fade_from_black(duration)
