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
	var current_hp := GameManager.get_max_health()
	hull_button.text = "Harden Carapace Lv%d — Max HP: %d → %d (%d Minerals)" % [
		GameManager.carapace_level, current_hp, current_hp + 1, carapace_cost
	]

	var current_speed := int(GameManager.get_max_speed())
	engine_button.text = "Strengthen Legs Lv%d — Speed: %d → %d (%d Minerals)" % [
		GameManager.legs_level, current_speed, current_speed + 30, legs_cost
	]

	var current_power := GameManager.get_mandibles_power()
	drill_button.text = "Sharpen Mandibles Lv%d — Mining Power: %d → %d (%d Minerals)" % [
		GameManager.mandibles_level, current_power, current_power + 3, mandibles_cost
	]

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
