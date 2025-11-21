class_name ChatterManager
extends Node

@export var chat_bubble_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(100, 100, 1080, 520)
@export var min_interval: float = 0.5
@export var max_interval: float = 1.5

var timer: Timer
var messages: Array[String] = [
	# Flavor
	"Nice haul!",
	"Need more scrap...",
	"The wastes are dangerous.",
	"Seen any drones?",
	"My ship needs fixing.",
	"Prices are going up.",
	"Stay safe out there.",
	"Found some gold yesterday!",
	"Watch out for mutants.",
	"Engine's acting up again.",
	"I miss the old days.",
	"Who builds these things?",
	"My radar is jamming.",
	"Anyone got a spare battery?",
	"This coffee is cold.",
	"Just one more run...",
	"Did you hear that noise?",
	"Scanning for signals...",
	"Back to the grind.",
	"Hope the payout is good.",
	
	# Tips
	"Don't touch the mutants!",
	"You have to extract to keep your loot.",
	"Buy upgrades to survive longer.",
	"The extraction zone is your only way out.",
	"Watch your hull integrity!",
	"Lasers mine faster with upgrades.",
	"Engines help you outrun trouble.",
	"Scrap is life out here.",
	"Don't get greedy, get out alive.",
	"Map nodes have different resources.",
	
	# Lore
	"The Company doesn't care about us.",
	"Is Earth really gone?",
	"They say there's a vault nearby.",
	"I saw a ghost ship yesterday.",
	"The mutants are evolving."
]

func _ready() -> void:
	if spawn_area.size == Vector2.ZERO:
		var vp_size = get_viewport().get_visible_rect().size
		spawn_area = Rect2(50, 50, vp_size.x - 100, vp_size.y - 100)
		print("ChatterManager: Spawn area was empty, defaulted to: ", spawn_area)
	else:
		print("ChatterManager: Spawn area initialized to: ", spawn_area)

	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_spawn_chat)
	_start_timer()

func _start_timer() -> void:
	timer.wait_time = randf_range(min_interval, max_interval)
	timer.start()

func _spawn_chat() -> void:
	if not chat_bubble_scene:
		return
		
	var bubble = chat_bubble_scene.instantiate()
	var pos = _get_valid_spawn_position()
	bubble.position = pos
	bubble.set_text(messages.pick_random())
	add_child(bubble)
	
	_start_timer()

func _get_valid_spawn_position() -> Vector2:
	var viewport_rect = get_viewport().get_visible_rect()
	var margin = 50.0
	var safe_area = viewport_rect.grow(-margin)
	
	var center = viewport_rect.size / 2
	var exclusion_size = Vector2(500, 400) # Larger exclusion for safety
	var exclusion_rect = Rect2(center - exclusion_size / 2, exclusion_size)
	
	var pos = Vector2.ZERO
	var valid = false
	var attempts = 0
	
	while not valid and attempts < 20:
		pos = Vector2(
			randf_range(safe_area.position.x, safe_area.end.x),
			randf_range(safe_area.position.y, safe_area.end.y)
		)
		if not exclusion_rect.has_point(pos):
			valid = true
		attempts += 1
	
	# If we failed to find a spot, just pick a random edge
	if not valid:
		pos = Vector2(randf_range(safe_area.position.x, safe_area.end.x), margin)
		
	return pos
