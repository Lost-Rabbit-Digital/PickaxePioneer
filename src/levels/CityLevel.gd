class_name CityLevel
extends Node2D

func _ready() -> void:
	# Bank currency when entering city
	GameManager.bank_currency()
	
	# Start city music
	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)

func _on_return_button_pressed() -> void:
	GameManager.load_overworld()
