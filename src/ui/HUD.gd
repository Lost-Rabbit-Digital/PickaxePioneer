class_name HUD
extends CanvasLayer

# HUD — displays Scrap total (upper-left) and 3 heart squares (upper-right).

@onready var scrap_label: Label = $Control/ScrapLabel
@onready var health_container: HBoxContainer = $Control/HealthContainer

var health_squares: Array[ColorRect] = []

func _ready() -> void:
	EventBus.scrap_changed.connect(_on_scrap_changed)
	EventBus.player_health_changed.connect(_on_health_changed)

func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = "Scrap: %d" % amount

func _on_health_changed(current: int, max_hp: int) -> void:
	# Clear previous squares
	for square in health_squares:
		square.queue_free()
	health_squares.clear()

	# Rebuild squares (filled = red, lost = dark grey)
	for i in range(max_hp):
		var square := ColorRect.new()
		square.custom_minimum_size = Vector2(26, 26)
		square.color = Color(0.85, 0.08, 0.08, 1.0) if i < current else Color(0.25, 0.25, 0.25, 0.6)
		health_container.add_child(square)
		health_squares.append(square)
