extends Control

const WISHLIST_URL = "https://lost-rabbit-digital.itch.io/pickaxe-pioneer"

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var master_slider: HSlider = $SettingsPanel/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $SettingsPanel/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $SettingsPanel/VBox/SFXRow/SFXSlider
@onready var master_label: Label = $SettingsPanel/VBox/MasterRow/ValueLabel
@onready var music_label: Label = $SettingsPanel/VBox/MusicRow/ValueLabel
@onready var sfx_label: Label = $SettingsPanel/VBox/SFXRow/ValueLabel

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/WishlistButton.pressed.connect(_on_wishlist_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$SettingsPanel/VBox/CloseButton.pressed.connect(_on_settings_close_pressed)

	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)

	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	# Initialise sliders from saved settings
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	_update_labels()

	settings_panel.hide()

func _on_start_pressed() -> void:
	GameManager.start_game()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	settings_panel.show()

func _on_wishlist_pressed() -> void:
	OS.shell_open(WISHLIST_URL)

func _on_settings_close_pressed() -> void:
	SettingsManager.save_settings()
	settings_panel.hide()

func _on_master_changed(value: float) -> void:
	SettingsManager.set_master_volume(value)
	master_label.text = "%d%%" % int(value * 100)

func _on_music_changed(value: float) -> void:
	SettingsManager.set_music_volume(value)
	music_label.text = "%d%%" % int(value * 100)

func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_sfx_volume(value)
	sfx_label.text = "%d%%" % int(value * 100)

func _update_labels() -> void:
	master_label.text = "%d%%" % int(master_slider.value * 100)
	music_label.text = "%d%%" % int(music_slider.value * 100)
	sfx_label.text = "%d%%" % int(sfx_slider.value * 100)
