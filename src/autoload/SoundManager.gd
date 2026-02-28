extends Node

# SoundManager
# Generates and plays procedural sounds

var sample_rate = 44100.0
var _pop_sounds: Array = []

var _rocket_engine_player: AudioStreamPlayer = null

func start_rocket_engine_sound() -> void:
	if _rocket_engine_player and _rocket_engine_player.playing:
		return
	if not _rocket_engine_player:
		_rocket_engine_player = AudioStreamPlayer.new()
		add_child(_rocket_engine_player)
		var stream: AudioStreamWAV = load("res://assets/sound_effects/rocket_engine.wav").duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_rocket_engine_player.stream = stream
		_rocket_engine_player.bus = &"SFX"
		_rocket_engine_player.volume_db = -10.0
	_rocket_engine_player.play()

func stop_rocket_engine_sound() -> void:
	if _rocket_engine_player and _rocket_engine_player.playing:
		_rocket_engine_player.stop()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_pop_sounds = [
		load("res://assets/sound_effects/pops/pop1.ogg"),
		load("res://assets/sound_effects/pops/pop2.ogg"),
		load("res://assets/sound_effects/pops/pop3.ogg"),
	]

func play_pickup_sound() -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)

	player.stream = _pop_sounds[randi() % _pop_sounds.size()]
	player.pitch_scale = randf_range(0.8, 1.2)
	player.bus = &"SFX"
	player.volume_db = -8.0
	player.play()

	await player.finished
	player.queue_free()

func play_drill_sound() -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)

	player.stream = _pop_sounds[randi() % _pop_sounds.size()]
	player.pitch_scale = randf_range(0.8, 1.2)
	player.bus = &"SFX"
	player.volume_db = -8.0
	player.play()

	await player.finished
	player.queue_free()

func play_impact_sound() -> void:
	# Short, sharp thud for hitting a block that isn't destroyed yet
	var player = AudioStreamPlayer.new()
	add_child(player)

	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.1
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = -14.0
	player.play()

	var playback = player.get_stream_playback()
	_fill_impact_buffer(playback)

	await get_tree().create_timer(0.15).timeout
	player.queue_free()

func play_damage_sound() -> void:
	# Short sharp "hurt" sound: descending tone + noise burst
	var player = AudioStreamPlayer.new()
	add_child(player)

	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.15
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = -6.0
	player.play()

	var playback = player.get_stream_playback()
	_fill_damage_buffer(playback)

	await get_tree().create_timer(0.3).timeout
	player.queue_free()

func play_explosion_sound() -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)

	var stream = AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.5
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = -5.0
	player.play()
	
	var playback = player.get_stream_playback()
	_fill_explosion_buffer(playback)
	
	await get_tree().create_timer(0.6).timeout
	player.queue_free()


func _fill_impact_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var phase = 0.0
	var frames = playback.get_frames_available()

	for i in range(frames):
		var t = float(i) / sample_rate
		# Short percussive thud: pitch-dropping tone + quick noise burst
		var freq = 200.0 * exp(-t * 25.0)  # Pitch drops rapidly
		var increment = freq / sample_rate
		phase = fmod(phase + increment, 1.0)
		var tone = sin(phase * TAU) * exp(-t * 35.0) * 0.35
		var noise = randf_range(-0.12, 0.12) * exp(-t * 30.0)
		playback.push_frame(Vector2.ONE * (tone + noise))

func _fill_explosion_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var frames = playback.get_frames_available()

	for i in range(frames):
		var t = float(i) / sample_rate
		# White noise with decay
		var sample_val = randf_range(-1.0, 1.0) * 0.5 * exp(-t * 5.0)
		playback.push_frame(Vector2.ONE * sample_val)

func _fill_damage_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var phase = 0.0
	var frames = playback.get_frames_available()

	for i in range(frames):
		var t = float(i) / sample_rate
		# Descending tone from 300 Hz down to ~80 Hz — a dull "thwack" with a pain edge
		var freq = 300.0 * exp(-t * 12.0) + 80.0
		var increment = freq / sample_rate
		phase = fmod(phase + increment, 1.0)
		var tone = sin(phase * TAU) * exp(-t * 18.0) * 0.45
		# Gritty noise layer for impact texture
		var noise = randf_range(-0.2, 0.2) * exp(-t * 22.0)
		playback.push_frame(Vector2.ONE * (tone + noise))
