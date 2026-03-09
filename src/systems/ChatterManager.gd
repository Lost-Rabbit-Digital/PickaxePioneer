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
	"The clowder needs more minerals...",
	"The deep tunnels are dangerous.",
	"Seen any rats down there?",
	"My claws are getting dull.",
	"Gem prices are going up.",
	"Stay safe in the tunnels.",
	"Found gold ore yesterday!",
	"Watch out for lava flows.",
	"My paws are killing me.",
	"I miss the upper galleries.",
	"Who digs these side tunnels?",
	"My whiskers are tingling...",
	"Anyone got a spare energy cell?",
	"The Matriarch wants more.",
	"Just one more run...",
	"Did you hear that rumbling?",
	"Sensing mineral veins ahead...",
	"Back to the digging.",
	"Hope the deposit is rich.",
	"Curiosity didn't kill this cat...",
	"Nine lives, but I'd rather not use them.",
	"Keep your claws sharp, your whiskers sharper.",

	# Tips
	"Don't step on lava!",
	"You have to surface to keep your minerals.",
	"Thicken your pelt to survive longer.",
	"The exit station is your only way out.",
	"Watch your pelt integrity!",
	"Sharper claws dig faster.",
	"Stronger paws let you dig deeper.",
	"Minerals are life out here.",
	"Don't get greedy, get out alive.",
	"Different mines have different ore richness.",

	# Lore
	"The clowder grows ever deeper.",
	"How far does the earth go?",
	"They say there's a gem vein nearby.",
	"I found a strange crystal yesterday.",
	"The deep rocks are shifting.",
	"My paws were made for digging.",
	"Ancient tunnels... something old lives down here.",
	"The Matriarch's whiskers never lie.",
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
