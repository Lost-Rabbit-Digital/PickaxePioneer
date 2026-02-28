extends Node

# MusicManager
# Continuous shuffled playlist that starts on launch and plays seamlessly
# through all scenes. Crossfades between songs when one finishes.

var current_player: AudioStreamPlayer
var fade_duration: float = 1.5

var _playlist: Array[AudioStream] = []
var _play_order: Array[int] = []
var _current_index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_playlist()
	_shuffle_order()
	_play_next()

func _load_playlist() -> void:
	_playlist = [
		load("res://assets/music/crickets.mp3"),
		load("res://assets/city.mp3"),
		load("res://assets/mine.mp3"),
		load("res://assets/overworld.mp3"),
	]

func _shuffle_order() -> void:
	_play_order.clear()
	for i in range(_playlist.size()):
		_play_order.append(i)
	_play_order.shuffle()
	_current_index = -1

func _play_next() -> void:
	_current_index += 1
	if _current_index >= _play_order.size():
		_shuffle_order()
		_current_index = 0

	var stream := _playlist[_play_order[_current_index]]
	_crossfade_to(stream)

func _crossfade_to(stream: AudioStream) -> void:
	var new_player := AudioStreamPlayer.new()
	new_player.stream = stream
	new_player.bus = &"Music"
	new_player.volume_db = -80.0
	add_child(new_player)
	new_player.play()
	new_player.finished.connect(_on_song_finished.bind(new_player))

	var tween := create_tween()
	tween.set_parallel(true)

	if current_player:
		var old := current_player
		tween.tween_property(old, "volume_db", -80.0, fade_duration)
		tween.chain().tween_callback(old.queue_free)

	tween.tween_property(new_player, "volume_db", 0.0, fade_duration)

	current_player = new_player

func _on_song_finished(player: AudioStreamPlayer) -> void:
	if player == current_player:
		_play_next()

func stop_music() -> void:
	if current_player:
		var tween := create_tween()
		tween.tween_property(current_player, "volume_db", -80.0, fade_duration)
		await tween.finished
		current_player.queue_free()
		current_player = null
