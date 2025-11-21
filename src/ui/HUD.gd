class_name HUD
extends CanvasLayer

# HUD to display game info

@onready var scrap_label: Label = $Control/ScrapLabel
@onready var health_bar: ProgressBar = $Control/HealthBar

func _ready() -> void:
	EventBus.scrap_changed.connect(_on_scrap_changed)
	EventBus.player_health_changed.connect(_on_health_changed)
	# Removed ReturnButton connection as it's being removed

func _on_scrap_changed(amount: int) -> void:
	scrap_label.text = "Scrap: %d" % amount

func _on_health_changed(current: int, max_hp: int) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current
