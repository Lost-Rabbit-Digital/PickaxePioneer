extends Node

# MusicManager
# Auto-discovers all .mp3 files in res://assets/music/, shuffles them,
# and loops continuously with crossfade. Starts on launch, persists
# across all scene transitions.

const MUSIC_DIR := "res://assets/music/"

var current_player: AudioStreamPlayer
var fade_duration: float = 1.5

var _tracks: Array[AudioStream] = []
var _order: Array[int] = []
var _index: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_scan_tracks()
	if _tracks.is_empty():
		return
	_shuffle()
	_play_next()

func _scan_tracks() -> void:
	var dir := DirAccess.open(MUSIC_DIR)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			# In exported builds files appear as "song.mp3.import"
			var clean := file_name.trim_suffix(".import")
			if clean.ends_with(".mp3") or clean.ends_with(".ogg") or clean.ends_with(".wav"):
				var path := MUSIC_DIR + clean
				if ResourceLoader.exists(path):
					var stream := load(path) as AudioStream
					if stream:
						_tracks.append(stream)
		file_name = dir.get_next()

func _shuffle() -> void:
	_order.clear()
	for i in range(_tracks.size()):
		_order.append(i)
	_order.shuffle()
	_index = -1

func _play_next() -> void:
	_index += 1
	if _index >= _order.size():
		_shuffle()
		_index = 0
	_crossfade_to(_tracks[_order[_index]])

func _crossfade_to(stream: AudioStream) -> void:
	var track_name := stream.resource_path.get_file().get_basename()
	print("[MusicManager] Now playing: ", track_name)

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
