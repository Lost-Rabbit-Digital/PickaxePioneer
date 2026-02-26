class_name PlayerProbe
extends Node

# Lightweight player entity for the grid-based mining level.
# Movement is handled by MiningLevel; this node manages health and signals.

@onready var health_component: HealthComponent = $HealthComponent
@onready var interact_prompt: Label = $PromptLayer/InteractPrompt

func show_prompt(text: String) -> void:
	interact_prompt.text = text
	interact_prompt.visible = true

func hide_prompt() -> void:
	interact_prompt.visible = false

func set_prompt_position(screen_pos: Vector2) -> void:
	var sz := interact_prompt.size
	if sz.x < 1.0:
		sz = Vector2(320.0, 32.0)
	interact_prompt.position = Vector2(screen_pos.x - sz.x * 0.5, screen_pos.y - sz.y - 4.0)

func _ready() -> void:
	add_to_group("player")
	health_component.health_changed.connect(_on_health_changed)
	health_component.died.connect(_on_died)
	# Re-emit initial state (HealthComponent fires during its own _ready, before our signal connects)
	EventBus.player_health_changed.emit(health_component.current_health, health_component.max_health)

func take_damage(amount: int) -> void:
	health_component.damage(amount)

func heal(amount: int) -> void:
	health_component.heal(amount)

func is_at_max_health() -> bool:
	return health_component.current_health >= health_component.max_health

func _on_health_changed(current: int, max_hp: int) -> void:
	EventBus.player_health_changed.emit(current, max_hp)

func _on_died() -> void:
	# Emit signal so MiningLevel can show a death overlay before transitioning
	EventBus.player_died.emit()
