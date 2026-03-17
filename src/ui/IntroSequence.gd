class_name IntroSequence
extends CanvasLayer

## Skippable narrative intro — 3-4 text cards establishing the mining cat fantasy.
## Shown once on first new game before the overworld loads.
## Press any key or click to advance; hold to skip entirely.

signal finished

const CARDS: Array[String] = [
	"Your father never came back from the frontier.\nHe left you his ship, his routes...\nand a debt to the Clowder you didn't ask for.",
	"The Clowder always collects.\nFourteen days.\nNot a moment more.",
	"Somewhere out there, ore waits in the dark.\nMine it. Sell it. Survive.\nThe rest you'll figure out.",
]

const FADE_IN_TIME: float = 0.8
const HOLD_TIME: float = 4.5
const FADE_OUT_TIME: float = 0.5

var _current_card: int = -1
var _label: Label
var _bg: ColorRect
var _skip_label: Label
var _tween: Tween
var _advancing: bool = false

func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS

	_bg = ColorRect.new()
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.02, 0.02, 0.06, 1.0)
	add_child(_bg)

	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_label.custom_minimum_size = Vector2(900, 200)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.55))
	_label.modulate.a = 0.0
	add_child(_label)

	_skip_label = Label.new()
	_skip_label.text = "Press any key to advance  |  ESC to skip"
	_skip_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_skip_label.offset_top = -40
	_skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skip_label.add_theme_font_size_override("font_size", 14)
	_skip_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.6))
	add_child(_skip_label)

	_advance_card()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		return
	if event.is_pressed():
		if event.is_action_pressed("ui_cancel"):
			_skip_all()
		else:
			if _tween:
				_tween.kill()
			_advancing = false
			_advance_card()
		get_viewport().set_input_as_handled()

func _advance_card() -> void:
	if _advancing:
		return
	_advancing = true

	if _tween:
		_tween.kill()

	_current_card += 1
	if _current_card >= CARDS.size():
		_finish()
		return

	_label.text = CARDS[_current_card]

	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, FADE_IN_TIME)
	_tween.tween_interval(HOLD_TIME)
	_tween.tween_property(_label, "modulate:a", 0.0, FADE_OUT_TIME)
	_tween.tween_callback(func() -> void:
		_advancing = false
		_advance_card()
	)

func _skip_all() -> void:
	if _tween:
		_tween.kill()
	_finish()

func _finish() -> void:
	if _tween:
		_tween.kill()
	# Fade out only the text; keep _bg opaque so the screen stays black.
	# GameManager will take over with SceneTransition and fade from black.
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 0.0, 0.3)
	_tween.tween_callback(func() -> void:
		finished.emit()
		queue_free()
	)
