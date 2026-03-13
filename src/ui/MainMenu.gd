extends Control

const WISHLIST_URL = "https://lost-rabbit-digital.itch.io/pickaxe-pioneer"

@onready var credits_panel: PanelContainer = $CreditsPanel
@onready var version_label: Label = $VersionLabel

# Inline sub-menu buttons
@onready var _menu_title_label: Label = $VBoxContainer/MenuTitleLabel
@onready var _continue_btn: Button = $VBoxContainer/ContinueButton
@onready var _new_game_btn: Button = $VBoxContainer/NewGameButton
@onready var _sp_back_btn: Button = $VBoxContainer/SpBackButton
@onready var _host_btn: Button = $VBoxContainer/HostButton
@onready var _join_btn: Button = $VBoxContainer/JoinButton
@onready var _mp_back_btn: Button = $VBoxContainer/MpBackButton
@onready var _lan_btn: Button = $VBoxContainer/LanButton
@onready var _steam_btn: Button = $VBoxContainer/SteamButton
@onready var _hosting_back_btn: Button = $VBoxContainer/HostingBackButton
@onready var _host_save_continue_btn: Button = $VBoxContainer/HostSaveContinueButton
@onready var _host_save_new_game_btn: Button = $VBoxContainer/HostSaveNewGameButton
@onready var _host_save_back_btn: Button = $VBoxContainer/HostSaveBackButton

var _active_submenu: String = ""  # "sp", "mp", "hosting", "host_save", or ""

# Save slot popup (built in code)
var _save_popup: Control = null
var _popup_mode: String = ""  # "new_game" or "continue"
var _slot_buttons: Array = []
var _delete_buttons: Array = []

# Confirmation dialog for overwriting saves
var _confirm_dialog: Control = null
var _pending_slot_index: int = -1

# Confirmation dialog for deleting saves
var _delete_confirm_dialog: Control = null
var _pending_delete_index: int = -1

# Singleplayer overlay
var _sp_overlay: Control = null
var _sp_continue_btn: Button = null

# Multiplayer overlay (multi-page)
var _mp_overlay: Control = null
var _mp_title_label: Label = null
var _mp_page_menu: VBoxContainer = null
var _mp_page_host_type: VBoxContainer = null
var _mp_page_host_save: VBoxContainer = null
var _mp_page_host_save_continue_btn: Button = null
var _mp_page_lobby: VBoxContainer = null
var _mp_page_join: VBoxContainer = null
var _mp_lobby_status: Label = null
var _mp_lobby_start_btn: Button = null
var _mp_join_status: Label = null
var _mp_ip_input: LineEdit = null
var _mp_port_input: LineEdit = null
var _mp_host_method: String = ""
var _mp_host_pending: bool = false
var _mp_current_page: String = "menu"

# Settings overlay (built in code, delegates to shared SettingsPanel)
var _settings_overlay: Control = null
var _settings_panel: Node = null

# Character customization overlay — shared CustomizationMenu scene
var _customize_menu: CustomizationMenu = null
var _menu_char_sprite: AnimatedSprite2D = null

@onready var _player_level_bar: ProgressBar = $CharacterContainer/CurrentPlayerLevelProgress
@onready var _player_level_label: Label = $CharacterContainer/CurrentPlayerLevelProgress/Panel/Label

func _ready() -> void:
	$VBoxContainer/SingleplayerButton.pressed.connect(_on_singleplayer_pressed)
	$VBoxContainer/MultiplayerButton.pressed.connect(_on_multiplayer_pressed)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings_pressed)
	$VBoxContainer/WishlistButton.pressed.connect(_on_wishlist_pressed)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)
	$CreditsButton.pressed.connect(_on_credits_pressed)
	$CreditsPanel/VBox/CloseButton.pressed.connect(_on_credits_close_pressed)
	$CharacterContainer/CustomizeButton.pressed.connect(_on_customize_character_pressed)

	_continue_btn.pressed.connect(_on_inline_continue_pressed)
	_new_game_btn.pressed.connect(_on_inline_new_game_pressed)
	_sp_back_btn.pressed.connect(_show_main_buttons)
	_host_btn.pressed.connect(_on_inline_host_pressed)
	_join_btn.pressed.connect(_on_inline_join_pressed)
	_mp_back_btn.pressed.connect(_show_main_buttons)
	_lan_btn.pressed.connect(_on_lan_pressed)
	_steam_btn.disabled = true
	_hosting_back_btn.pressed.connect(_on_hosting_back_pressed)
	_host_save_continue_btn.pressed.connect(_on_inline_host_save_continue_pressed)
	_host_save_new_game_btn.pressed.connect(_on_inline_host_save_new_game_pressed)
	_host_save_back_btn.pressed.connect(_on_inline_host_save_back_pressed)

	version_label.text = "v" + ProjectSettings.get_setting("application/config/version", "0.0.0")

	_build_settings_overlay()
	_build_save_popup()
	_build_confirm_dialog()
	_build_delete_confirm_dialog()
	_build_singleplayer_overlay()
	_build_multiplayer_overlay()
	_setup_customize_menu()
	_setup_menu_char_sprite()

	# If returning from a multiplayer session that ended (e.g. disconnected), clean up
	if NetworkManager.is_multiplayer_session:
		NetworkManager.disconnect_session()

	credits_panel.hide()

	_update_player_level_display()
	EventBus.global_xp_changed.connect(_on_global_xp_changed)
	EventBus.global_player_leveled_up.connect(_on_global_player_leveled_up)

# ---------------------------------------------------------------------------
# Menu buttons
# ---------------------------------------------------------------------------

func _on_singleplayer_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_active_submenu = "sp"
	_hide_main_buttons()
	_menu_title_label.text = "SINGLEPLAYER"
	_menu_title_label.show()
	_continue_btn.visible = SaveManager.has_any_save()
	_new_game_btn.show()
	_sp_back_btn.show()

func _on_multiplayer_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_active_submenu = "mp"
	_hide_main_buttons()
	_menu_title_label.text = "MULTIPLAYER"
	_menu_title_label.show()
	_host_btn.show()
	_join_btn.show()
	_mp_back_btn.show()

func _hide_main_buttons() -> void:
	$VBoxContainer/SingleplayerButton.hide()
	$VBoxContainer/MultiplayerButton.hide()
	$VBoxContainer/WishlistButton.hide()
	$VBoxContainer/SettingsButton.hide()
	$VBoxContainer/QuitButton.hide()

func _show_main_buttons() -> void:
	SoundManager.play_ui_close_sound()
	_active_submenu = ""
	$VBoxContainer/SingleplayerButton.show()
	$VBoxContainer/MultiplayerButton.show()
	$VBoxContainer/WishlistButton.show()
	$VBoxContainer/SettingsButton.show()
	$VBoxContainer/QuitButton.show()
	_menu_title_label.hide()
	_continue_btn.hide()
	_new_game_btn.hide()
	_sp_back_btn.hide()
	_host_btn.hide()
	_join_btn.hide()
	_mp_back_btn.hide()
	_lan_btn.hide()
	_steam_btn.hide()
	_hosting_back_btn.hide()
	_host_save_continue_btn.hide()
	_host_save_new_game_btn.hide()
	_host_save_back_btn.hide()

func _on_inline_continue_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_popup_mode = "continue"
	_refresh_popup()
	_save_popup.show()

func _on_inline_new_game_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_popup_mode = "new_game"
	_refresh_popup()
	_save_popup.show()

func _on_inline_host_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_active_submenu = "hosting"
	_host_btn.hide()
	_join_btn.hide()
	_mp_back_btn.hide()
	_menu_title_label.text = "HOSTING"
	_lan_btn.show()
	_steam_btn.show()
	_hosting_back_btn.show()

func _on_inline_join_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_mp_show_page("join")
	_mp_overlay.show()

func _on_lan_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_mp_host_method = "lan"
	_active_submenu = "host_save"
	_lan_btn.hide()
	_steam_btn.hide()
	_hosting_back_btn.hide()
	_menu_title_label.text = "HOST — SELECT SAVE"
	_host_save_continue_btn.visible = SaveManager.has_any_save()
	_host_save_new_game_btn.show()
	_host_save_back_btn.show()

func _on_hosting_back_pressed() -> void:
	SoundManager.play_ui_close_sound()
	_active_submenu = "mp"
	_lan_btn.hide()
	_steam_btn.hide()
	_hosting_back_btn.hide()
	_menu_title_label.text = "MULTIPLAYER"
	_host_btn.show()
	_join_btn.show()
	_mp_back_btn.show()

func _on_inline_host_save_back_pressed() -> void:
	SoundManager.play_ui_close_sound()
	_active_submenu = "hosting"
	_host_save_continue_btn.hide()
	_host_save_new_game_btn.hide()
	_host_save_back_btn.hide()
	_menu_title_label.text = "HOSTING"
	_lan_btn.show()
	_steam_btn.show()
	_hosting_back_btn.show()

func _on_inline_host_save_continue_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_mp_host_pending = true
	_popup_mode = "continue"
	_refresh_popup()
	_save_popup.show()

func _on_inline_host_save_new_game_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_mp_host_pending = true
	_popup_mode = "new_game"
	_refresh_popup()
	_save_popup.show()

func _on_quit_pressed() -> void:
	SoundManager.play_ui_close_sound()
	OS.delay_msec(250)
	get_tree().quit()

func _on_settings_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_settings_panel.sync_settings_ui()
	_settings_overlay.show()

func _on_wishlist_pressed() -> void:
	SoundManager.play_ui_click_sound()
	OS.shell_open(WISHLIST_URL)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if credits_panel.visible:
			_on_credits_close_pressed()
			get_viewport().set_input_as_handled()
		elif _settings_overlay != null and _settings_overlay.visible:
			if _settings_panel and _settings_panel.is_listening():
				_settings_panel.cancel_rebind()
			else:
				_on_settings_close()
			get_viewport().set_input_as_handled()
		elif _save_popup != null and _save_popup.visible:
			_on_popup_close()
			get_viewport().set_input_as_handled()
		elif _mp_overlay != null and _mp_overlay.visible:
			_on_mp_back_pressed()
			get_viewport().set_input_as_handled()
		elif _customize_menu != null and _customize_menu.visible:
			_customize_menu.close()
			get_viewport().set_input_as_handled()
		elif _active_submenu != "":
			_show_main_buttons()
			get_viewport().set_input_as_handled()

func _on_credits_pressed() -> void:
	SoundManager.play_ui_click_sound()
	credits_panel.show()

func _on_credits_close_pressed() -> void:
	SoundManager.play_ui_close_sound()
	credits_panel.hide()

func _on_customize_character_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_customize_menu.open()

# ---------------------------------------------------------------------------
# Character customization — scene instance + menu cat sprite
# ---------------------------------------------------------------------------

func _setup_customize_menu() -> void:
	var scene := preload("res://src/ui/CustomizationMenu.tscn") as PackedScene
	_customize_menu = scene.instantiate() as CustomizationMenu
	# No player on the main menu; CustomizationMenu handles null gracefully
	_customize_menu.player = null
	add_child(_customize_menu)
	_customize_menu.color_changed.connect(_update_menu_char_sprite_shader)

func _setup_menu_char_sprite() -> void:
	_menu_char_sprite = AnimatedSprite2D.new()
	_menu_char_sprite.position = Vector2(80.0, 112.0)
	_menu_char_sprite.scale = Vector2(4, 4)
	_menu_char_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	$CharacterContainer.add_child(_menu_char_sprite)
	_load_char_sprite_frames(_menu_char_sprite)
	_menu_char_sprite.play(&"idle")
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/cat_color.gdshader")
	mat.set_shader_parameter("base_color", GameManager.cat_color)
	mat.set_shader_parameter("outline_color", GameManager.cat_outline_color)
	_menu_char_sprite.material = mat

func _load_char_sprite_frames(target: AnimatedSprite2D) -> void:
	var player_scene := load("res://src/entities/player/PlayerProbe.tscn") as PackedScene
	if player_scene:
		var temp := player_scene.instantiate()
		var source_sprite: AnimatedSprite2D = temp.get_node("AnimatedSprite2D")
		if source_sprite:
			target.sprite_frames = source_sprite.sprite_frames
		temp.queue_free()

func _update_menu_char_sprite_shader() -> void:
	if _menu_char_sprite and _menu_char_sprite.material is ShaderMaterial:
		var mat := _menu_char_sprite.material as ShaderMaterial
		mat.set_shader_parameter("base_color", GameManager.cat_color)
		mat.set_shader_parameter("outline_color", GameManager.cat_outline_color)

# ---------------------------------------------------------------------------
# Player level display — shows global cross-save level and XP progress
# ---------------------------------------------------------------------------

func _update_player_level_display() -> void:
	var level: int = GameManager.global_player_level
	var xp: int = GameManager.global_player_xp
	var xp_max: int = PerkSystem.xp_for_next_level(level)
	_player_level_bar.max_value = xp_max
	_player_level_bar.value = xp
	_player_level_label.text = str(level)

func _on_global_xp_changed(_current_xp: int, _xp_to_next: int) -> void:
	_update_player_level_display()

func _on_global_player_leveled_up(_new_level: int) -> void:
	_update_player_level_display()

# ---------------------------------------------------------------------------
# Singleplayer overlay — built in code
# ---------------------------------------------------------------------------

const SP_W := 360.0
const SP_H := 300.0

func _build_singleplayer_overlay() -> void:
	_sp_overlay = Control.new()
	_sp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sp_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_sp_overlay.hide()
	add_child(_sp_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	_sp_overlay.add_child(dimmer)

	var px := (1280.0 - SP_W) / 2.0
	var py := (720.0 - SP_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(SP_W + 4, SP_H + 4)
	border.color = Color(0.30, 0.55, 0.90, 0.85)
	_sp_overlay.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(SP_W, SP_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_sp_overlay.add_child(bg)

	var title := Label.new()
	title.text = "SINGLEPLAYER"
	title.position = Vector2(px, py + 14)
	title.size = Vector2(SP_W, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	_sp_overlay.add_child(title)

	var sep := ColorRect.new()
	sep.position = Vector2(px + 20, py + 56)
	sep.size = Vector2(SP_W - 40, 2)
	sep.color = Color(0.30, 0.55, 0.90, 0.45)
	_sp_overlay.add_child(sep)

	var btn_vbox := VBoxContainer.new()
	btn_vbox.position = Vector2(px + 40, py + 76)
	btn_vbox.size = Vector2(SP_W - 80, 130)
	btn_vbox.add_theme_constant_override("separation", 14)
	_sp_overlay.add_child(btn_vbox)

	_sp_continue_btn = Button.new()
	_sp_continue_btn.text = "CONTINUE"
	_sp_continue_btn.custom_minimum_size = Vector2(0, 44)
	_sp_continue_btn.add_theme_font_size_override("font_size", 22)
	_sp_continue_btn.pressed.connect(_on_sp_continue_pressed)
	_sp_continue_btn.visible = SaveManager.has_any_save()
	btn_vbox.add_child(_sp_continue_btn)

	var new_btn := Button.new()
	new_btn.text = "NEW GAME"
	new_btn.custom_minimum_size = Vector2(0, 44)
	new_btn.add_theme_font_size_override("font_size", 22)
	new_btn.pressed.connect(_on_sp_new_game_pressed)
	btn_vbox.add_child(new_btn)

	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.position = Vector2(px + (SP_W - 130) / 2.0, py + SP_H - 50)
	back_btn.size = Vector2(130, 36)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_on_sp_back_pressed)
	_sp_overlay.add_child(back_btn)

func _on_sp_new_game_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_popup_mode = "new_game"
	_refresh_popup()
	_save_popup.show()

func _on_sp_continue_pressed() -> void:
	SoundManager.play_ui_click_sound()
	_popup_mode = "continue"
	_refresh_popup()
	_save_popup.show()

func _on_sp_back_pressed() -> void:
	SoundManager.play_ui_close_sound()
	_sp_overlay.hide()

# ---------------------------------------------------------------------------
# Multiplayer overlay — multi-page, built in code
# ---------------------------------------------------------------------------

const MP_W := 480.0
const MP_H := 400.0

func _build_multiplayer_overlay() -> void:
	_mp_overlay = Control.new()
	_mp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mp_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_mp_overlay.hide()
	add_child(_mp_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	_mp_overlay.add_child(dimmer)

	var px := (1280.0 - MP_W) / 2.0
	var py := (720.0 - MP_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(MP_W + 4, MP_H + 4)
	border.color = Color(0.30, 0.55, 0.90, 0.85)
	_mp_overlay.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(MP_W, MP_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_mp_overlay.add_child(bg)

	# Title (changes per page)
	_mp_title_label = Label.new()
	_mp_title_label.position = Vector2(px, py + 14)
	_mp_title_label.size = Vector2(MP_W, 36)
	_mp_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mp_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mp_title_label.add_theme_font_size_override("font_size", 22)
	_mp_title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	_mp_overlay.add_child(_mp_title_label)

	var sep := ColorRect.new()
	sep.position = Vector2(px + 20, py + 56)
	sep.size = Vector2(MP_W - 40, 2)
	sep.color = Color(0.30, 0.55, 0.90, 0.45)
	_mp_overlay.add_child(sep)

	# Content area shared by all pages
	var content_x := px + 60
	var content_y := py + 80
	var content_w := MP_W - 120
	var content_h := MP_H - 150

	# --- Page: Menu (HOST / JOIN) ---
	_mp_page_menu = VBoxContainer.new()
	_mp_page_menu.position = Vector2(content_x, content_y)
	_mp_page_menu.size = Vector2(content_w, content_h)
	_mp_page_menu.add_theme_constant_override("separation", 16)
	_mp_page_menu.alignment = BoxContainer.ALIGNMENT_CENTER
	_mp_overlay.add_child(_mp_page_menu)

	var host_btn := Button.new()
	host_btn.text = "HOST"
	host_btn.custom_minimum_size = Vector2(0, 48)
	host_btn.add_theme_font_size_override("font_size", 24)
	host_btn.pressed.connect(_on_mp_host_pressed)
	_mp_page_menu.add_child(host_btn)

	var join_btn := Button.new()
	join_btn.text = "JOIN"
	join_btn.custom_minimum_size = Vector2(0, 48)
	join_btn.add_theme_font_size_override("font_size", 24)
	join_btn.pressed.connect(_on_mp_join_page_pressed)
	_mp_page_menu.add_child(join_btn)

	# --- Page: Host Type (LAN / STEAM) ---
	_mp_page_host_type = VBoxContainer.new()
	_mp_page_host_type.position = Vector2(content_x, content_y)
	_mp_page_host_type.size = Vector2(content_w, content_h)
	_mp_page_host_type.add_theme_constant_override("separation", 16)
	_mp_page_host_type.alignment = BoxContainer.ALIGNMENT_CENTER
	_mp_page_host_type.hide()
	_mp_overlay.add_child(_mp_page_host_type)

	var lan_btn := Button.new()
	lan_btn.text = "LAN"
	lan_btn.custom_minimum_size = Vector2(0, 48)
	lan_btn.add_theme_font_size_override("font_size", 24)
	lan_btn.pressed.connect(_on_mp_lan_pressed)
	_mp_page_host_type.add_child(lan_btn)

	var steam_btn := Button.new()
	steam_btn.text = "STEAM"
	steam_btn.custom_minimum_size = Vector2(0, 48)
	steam_btn.add_theme_font_size_override("font_size", 24)
	steam_btn.disabled = true
	steam_btn.tooltip_text = "Coming Soon"
	_mp_page_host_type.add_child(steam_btn)

	# --- Page: Host Save (NEW GAME / CONTINUE) ---
	_mp_page_host_save = VBoxContainer.new()
	_mp_page_host_save.position = Vector2(content_x, content_y)
	_mp_page_host_save.size = Vector2(content_w, content_h)
	_mp_page_host_save.add_theme_constant_override("separation", 16)
	_mp_page_host_save.alignment = BoxContainer.ALIGNMENT_CENTER
	_mp_page_host_save.hide()
	_mp_overlay.add_child(_mp_page_host_save)

	_mp_page_host_save_continue_btn = Button.new()
	_mp_page_host_save_continue_btn.text = "CONTINUE"
	_mp_page_host_save_continue_btn.custom_minimum_size = Vector2(0, 48)
	_mp_page_host_save_continue_btn.add_theme_font_size_override("font_size", 24)
	_mp_page_host_save_continue_btn.pressed.connect(_on_mp_host_continue_pressed)
	_mp_page_host_save.add_child(_mp_page_host_save_continue_btn)

	var host_new_btn := Button.new()
	host_new_btn.text = "NEW GAME"
	host_new_btn.custom_minimum_size = Vector2(0, 48)
	host_new_btn.add_theme_font_size_override("font_size", 24)
	host_new_btn.pressed.connect(_on_mp_host_new_game_pressed)
	_mp_page_host_save.add_child(host_new_btn)

	# --- Page: Host Lobby (waiting for guest) ---
	_mp_page_lobby = VBoxContainer.new()
	_mp_page_lobby.position = Vector2(content_x, content_y)
	_mp_page_lobby.size = Vector2(content_w, content_h)
	_mp_page_lobby.add_theme_constant_override("separation", 16)
	_mp_page_lobby.alignment = BoxContainer.ALIGNMENT_CENTER
	_mp_page_lobby.hide()
	_mp_overlay.add_child(_mp_page_lobby)

	_mp_lobby_status = Label.new()
	_mp_lobby_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mp_lobby_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mp_lobby_status.add_theme_font_size_override("font_size", 16)
	_mp_lobby_status.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_mp_lobby_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_mp_lobby_status.custom_minimum_size = Vector2(0, 60)
	_mp_page_lobby.add_child(_mp_lobby_status)

	_mp_lobby_start_btn = Button.new()
	_mp_lobby_start_btn.text = "START GAME"
	_mp_lobby_start_btn.custom_minimum_size = Vector2(0, 48)
	_mp_lobby_start_btn.add_theme_font_size_override("font_size", 22)
	_mp_lobby_start_btn.pressed.connect(_on_mp_lobby_start_pressed)
	_mp_lobby_start_btn.visible = false
	_mp_page_lobby.add_child(_mp_lobby_start_btn)

	# --- Page: Join (IP + port input) ---
	_mp_page_join = VBoxContainer.new()
	_mp_page_join.position = Vector2(content_x, content_y)
	_mp_page_join.size = Vector2(content_w, content_h)
	_mp_page_join.add_theme_constant_override("separation", 10)
	_mp_page_join.alignment = BoxContainer.ALIGNMENT_CENTER
	_mp_page_join.hide()
	_mp_overlay.add_child(_mp_page_join)

	var ip_label := Label.new()
	ip_label.text = "Host IP Address:"
	ip_label.add_theme_font_size_override("font_size", 16)
	_mp_page_join.add_child(ip_label)

	_mp_ip_input = LineEdit.new()
	_mp_ip_input.placeholder_text = "192.168.x.x"
	_mp_ip_input.custom_minimum_size = Vector2(0, 36)
	_mp_ip_input.add_theme_font_size_override("font_size", 16)
	_mp_page_join.add_child(_mp_ip_input)

	var port_label := Label.new()
	port_label.text = "Port:"
	port_label.add_theme_font_size_override("font_size", 16)
	_mp_page_join.add_child(port_label)

	_mp_port_input = LineEdit.new()
	_mp_port_input.text = str(NetworkManager.DEFAULT_PORT)
	_mp_port_input.custom_minimum_size = Vector2(0, 36)
	_mp_port_input.add_theme_font_size_override("font_size", 16)
	_mp_page_join.add_child(_mp_port_input)

	var connect_btn := Button.new()
	connect_btn.text = "CONNECT"
	connect_btn.custom_minimum_size = Vector2(0, 42)
	connect_btn.add_theme_font_size_override("font_size", 20)
	connect_btn.pressed.connect(_on_mp_connect_pressed)
	_mp_page_join.add_child(connect_btn)

	_mp_join_status = Label.new()
	_mp_join_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mp_join_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mp_join_status.add_theme_font_size_override("font_size", 14)
	_mp_join_status.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_mp_join_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_mp_join_status.custom_minimum_size = Vector2(0, 40)
	_mp_page_join.add_child(_mp_join_status)

	# --- Back button (always visible, shared across pages) ---
	var back_btn := Button.new()
	back_btn.text = "BACK"
	back_btn.position = Vector2(px + (MP_W - 130) / 2.0, py + MP_H - 50)
	back_btn.size = Vector2(130, 36)
	back_btn.add_theme_font_size_override("font_size", 18)
	back_btn.pressed.connect(_on_mp_back_pressed)
	_mp_overlay.add_child(back_btn)

	# Connect NetworkManager signals
	NetworkManager.host_started.connect(_on_nm_host_started)
	NetworkManager.guest_connected.connect(_on_nm_guest_connected)
	NetworkManager.guest_disconnected.connect(_on_nm_guest_disconnected)
	NetworkManager.connected_to_host.connect(_on_nm_connected_to_host)
	NetworkManager.connection_failed.connect(_on_nm_connection_failed)

func _mp_show_page(page: String) -> void:
	_mp_current_page = page
	_mp_page_menu.visible = (page == "menu")
	_mp_page_host_type.visible = (page == "host_type")
	_mp_page_host_save.visible = (page == "host_save")
	_mp_page_lobby.visible = (page == "lobby")
	_mp_page_join.visible = (page == "join")
	match page:
		"menu":
			_mp_title_label.text = "MULTIPLAYER"
		"host_type":
			_mp_title_label.text = "HOST — SELECT TYPE"
		"host_save":
			_mp_title_label.text = "HOST — SELECT SAVE"
			_mp_page_host_save_continue_btn.visible = SaveManager.has_any_save()
		"lobby":
			_mp_title_label.text = "HOST — LOBBY"
		"join":
			_mp_title_label.text = "JOIN GAME"
			_mp_join_status.text = ""

# -- MP page handlers --

func _on_mp_host_pressed() -> void:
	_mp_show_page("host_type")

func _on_mp_join_page_pressed() -> void:
	_mp_show_page("join")

func _on_mp_lan_pressed() -> void:
	_mp_host_method = "lan"
	_mp_show_page("host_save")

func _on_mp_host_new_game_pressed() -> void:
	_mp_host_pending = true
	_popup_mode = "new_game"
	_refresh_popup()
	_save_popup.show()

func _on_mp_host_continue_pressed() -> void:
	_mp_host_pending = true
	_popup_mode = "continue"
	_refresh_popup()
	_save_popup.show()

func _on_mp_connect_pressed() -> void:
	var ip := _mp_ip_input.text.strip_edges()
	if ip.is_empty():
		_mp_join_status.text = "Enter the host's IP address."
		return
	var port_text := _mp_port_input.text.strip_edges()
	var port := int(port_text) if port_text.is_valid_int() else 0
	if port <= 0 or port > 65535:
		_mp_join_status.text = "Invalid port number."
		return
	_mp_join_status.text = "Connecting to %s:%d..." % [ip, port]
	var err := NetworkManager.join_host(ip, port)
	if err != OK:
		_mp_join_status.text = "Connection error — check IP and try again."

func _on_mp_lobby_start_pressed() -> void:
	GameManager.start_game()

func _on_mp_back_pressed() -> void:
	match _mp_current_page:
		"menu":
			if NetworkManager.is_multiplayer_session:
				NetworkManager.disconnect_session()
			SoundManager.play_ui_close_sound()
			_mp_overlay.hide()
		"host_type":
			SoundManager.play_ui_close_sound()
			_mp_overlay.hide()
		"lobby":
			if NetworkManager.is_multiplayer_session:
				NetworkManager.disconnect_session()
			SoundManager.play_ui_close_sound()
			_mp_lobby_start_btn.visible = false
			_mp_overlay.hide()
			_active_submenu = "host_save"
			_menu_title_label.text = "HOST — SELECT SAVE"
			_host_save_continue_btn.visible = SaveManager.has_any_save()
			_host_save_new_game_btn.show()
			_host_save_back_btn.show()
		"join":
			if NetworkManager.is_multiplayer_session:
				NetworkManager.disconnect_session()
			SoundManager.play_ui_close_sound()
			_mp_overlay.hide()

func _start_mp_hosting() -> void:
	var port := NetworkManager.DEFAULT_PORT
	var err := NetworkManager.start_host(port)
	if err != OK:
		_mp_lobby_status.text = "Failed to start host (port %d in use?)" % port
		_mp_show_page("lobby")
		return
	_mp_overlay.hide()
	GameManager.start_game()

func _on_nm_host_started() -> void:
	_mp_lobby_status.text = "Hosting on port %d\nWaiting for Player 2..." % NetworkManager.DEFAULT_PORT
	_mp_lobby_start_btn.visible = true

func _on_nm_guest_connected(_peer_id: int) -> void:
	_mp_lobby_status.text = "Player 2 connected!"
	_mp_lobby_start_btn.visible = true
	EventBus.multiplayer_guest_connected.emit(_peer_id)

func _on_nm_guest_disconnected() -> void:
	_mp_lobby_start_btn.visible = false
	_mp_lobby_status.text = "Player 2 disconnected. Waiting..."
	EventBus.multiplayer_guest_disconnected.emit()

func _on_nm_connected_to_host() -> void:
	_mp_join_status.text = "Connected! Waiting for host to start the game..."
	EventBus.multiplayer_connected_to_host.emit()

func _on_nm_connection_failed() -> void:
	_mp_join_status.text = "Connection failed. Check the IP and try again."
	EventBus.multiplayer_connection_failed.emit()

# ---------------------------------------------------------------------------
# Settings overlay — delegates to shared SettingsPanel
# ---------------------------------------------------------------------------

const SETTINGS_W := 620.0
const SETTINGS_H := 560.0
const SECTION_COLOR := Color(0.9, 0.7, 0.3)

func _build_settings_overlay() -> void:
	_settings_overlay = Control.new()
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_overlay.hide()
	add_child(_settings_overlay)

	# Dimmer
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.75)
	_settings_overlay.add_child(dimmer)

	# Panel background
	var px := (1280.0 - SETTINGS_W) / 2.0
	var py := (720.0 - SETTINGS_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(SETTINGS_W + 4, SETTINGS_H + 4)
	border.color = Color(0.5, 0.6, 0.9, 0.85)
	_settings_overlay.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(SETTINGS_W, SETTINGS_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_settings_overlay.add_child(bg)

	# Outer VBox for title + scroll + close button
	var outer_vbox := VBoxContainer.new()
	outer_vbox.position = Vector2(px + 16, py + 12)
	outer_vbox.size = Vector2(SETTINGS_W - 32, SETTINGS_H - 24)
	outer_vbox.add_theme_constant_override("separation", 8)
	_settings_overlay.add_child(outer_vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", SECTION_COLOR)
	outer_vbox.add_child(title)

	# Scroll container
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	outer_vbox.add_child(scroll)

	# Shared SettingsPanel inside scroll
	var settings_scene := preload("res://src/ui/SettingsPanel.tscn")
	_settings_panel = settings_scene.instantiate()
	_settings_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_settings_panel)

	# Close button (outside scroll, at bottom)
	var close_btn := Button.new()
	close_btn.text = "CLOSE"
	close_btn.custom_minimum_size = Vector2(0, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_settings_close)
	outer_vbox.add_child(close_btn)

func _on_settings_close() -> void:
	SoundManager.play_ui_close_sound()
	_settings_panel.close_settings()
	_settings_overlay.hide()

func _input(event: InputEvent) -> void:
	if _settings_panel and _settings_panel.handle_input(event):
		get_viewport().set_input_as_handled()

# ---------------------------------------------------------------------------
# Save Slot Popup — built entirely in code
# ---------------------------------------------------------------------------

const POPUP_W := 584.0
const POPUP_H := 420.0
const SLOT_H := 90.0
const SLOT_GAP := 12.0

func _build_save_popup() -> void:
	# Full-screen dimmer + click blocker
	_save_popup = Control.new()
	_save_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_save_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_save_popup.hide()
	add_child(_save_popup)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	_save_popup.add_child(dimmer)

	# Panel background with border
	var px := (1280.0 - POPUP_W) / 2.0
	var py := (720.0 - POPUP_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(POPUP_W + 4, POPUP_H + 4)
	border.color = Color(0.5, 0.6, 0.9, 0.85)
	_save_popup.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(POPUP_W, POPUP_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_save_popup.add_child(bg)

	# Title label (will be updated in _refresh_popup)
	var title := Label.new()
	title.name = "PopupTitle"
	title.position = Vector2(px, py + 10)
	title.size = Vector2(POPUP_W, 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	_save_popup.add_child(title)

	# Separator
	var sep := ColorRect.new()
	sep.position = Vector2(px + 20, py + 52)
	sep.size = Vector2(POPUP_W - 40, 2)
	sep.color = Color(0.5, 0.6, 0.9, 0.45)
	_save_popup.add_child(sep)

	# Build 3 slot rows
	var slot_y := py + 64
	for i in range(SaveManager.MAX_SLOTS):
		var row := _build_slot_row(i, px + 20, slot_y, POPUP_W - 40)
		slot_y += SLOT_H + SLOT_GAP

	# Close button
	var close_btn := Button.new()
	close_btn.text = "BACK"
	close_btn.position = Vector2(px + (POPUP_W - 140) / 2.0, py + POPUP_H - 52)
	close_btn.size = Vector2(140, 38)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_popup_close)
	_save_popup.add_child(close_btn)

func _build_slot_row(index: int, rx: float, ry: float, rw: float) -> Control:
	var container := Control.new()
	container.position = Vector2(rx, ry)
	container.size = Vector2(rw, SLOT_H)
	_save_popup.add_child(container)

	# Row background
	var row_bg := ColorRect.new()
	row_bg.position = Vector2.ZERO
	row_bg.size = Vector2(rw, SLOT_H)
	row_bg.color = Color(0.12, 0.11, 0.10, 0.8)
	container.add_child(row_bg)

	# Select button (covers most of the row)
	var select_btn := Button.new()
	select_btn.name = "SelectBtn"
	select_btn.position = Vector2(4, 4)
	select_btn.size = Vector2(rw - 46, SLOT_H - 8)
	select_btn.add_theme_font_size_override("font_size", 14)
	select_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	select_btn.pressed.connect(_on_slot_selected.bind(index))
	container.add_child(select_btn)
	_slot_buttons.append(select_btn)

	# Delete button
	var del_btn := Button.new()
	del_btn.name = "DeleteBtn"
	del_btn.text = "X"
	del_btn.position = Vector2(rw - 38, (SLOT_H - 34) / 2.0)
	del_btn.size = Vector2(34, 34)
	del_btn.add_theme_font_size_override("font_size", 16)
	del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	del_btn.pressed.connect(_on_slot_delete.bind(index))
	container.add_child(del_btn)
	_delete_buttons.append(del_btn)

	return container

func _refresh_popup() -> void:
	# Update title
	var title_node: Label = _save_popup.get_node("PopupTitle")
	if _popup_mode == "new_game":
		title_node.text = "New Game - Select Save"
	else:
		title_node.text = "CONTINUE — SELECT SAVE"

	# Update each slot
	for i in range(SaveManager.MAX_SLOTS):
		var summary := SaveManager.get_slot_summary(i)
		var btn: Button = _slot_buttons[i]
		var del_btn: Button = _delete_buttons[i]

		if summary.is_empty():
			btn.text = "  Slot %d  —  EMPTY" % (i + 1)
			del_btn.visible = false
			# In continue mode, can't select empty slots
			btn.disabled = (_popup_mode == "continue")
		else:
			var is_active := SaveManager.active_slot == i
			var lines: String
			if is_active:
				lines = "  ▶ CURRENT"
			else:
				lines = "  Slot %d" % (i + 1)
			lines += "  |  %dg" % summary.get("dollars", 0)
			lines += "  |  Depth: %dm" % summary.get("deepest_row", 0)
			var last_node: String = summary.get("last_node", "")
			if last_node != "":
				lines += "  |  Last: %s" % last_node
			lines += "  |  Playtime: %s" % _format_playtime(summary.get("playtime_seconds", 0.0))
			btn.text = lines
			btn.disabled = false
			del_btn.visible = true

func _format_playtime(seconds: float) -> String:
	var total_minutes := int(seconds) / 60
	var hours := total_minutes / 60
	var minutes := total_minutes % 60
	if hours > 0:
		return "%dh %dm" % [hours, minutes]
	return "%dm" % minutes

func _on_slot_selected(index: int) -> void:
	if _popup_mode == "new_game":
		# Check if slot has existing data
		var slot_data = SaveManager.get_slot(index)
		if slot_data != null:
			# Slot has existing data, show confirmation dialog
			_pending_slot_index = index
			_show_confirm_dialog(index)
			return
		# Slot is empty, proceed with new game
		_save_popup.hide()
		SaveManager.new_game(index)
	else:
		_save_popup.hide()
		SaveManager.load_slot(index)
	if _mp_host_pending:
		_mp_host_pending = false
		_start_mp_hosting()
		return
	GameManager.start_game()

func _on_slot_delete(index: int) -> void:
	SoundManager.play_ui_close_sound()
	_pending_delete_index = index
	_delete_confirm_dialog.show()

func _on_popup_close() -> void:
	SoundManager.play_ui_close_sound()
	_save_popup.hide()
	_mp_host_pending = false

# ---------------------------------------------------------------------------
# Confirmation Dialog — for overwriting existing saves
# ---------------------------------------------------------------------------

const CONFIRM_DIALOG_W := 504.0
const CONFIRM_DIALOG_H := 240.0

func _build_confirm_dialog() -> void:
	# Full-screen dimmer + click blocker
	_confirm_dialog = Control.new()
	_confirm_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_dialog.hide()
	add_child(_confirm_dialog)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	_confirm_dialog.add_child(dimmer)

	# Panel background with border
	var px := (1280.0 - CONFIRM_DIALOG_W) / 2.0
	var py := (720.0 - CONFIRM_DIALOG_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(CONFIRM_DIALOG_W + 4, CONFIRM_DIALOG_H + 4)
	border.color = Color(0.8, 0.4, 0.2, 0.85)
	_confirm_dialog.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(CONFIRM_DIALOG_W, CONFIRM_DIALOG_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_confirm_dialog.add_child(bg)

	# Title label
	var title := Label.new()
	title.name = "ConfirmTitle"
	title.position = Vector2(px, py + 15)
	title.size = Vector2(CONFIRM_DIALOG_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	title.text = "OVERWRITE SAVE?"
	_confirm_dialog.add_child(title)

	# Message label
	var message := Label.new()
	message.name = "ConfirmMessage"
	message.position = Vector2(px + 20, py + 60)
	message.size = Vector2(CONFIRM_DIALOG_W - 40, 80)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	message.text = "This save slot already contains data.\nAre you sure you want to overwrite it with a new game?"
	_confirm_dialog.add_child(message)

	# Button container
	var button_container := HBoxContainer.new()
	button_container.position = Vector2(px, py + CONFIRM_DIALOG_H - 50)
	button_container.size = Vector2(CONFIRM_DIALOG_W, 40)
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_confirm_dialog.add_child(button_container)

	# Cancel button
	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.size = Vector2(120, 38)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_on_confirm_cancel)
	button_container.add_child(cancel_btn)

	# Confirm button
	var confirm_btn := Button.new()
	confirm_btn.text = "OVERWRITE"
	confirm_btn.size = Vector2(120, 38)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	confirm_btn.pressed.connect(_on_confirm_overwrite)
	button_container.add_child(confirm_btn)

func _show_confirm_dialog(slot_index: int) -> void:
	_pending_slot_index = slot_index
	_confirm_dialog.show()

func _on_confirm_cancel() -> void:
	_confirm_dialog.hide()
	_pending_slot_index = -1

func _on_confirm_overwrite() -> void:
	_confirm_dialog.hide()
	_save_popup.hide()
	if _pending_slot_index >= 0:
		SaveManager.new_game(_pending_slot_index)
		if _mp_host_pending:
			_mp_host_pending = false
			_start_mp_hosting()
		else:
			GameManager.start_game()
	_pending_slot_index = -1

# ---------------------------------------------------------------------------
# Delete Confirmation Dialog — for deleting existing saves
# ---------------------------------------------------------------------------

func _build_delete_confirm_dialog() -> void:
	_delete_confirm_dialog = Control.new()
	_delete_confirm_dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_delete_confirm_dialog.mouse_filter = Control.MOUSE_FILTER_STOP
	_delete_confirm_dialog.hide()
	add_child(_delete_confirm_dialog)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.7)
	_delete_confirm_dialog.add_child(dimmer)

	var px := (1280.0 - CONFIRM_DIALOG_W) / 2.0
	var py := (720.0 - CONFIRM_DIALOG_H) / 2.0

	var border := ColorRect.new()
	border.position = Vector2(px - 2, py - 2)
	border.size = Vector2(CONFIRM_DIALOG_W + 4, CONFIRM_DIALOG_H + 4)
	border.color = Color(0.8, 0.2, 0.2, 0.85)
	_delete_confirm_dialog.add_child(border)

	var bg := ColorRect.new()
	bg.position = Vector2(px, py)
	bg.size = Vector2(CONFIRM_DIALOG_W, CONFIRM_DIALOG_H)
	bg.color = Color(0.07, 0.06, 0.05, 0.97)
	_delete_confirm_dialog.add_child(bg)

	var title := Label.new()
	title.position = Vector2(px, py + 15)
	title.size = Vector2(CONFIRM_DIALOG_W, 32)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	title.text = "DELETE SAVE?"
	_delete_confirm_dialog.add_child(title)

	var message := Label.new()
	message.position = Vector2(px + 20, py + 60)
	message.size = Vector2(CONFIRM_DIALOG_W - 40, 80)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 14)
	message.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	message.autowrap_mode = TextServer.AUTOWRAP_WORD
	message.text = "Are you sure you want to delete this save?\nThis action cannot be undone."
	_delete_confirm_dialog.add_child(message)

	var button_container := HBoxContainer.new()
	button_container.position = Vector2(px, py + CONFIRM_DIALOG_H - 50)
	button_container.size = Vector2(CONFIRM_DIALOG_W, 40)
	button_container.add_theme_constant_override("separation", 10)
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_delete_confirm_dialog.add_child(button_container)

	var cancel_btn := Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.size = Vector2(120, 38)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_on_delete_confirm_cancel)
	button_container.add_child(cancel_btn)

	var delete_btn := Button.new()
	delete_btn.text = "DELETE"
	delete_btn.size = Vector2(120, 38)
	delete_btn.add_theme_font_size_override("font_size", 16)
	delete_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	delete_btn.pressed.connect(_on_delete_confirm_proceed)
	button_container.add_child(delete_btn)

func _on_delete_confirm_cancel() -> void:
	_delete_confirm_dialog.hide()
	_pending_delete_index = -1

func _on_delete_confirm_proceed() -> void:
	_delete_confirm_dialog.hide()
	if _pending_delete_index >= 0:
		SaveManager.delete_slot(_pending_delete_index)
		var has_saves := SaveManager.has_any_save()
		if not has_saves and _popup_mode == "continue":
			# No saves remain — close the popup and return to the parent screen
			_save_popup.hide()
			_mp_host_pending = false
		else:
			_refresh_popup()
		_continue_btn.visible = has_saves
		if _sp_continue_btn != null:
			_sp_continue_btn.visible = has_saves
		_host_save_continue_btn.visible = has_saves
		if _mp_page_host_save_continue_btn != null:
			_mp_page_host_save_continue_btn.visible = has_saves
	_pending_delete_index = -1
