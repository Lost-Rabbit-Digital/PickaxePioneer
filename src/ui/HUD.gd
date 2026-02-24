class_name HUD
extends CanvasLayer

# HUD — displays Scrap total (upper-left), health squares and fuel gauge (upper-right).

@onready var scrap_label: Label = $Control/ScrapLabel
@onready var health_container: HBoxContainer = $Control/HealthContainer
@onready var fuel_label: Label = $Control/FuelLabel
@onready var fuel_bar_container: HBoxContainer = $Control/FuelBarContainer

var health_squares: Array[ColorRect] = []
var fuel_segments: Array[ColorRect] = []

func _ready() -> void:
	EventBus.scrap_changed.connect(_on_scrap_changed)
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.fuel_changed.connect(_on_fuel_changed)
	# Initialize hearts immediately since PlayerProbe emits before HUD connects
	var max_hp := GameManager.get_max_health()
	_on_health_changed(max_hp, max_hp)
	# Initialize fuel
	_on_fuel_changed(GameManager.current_fuel, GameManager.max_fuel)

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

func _on_fuel_changed(current_fuel: int, max_fuel: int) -> void:
	fuel_label.text = "Fuel: %d/%d" % [current_fuel, max_fuel]

	# Clear previous segments
	for segment in fuel_segments:
		segment.queue_free()
	fuel_segments.clear()

	# Create fuel bar with 10 segments (each represents 10 fuel)
	var segments = 10
	for i in range(segments):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(20, 20)
		# Yellow/green gradient: full = green, empty = dark
		var filled = i < (current_fuel / 10)
		segment.color = Color(0.20, 0.80, 0.20, 1.0) if filled else Color(0.25, 0.25, 0.25, 0.6)
		fuel_bar_container.add_child(segment)
		fuel_segments.append(segment)
