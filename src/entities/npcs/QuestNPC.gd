class_name QuestNPC
extends CharacterBody2D

@export var quest_item_scene: PackedScene
@export var quest_reward: int = 50

var quest_active: bool = false
var dialogue_label: Label
var item_names: Array[String] = [
	"Ancient Data Core",
	"Salvaged Power Cell",
	"Pre-War Relic",
	"Encrypted Module",
	"Mysterious Artifact"
]

func _ready() -> void:
	# Create dialogue label
	dialogue_label = Label.new()
	dialogue_label.position = Vector2(-60, -80)
	dialogue_label.size = Vector2(120, 40)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.3))
	dialogue_label.visible = false
	add_child(dialogue_label)
	
	# Connect interaction area
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	if not quest_active and QuestManager.active_quest.is_empty():
		dialogue_label.text = "[E] Talk"
		dialogue_label.visible = true
	elif quest_active and QuestManager.item_collected:
		dialogue_label.text = "[E] Complete"
		dialogue_label.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		dialogue_label.visible = false

func _process(_delta: float) -> void:
	if dialogue_label.visible and Input.is_action_just_pressed("ui_accept"):
		_interact()

func _interact() -> void:
	if not quest_active and QuestManager.active_quest.is_empty():
		_start_quest()
	elif quest_active and QuestManager.item_collected:
		_complete_quest()

func _start_quest() -> void:
	var item_name = item_names.pick_random()
	QuestManager.start_quest(self, item_name, quest_reward)
	quest_active = true
	dialogue_label.text = "Find: " + item_name
	
	# Spawn quest item at random location
	await get_tree().create_timer(0.5).timeout
	_spawn_quest_item()

func _spawn_quest_item() -> void:
	if not quest_item_scene:
		return
	
	var item = quest_item_scene.instantiate()
	var spawn_area = Rect2(-1500, -1000, 3000, 2000)
	var pos = Vector2(
		randf_range(spawn_area.position.x, spawn_area.end.x),
		randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	item.global_position = pos
	get_parent().add_child(item)

func _complete_quest() -> void:
	QuestManager.complete_quest()
	dialogue_label.text = "Thanks!"
	await get_tree().create_timer(1.0).timeout
	queue_free()
