class_name UpgradeMenu
extends Control

@onready var hull_button: Button = $Panel/VBoxContainer/HullButton
@onready var engine_button: Button = $Panel/VBoxContainer/EngineButton
@onready var drill_button: Button = $Panel/VBoxContainer/DrillButton
@onready var info_label: Label = $Panel/InfoLabel
@onready var dialogue_label: Label = $Panel/Shopkeeper/DialogueLabel

var carapace_cost: int = 50
var legs_cost: int = 50
var mandibles_cost: int = 50

var welcome_lines: Array[String] = [
	"Welcome back, worker!",
	"Brought minerals from the deep?",
	"The Queen demands only the finest upgrades.",
	"No refunds — the colony needs every mineral.",
	"These mandibles won't sharpen themselves.",
	"Stronger legs, deeper mines.",
	"Fresh chitin plating, just for you.",
	"The tunnels go ever deeper..."
]

func _ready() -> void:
	hull_button.pressed.connect(_on_carapace_pressed)
	engine_button.pressed.connect(_on_legs_pressed)
	drill_button.pressed.connect(_on_mandibles_pressed)
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
	hull_button.text = "Harden Carapace Lv%d (%d Minerals)" % [GameManager.carapace_level, carapace_cost]
	engine_button.text = "Strengthen Legs Lv%d (%d Minerals)" % [GameManager.legs_level, legs_cost]
	drill_button.text = "Sharpen Mandibles Lv%d (%d Minerals)" % [GameManager.mandibles_level, mandibles_cost]
	info_label.text = "Minerals: %d" % GameManager.mineral_currency

func _on_carapace_pressed() -> void:
	if GameManager.mineral_currency >= carapace_cost:
		GameManager.mineral_currency -= carapace_cost
		GameManager.upgrade_carapace()
		carapace_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_legs_pressed() -> void:
	if GameManager.mineral_currency >= legs_cost:
		GameManager.mineral_currency -= legs_cost
		GameManager.upgrade_legs()
		legs_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_mandibles_pressed() -> void:
	if GameManager.mineral_currency >= mandibles_cost:
		GameManager.mineral_currency -= mandibles_cost
		GameManager.upgrade_mandibles()
		mandibles_cost += 25
		GameManager.save_game()
		_update_ui()
