extends HBoxContainer
## Social buttons component for main menu with Discord, Steam, and Twitch links

const DISCORD_URL = "https://discord.gg/e7M6DcU5fR"
const STEAM_URL = "https://store.steampowered.com/search/?developer=Lost%20Rabbit%20Digital"

@onready var discord_button: TextureButton = $DiscordBackground/DiscordButton
@onready var steam_button: TextureButton = $SteamBackground/SteamButton


func _on_discord_button_pressed() -> void:
	OS.shell_open(DISCORD_URL)

func _on_steam_button_pressed() -> void:
	OS.shell_open(STEAM_URL)
	
