extends HBoxContainer
## Social buttons component for main menu with Discord, Steam, and Twitch links

const DISCORD_URL = "https://discord.gg/e7M6DcU5fR"

@onready var discord_button: TextureButton = $DiscordButton


func _on_discord_button_pressed() -> void:
	OS.shell_open(DISCORD_URL)

func _on_discord_label_button_pressed() -> void:
	OS.shell_open(DISCORD_URL)
