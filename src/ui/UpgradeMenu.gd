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
var mineral_sense_cost: int = 75

var _sense_button: Button

# Gem socket buttons (one per upgrade track)
var _gem_label: Label
var _gem_carapace_button: Button
var _gem_legs_button: Button
var _gem_mandibles_button: Button
var _gem_sense_button: Button

var welcome_lines: Array[String] = [
	"Welcome back, space cat!",
	"Brought minerals from the asteroid belt?",
	"The Commander demands only the finest upgrades.",
	"No refunds — the station needs every mineral.",
	"That space pickaxe won't sharpen itself.",
	"Better jet boots, deeper sectors.",
	"Fresh spacesuit plating, just for you.",
	"The cosmos stretches ever further..."
]

func _ready() -> void:
	hull_button.pressed.connect(_on_carapace_pressed)
	engine_button.pressed.connect(_on_legs_pressed)
	drill_button.pressed.connect(_on_mandibles_pressed)

	# Dynamically add Mineral Sense (Sonar Ping) upgrade button
	_sense_button = Button.new()
	_sense_button.tooltip_text = "Teach your whiskers to sniff out ore from ridiculous distances."
	$Panel/VBoxContainer.add_child(_sense_button)
	_sense_button.pressed.connect(_on_mineral_sense_pressed)

	# Gem Socket section — separator label + 4 socket buttons
	_gem_label = Label.new()
	_gem_label.add_theme_color_override("font_color", Color(0.15, 0.85, 0.75))
	$Panel/VBoxContainer.add_child(_gem_label)

	_gem_carapace_button = Button.new()
	_gem_carapace_button.tooltip_text = "Slot a shiny gem into your spacesuit. Fashionable AND protective."
	$Panel/VBoxContainer.add_child(_gem_carapace_button)
	_gem_carapace_button.pressed.connect(_on_gem_carapace_pressed)

	_gem_legs_button = Button.new()
	_gem_legs_button.tooltip_text = "Gem-powered jet boots: now with 20% more zoom and 100% more style."
	$Panel/VBoxContainer.add_child(_gem_legs_button)
	_gem_legs_button.pressed.connect(_on_gem_legs_pressed)

	_gem_mandibles_button = Button.new()
	_gem_mandibles_button.tooltip_text = "A gem in your cargo hold? More space, more ore. Absolutely do it."
	$Panel/VBoxContainer.add_child(_gem_mandibles_button)
	_gem_mandibles_button.pressed.connect(_on_gem_mandibles_pressed)

	_gem_sense_button = Button.new()
	_gem_sense_button.tooltip_text = "Supercharge your whiskers. Feel ore deposits from the next sector over."
	$Panel/VBoxContainer.add_child(_gem_sense_button)
	_gem_sense_button.pressed.connect(_on_gem_sense_pressed)

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
	hull_button.text = "Reinforce Spacesuit Lv%d — Max HP: %d → %d (%d Minerals)" % [
		GameManager.carapace_level, current_hp, current_hp + 1, carapace_cost
	]

	var current_energy_cap := GameManager.get_max_energy()
	var current_speed := GameManager.get_max_speed()
	engine_button.text = "Upgrade Jet Boots Lv%d — Energy: %d→%d, Speed: %.0f→%.0f (%d Minerals)" % [
		GameManager.legs_level, current_energy_cap, current_energy_cap + 25,
		current_speed, current_speed + 30.0, legs_cost
	]

	var current_cap := GameManager.get_ore_capacity()
	drill_button.text = "Expand Cargo Hold Lv%d — Ore Capacity: %d → %d (%d Minerals)" % [
		GameManager.mandibles_level, current_cap, current_cap + 25, mandibles_cost
	]

	var sense_level := GameManager.mineral_sense_level
	var sense_radius := GameManager.get_sonar_ping_radius()
	var sense_radius_next := sense_radius + 3.0
	var sense_energy := GameManager.get_sonar_ping_energy_cost()
	var sense_energy_next := maxi(3, sense_energy - 2)
	_sense_button.text = "Tune Space Whiskers (Scanner) Lv%d — Radius: %.0f→%.0f tiles, Energy: %d→%d (%d Minerals)" % [
		sense_level, sense_radius, sense_radius_next, sense_energy, sense_energy_next, mineral_sense_cost
	]

	info_label.text = "Minerals: %d   |   Gems: %d" % [GameManager.mineral_currency, GameManager.gem_count]

	_gem_label.text = "--- Gem Sockets (cost: %d gems each) ---" % GameManager.GEM_SOCKET_COST

	if GameManager.carapace_gem_socketed:
		_gem_carapace_button.text = "[SOCKETED] Shield Gem — +1 Max HP"
		_gem_carapace_button.disabled = true
	else:
		_gem_carapace_button.text = "Socket Shield Gem into Spacesuit — +1 Max HP (%d Gems)" % GameManager.GEM_SOCKET_COST
		_gem_carapace_button.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

	if GameManager.legs_gem_socketed:
		_gem_legs_button.text = "[SOCKETED] Booster Gem — +25 Max Energy, +15 Speed"
		_gem_legs_button.disabled = true
	else:
		_gem_legs_button.text = "Socket Booster Gem into Jet Boots — +25 Energy, +15 Speed (%d Gems)" % GameManager.GEM_SOCKET_COST
		_gem_legs_button.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

	if GameManager.mandibles_gem_socketed:
		_gem_mandibles_button.text = "[SOCKETED] Cargo Gem — +25 Ore Capacity"
		_gem_mandibles_button.disabled = true
	else:
		_gem_mandibles_button.text = "Socket Cargo Gem into Cargo Hold — +25 Ore Capacity (%d Gems)" % GameManager.GEM_SOCKET_COST
		_gem_mandibles_button.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

	if GameManager.sense_gem_socketed:
		_gem_sense_button.text = "[SOCKETED] Sensor Gem — +3 Scanner Radius"
		_gem_sense_button.disabled = true
	else:
		_gem_sense_button.text = "Socket Sensor Gem into Whiskers — +3 Scanner Radius (%d Gems)" % GameManager.GEM_SOCKET_COST
		_gem_sense_button.disabled = GameManager.gem_count < GameManager.GEM_SOCKET_COST

func _on_carapace_pressed() -> void:
	if GameManager.mineral_currency >= carapace_cost:
		GameManager.mineral_currency -= carapace_cost
		GameManager.upgrade_carapace()
		SoundManager.play_purchase_confirm_sound()
		carapace_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_legs_pressed() -> void:
	if GameManager.mineral_currency >= legs_cost:
		GameManager.mineral_currency -= legs_cost
		GameManager.upgrade_legs()
		SoundManager.play_purchase_confirm_sound()
		legs_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_mandibles_pressed() -> void:
	if GameManager.mineral_currency >= mandibles_cost:
		GameManager.mineral_currency -= mandibles_cost
		GameManager.upgrade_mandibles()
		SoundManager.play_purchase_confirm_sound()
		mandibles_cost += 25
		GameManager.save_game()
		_update_ui()

func _on_mineral_sense_pressed() -> void:
	if GameManager.mineral_currency >= mineral_sense_cost:
		GameManager.mineral_currency -= mineral_sense_cost
		GameManager.upgrade_mineral_sense()
		SoundManager.play_purchase_confirm_sound()
		mineral_sense_cost += 50
		GameManager.save_game()
		_update_ui()

func _on_gem_carapace_pressed() -> void:
	if not GameManager.carapace_gem_socketed and GameManager.gem_count >= GameManager.GEM_SOCKET_COST:
		GameManager.gem_count -= GameManager.GEM_SOCKET_COST
		GameManager.carapace_gem_socketed = true
		SoundManager.play_purchase_confirm_sound()
		GameManager.save_game()
		_update_ui()

func _on_gem_legs_pressed() -> void:
	if not GameManager.legs_gem_socketed and GameManager.gem_count >= GameManager.GEM_SOCKET_COST:
		GameManager.gem_count -= GameManager.GEM_SOCKET_COST
		GameManager.legs_gem_socketed = true
		SoundManager.play_purchase_confirm_sound()
		GameManager.save_game()
		_update_ui()

func _on_gem_mandibles_pressed() -> void:
	if not GameManager.mandibles_gem_socketed and GameManager.gem_count >= GameManager.GEM_SOCKET_COST:
		GameManager.gem_count -= GameManager.GEM_SOCKET_COST
		GameManager.mandibles_gem_socketed = true
		SoundManager.play_purchase_confirm_sound()
		GameManager.save_game()
		_update_ui()

func _on_gem_sense_pressed() -> void:
	if not GameManager.sense_gem_socketed and GameManager.gem_count >= GameManager.GEM_SOCKET_COST:
		GameManager.gem_count -= GameManager.GEM_SOCKET_COST
		GameManager.sense_gem_socketed = true
		SoundManager.play_purchase_confirm_sound()
		GameManager.save_game()
		_update_ui()
