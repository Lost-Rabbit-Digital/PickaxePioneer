class_name HUD
extends CanvasLayer

# HUD — displays Minerals total (upper-left), health squares and fuel gauge (upper-right).

@onready var scrap_label: Label = $Control/ScrapLabel
@onready var health_container: HBoxContainer = $Control/HealthContainer
@onready var fuel_label: Label = $Control/FuelLabel
@onready var fuel_bar_container: HBoxContainer = $Control/FuelBarContainer

var health_squares: Array[ColorRect] = []
var fuel_segments: Array[ColorRect] = []

var scrap_panel: ColorRect
var earnings_label: Label
var _earnings_tween: Tween

func _ready() -> void:
	EventBus.minerals_changed.connect(_on_minerals_changed)
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.fuel_changed.connect(_on_fuel_changed)
	EventBus.minerals_earned.connect(_on_minerals_earned)
	# Initialize hearts immediately since PlayerProbe emits before HUD connects
	var max_hp := GameManager.get_max_health()
	_on_health_changed(max_hp, max_hp)
	# Initialize fuel
	_on_fuel_changed(GameManager.current_fuel, GameManager.max_fuel)

	# Semi-transparent black background panel behind the minerals label
	scrap_panel = ColorRect.new()
	scrap_panel.color = Color(0.0, 0.0, 0.0, 0.55)
	scrap_panel.position = Vector2(8, 8)
	scrap_panel.size = Vector2(148, 34)
	scrap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$Control.add_child(scrap_panel)
	$Control.move_child(scrap_panel, 0)  # Draw behind everything else

	# Earnings popup label — appears below the minerals panel when a tile is mined
	earnings_label = Label.new()
	earnings_label.position = Vector2(16, 46)
	earnings_label.custom_minimum_size = Vector2(148, 22)
	earnings_label.modulate = Color(1.0, 0.88, 0.2, 0.0)  # Gold, starts invisible
	$Control.add_child(earnings_label)

func _on_minerals_changed(amount: int) -> void:
	scrap_label.text = "Minerals: %d" % amount

func _on_minerals_earned(amount: int) -> void:
	earnings_label.text = "+%d" % amount
	earnings_label.modulate = Color(1.0, 0.88, 0.2, 1.0)

	if _earnings_tween:
		_earnings_tween.kill()
	_earnings_tween = create_tween()
	_earnings_tween.tween_interval(0.8)
	_earnings_tween.tween_property(earnings_label, "modulate:a", 0.0, 0.45)

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
