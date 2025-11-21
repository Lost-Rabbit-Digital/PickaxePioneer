class_name UpgradeMenu
extends Control

@onready var hull_button: Button = $Panel/VBoxContainer/HullButton
@onready var engine_button: Button = $Panel/VBoxContainer/EngineButton
@onready var laser_button: Button = $Panel/VBoxContainer/LaserButton
@onready var info_label: Label = $Panel/InfoLabel
@onready var dialogue_label: Label = $Panel/Shopkeeper/DialogueLabel

var hull_cost: int = 50
var engine_cost: int = 50
var laser_cost: int = 50

var welcome_lines: Array[String] = [
	"Welcome, traveler!",
	"Got some scrap?",
	"Finest upgrades this side of the belt.",
	"No refunds!",
	"Keep your hands where I can see 'em.",
	"Need a new engine?",
	"Fresh parts, just for you.",
	"Don't let the mutants bite."
]

func _ready() -> void:
	hull_button.pressed.connect(_on_hull_pressed)
	engine_button.pressed.connect(_on_engine_pressed)
	laser_button.pressed.connect(_on_laser_pressed)
	_update_ui()
	
	# Rotate dialogue
	_update_dialogue()
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0
	timer.timeout.connect(_update_dialogue)
	timer.start()

func _update_dialogue() -> void:
	dialogue_label.text = welcome_lines.pick_random()

func _update_ui() -> void:
	hull_button.text = "Upgrade Hull Lv%d (%d Scrap)" % [GameManager.hull_level, hull_cost]
	engine_button.text = "Upgrade Engine Lv%d (%d Scrap)" % [GameManager.engine_level, engine_cost]
	laser_button.text = "Upgrade Laser Lv%d (%d Scrap)" % [GameManager.laser_level, laser_cost]
	info_label.text = "Current Scrap: %d" % GameManager.scrap_currency

func _on_hull_pressed() -> void:
	if GameManager.scrap_currency >= hull_cost:
		GameManager.scrap_currency -= hull_cost
		GameManager.upgrade_hull()
		hull_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_engine_pressed() -> void:
	if GameManager.scrap_currency >= engine_cost:
		GameManager.scrap_currency -= engine_cost
		GameManager.upgrade_engine()
		engine_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_laser_pressed() -> void:
	if GameManager.scrap_currency >= laser_cost:
		GameManager.scrap_currency -= laser_cost
		GameManager.upgrade_laser()
		laser_cost += 25
		GameManager.save_game()
		_update_ui()
