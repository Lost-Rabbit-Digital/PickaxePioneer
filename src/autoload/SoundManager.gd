extends Node

# SoundManager
# Generates and plays procedural sounds

var sample_rate = 44100.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_pickup_sound() -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.1
	player.stream = stream
	player.play()
	
	var playback = player.get_stream_playback()
	_fill_pickup_buffer(playback)
	
	await get_tree().create_timer(0.2).timeout
	player.queue_free()

func play_laser_sound() -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.1
	player.stream = stream
	player.volume_db = -10.0
	player.play()
	
	var playback = player.get_stream_playback()
	_fill_laser_buffer(playback)
	
	await get_tree().create_timer(0.2).timeout
	player.queue_free()

func play_explosion_sound() -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)
	
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.5
	player.stream = stream
	player.volume_db = -5.0
	player.play()
	
	var playback = player.get_stream_playback()
	_fill_explosion_buffer(playback)
	
	await get_tree().create_timer(0.6).timeout
	player.queue_free()

func _fill_pickup_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var phase = 0.0
	var frames = playback.get_frames_available()
	
	for i in range(frames):
		var t = float(i) / sample_rate
		# Simple high-pitched sine wave "ding"
		var freq = 880.0 + (t * 1000.0) # Slide up
		var increment = freq / sample_rate
		phase = fmod(phase + increment, 1.0)
		var sample = Vector2.ONE * sin(phase * TAU) * 0.5 * (1.0 - t * 10.0) # Decay
		playback.push_frame(sample)

func _fill_laser_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var phase = 0.0
	var frames = playback.get_frames_available()
	
	for i in range(frames):
		var t = float(i) / sample_rate
		# Square wave with pitch drop
		var freq = 800.0 - (t * 2000.0)
		if freq < 100: freq = 100
		var increment = freq / sample_rate
		phase = fmod(phase + increment, 1.0)
		var sample_val = (1.0 if phase < 0.5 else -1.0) * 0.3 * (1.0 - t * 5.0)
		playback.push_frame(Vector2.ONE * sample_val)

func _fill_explosion_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var frames = playback.get_frames_available()
	
	for i in range(frames):
		var t = float(i) / sample_rate
		# White noise with decay
		var sample_val = randf_range(-1.0, 1.0) * 0.5 * exp(-t * 5.0)
		playback.push_frame(Vector2.ONE * sample_val)
