class_name HUD
extends CanvasLayer

# HUD to display game info

@onready var scrap_label: Label = $Control/ScrapLabel
@onready var health_container: HBoxContainer = $Control/HealthContainer

var health_squares: Array[ColorRect] = []

func _ready() -> void:
	EventBus.scrap_changed.connect(_on_scrap_changed)
	EventBus.player_health_changed.connect(_on_health_changed)

func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = "Scrap: %d" % amount

func _on_health_changed(current: int, max_hp: int) -> void:
	# Clear old squares
	for square in health_squares:
		square.queue_free()
	health_squares.clear()

	# Create squares for max health
	for i in range(max_hp):
		var square = ColorRect.new()
		square.custom_minimum_size = Vector2(24, 24)
		if i < current:
			square.color = Color(0.8, 0.1, 0.1, 1.0) # Red = filled health
		else:
			square.color = Color(0.3, 0.3, 0.3, 0.5) # Dark grey = lost health
		health_container.add_child(square)
		health_squares.append(square)
