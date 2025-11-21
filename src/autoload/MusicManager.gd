extends Node

# MusicManager
# Handles music playback with crossfading between scenes

var current_player: AudioStreamPlayer
var next_player: AudioStreamPlayer
var fade_duration: float = 1.5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_music(stream: AudioStream) -> void:
	# If same music is already playing, do nothing
	if current_player and current_player.stream == stream and current_player.playing:
		return
	
	# Create new player for next track
	next_player = AudioStreamPlayer.new()
	next_player.stream = stream
	next_player.bus = &"Music"
	next_player.volume_db = -80.0  # Start silent
	add_child(next_player)
	next_player.play()
	
	# Crossfade
	var tween = create_tween()
	tween.set_parallel(true)
	
	if current_player:
		tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
	
	tween.tween_property(next_player, "volume_db", 0.0, fade_duration)
	
	await tween.finished
	
	# Clean up old player
	if current_player:
		current_player.queue_free()
	
	current_player = next_player
	next_player = null

func stop_music() -> void:
	if current_player:
		var tween = create_tween()
		tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
		await tween.finished
		current_player.queue_free()
		current_player = null
