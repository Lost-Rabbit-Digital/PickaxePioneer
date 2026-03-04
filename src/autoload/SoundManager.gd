extends Node

# SoundManager
# Plays sample-based SFX with procedural fallbacks for missing files

var sample_rate = 44100.0
var _pop_sounds: Array = []

# Suno-generated sound effect samples (loaded at runtime, null if file missing)
var _mining_hit_sound: AudioStream = null
var _sonar_ping_sound: AudioStream = null
var _cat_damage_sound: AudioStream = null
var _explosion_sound: AudioStream = null
var _boss_stinger_sound: AudioStream = null

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
	# Load Suno-generated SFX (graceful null if file not yet added)
	_mining_hit_sound = _try_load("res://assets/sound_effects/mining_hit.mp3")
	_sonar_ping_sound = _try_load("res://assets/sound_effects/sonar_ping.mp3")
	_cat_damage_sound = _try_load("res://assets/sound_effects/cat_damage.mp3")
	_explosion_sound = _try_load("res://assets/sound_effects/explosion.mp3")
	_boss_stinger_sound = _try_load("res://assets/sound_effects/boss_stinger.mp3")


func _try_load(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func _play_sample(stream: AudioStream, volume_db: float = -8.0, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.bus = &"SFX"
	player.volume_db = volume_db
	player.play()
	await player.finished
	player.queue_free()


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
	if _mining_hit_sound:
		_play_sample(_mining_hit_sound, -8.0, 0.85, 1.15)
		return
	# Fallback: pop sound
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = _pop_sounds[randi() % _pop_sounds.size()]
	player.pitch_scale = randf_range(0.8, 1.2)
	player.bus = &"SFX"
	player.volume_db = -8.0
	player.play()
	await player.finished
	player.queue_free()

func play_sonar_ping_sound() -> void:
	if _sonar_ping_sound:
		_play_sample(_sonar_ping_sound, -6.0)
		return
	# Fallback: procedural ping
	var player := AudioStreamPlayer.new()
	add_child(player)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.3
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = -8.0
	player.play()
	var playback := player.get_stream_playback()
	_fill_sonar_ping_buffer(playback)
	await get_tree().create_timer(0.5).timeout
	player.queue_free()

func play_damage_sound() -> void:
	if _cat_damage_sound:
		_play_sample(_cat_damage_sound, -6.0, 0.9, 1.1)
		return
	# Fallback: procedural descending tone
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
	if _explosion_sound:
		_play_sample(_explosion_sound, -5.0, 0.9, 1.1)
		return
	# Fallback: procedural white noise
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

func play_boss_stinger_sound() -> void:
	if _boss_stinger_sound:
		_play_sample(_boss_stinger_sound, -4.0)
		return
	# Fallback: procedural ominous tone
	var player := AudioStreamPlayer.new()
	add_child(player)
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = sample_rate
	stream.buffer_length = 0.5
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = -4.0
	player.play()
	var playback := player.get_stream_playback()
	_fill_boss_stinger_buffer(playback)
	await get_tree().create_timer(1.0).timeout
	player.queue_free()

func play_laser_sound() -> void:
	# Placeholder — reuses sonar ping for now
	play_sonar_ping_sound()

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


# ---------------------------------------------------------------------------
# Procedural buffer fills (fallbacks)
# ---------------------------------------------------------------------------

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

func _fill_sonar_ping_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var phase := 0.0
	var frames := playback.get_frames_available()

	for i in range(frames):
		var t := float(i) / sample_rate
		# Clean sine ping at 1200 Hz that decays with a subtle echo
		var freq := 1200.0 * exp(-t * 2.0)
		var increment := freq / sample_rate
		phase = fmod(phase + increment, 1.0)
		var tone := sin(phase * TAU) * exp(-t * 6.0) * 0.5
		playback.push_frame(Vector2.ONE * tone)

func _fill_boss_stinger_buffer(playback: AudioStreamGeneratorPlayback) -> void:
	var phase := 0.0
	var frames := playback.get_frames_available()

	for i in range(frames):
		var t := float(i) / sample_rate
		# Low ominous drone at 80 Hz with dissonant overtone
		var freq := 80.0
		var increment := freq / sample_rate
		phase = fmod(phase + increment, 1.0)
		var tone := sin(phase * TAU) * 0.4 * exp(-t * 2.0)
		var overtone := sin(phase * TAU * 3.17) * 0.2 * exp(-t * 3.0)
		var noise := randf_range(-0.1, 0.1) * exp(-t * 4.0)
		playback.push_frame(Vector2.ONE * (tone + overtone + noise))
