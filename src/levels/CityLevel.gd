class_name CityLevel
extends Node2D

# Colony Chamber panel built programmatically
var _chamber_layer: CanvasLayer
var _chamber_buttons: Dictionary = {}   # chamber_key -> Button

const CHAMBERS: Array = [
	{
		"key": "fungus_garden",
		"name": "Fungus Garden",
		"effect": "+10% mineral yield from all tiles",
		"unlock_label": "Unlock: bank 500 minerals total",
		"cost_const": "CHAMBER_COST_FUNGUS_GARDEN",
		"built_prop": "fungus_garden_built",
	},
	{
		"key": "brood_chamber",
		"name": "Brood Chamber",
		"effect": "Forager carry cap +20",
		"unlock_label": "Unlock: defeat first boss",
		"cost_const": "CHAMBER_COST_BROOD_CHAMBER",
		"built_prop": "brood_chamber_built",
	},
	{
		"key": "armory",
		"name": "Armory",
		"effect": "Explosive blast radius +1 tile",
		"unlock_label": "Unlock: bank 1000 minerals total",
		"cost_const": "CHAMBER_COST_ARMORY",
		"built_prop": "armory_built",
	},
	{
		"key": "nursery_vault",
		"name": "Nursery Vault",
		"effect": "+5% fossil find rate",
		"unlock_label": "Unlock: find 10 fossils total",
		"cost_const": "CHAMBER_COST_NURSERY_VAULT",
		"built_prop": "nursery_vault_built",
	},
	{
		"key": "deep_antenna",
		"name": "Deep Antenna Array",
		"effect": "Sonar ping radius +3 tiles",
		"unlock_label": "Unlock: reach row 96 in a run",
		"cost_const": "CHAMBER_COST_DEEP_ANTENNA",
		"built_prop": "deep_antenna_built",
	},
]


func _ready() -> void:
	# Bank currency when entering city
	GameManager.bank_currency()

	# Start city music
	var music = load("res://assets/music/crickets.mp3")
	MusicManager.play_music(music)

	_build_chamber_panel()


func _build_chamber_panel() -> void:
	_chamber_layer = CanvasLayer.new()
	add_child(_chamber_layer)

	const PW: int = 420
	const PH: int = 460
	const PX: int = 20
	const PY: int = 130

	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.05, 0.12, 0.90)
	bg.set_position(Vector2(PX, PY))
	bg.set_size(Vector2(PW, PH))
	_chamber_layer.add_child(bg)

	var title := Label.new()
	title.text = "Colony Chambers"
	title.set_position(Vector2(PX, PY - 26))
	title.add_theme_color_override("font_color", Color(0.80, 0.60, 1.00))
	_chamber_layer.add_child(title)

	var cy := PY + 8
	for chamber in CHAMBERS:
		var built: bool = GameManager.get(chamber["built_prop"])
		var cost_val: int = GameManager.get(chamber["cost_const"])
		var unlocked: bool = _is_chamber_unlocked(chamber["key"])

		var btn := Button.new()
		btn.set_position(Vector2(PX + 8, cy))
		btn.set_size(Vector2(PW - 16, 78))
		btn.disabled = built or not unlocked or GameManager.mineral_currency < cost_val

		var status: String
		if built:
			status = "[BUILT] %s — %s" % [chamber["name"], chamber["effect"]]
		elif not unlocked:
			status = "[LOCKED] %s\n%s\n%s" % [chamber["name"], chamber["effect"], chamber["unlock_label"]]
		else:
			status = "Build %s — %s\nCost: %d Minerals" % [chamber["name"], chamber["effect"], cost_val]

		btn.text = status
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_chamber_pressed.bind(chamber["key"]))
		_chamber_layer.add_child(btn)
		_chamber_buttons[chamber["key"]] = btn

		cy += 84


func _is_chamber_unlocked(key: String) -> bool:
	match key:
		"fungus_garden":
			return GameManager.total_minerals_banked >= 500
		"brood_chamber":
			return GameManager.bosses_defeated_total >= 1
		"armory":
			return GameManager.total_minerals_banked >= 1000
		"nursery_vault":
			return GameManager.total_fossils >= 10
		"deep_antenna":
			return GameManager.deepest_row_reached >= 96
	return false


func _on_chamber_pressed(key: String) -> void:
	for chamber in CHAMBERS:
		if chamber["key"] != key:
			continue
		var built: bool = GameManager.get(chamber["built_prop"])
		var cost_val: int = GameManager.get(chamber["cost_const"])
		if built or not _is_chamber_unlocked(key) or GameManager.mineral_currency < cost_val:
			return
		GameManager.mineral_currency -= cost_val
		GameManager.set(chamber["built_prop"], true)
		GameManager.save_game()
		_refresh_chamber_panel()
		break


func _refresh_chamber_panel() -> void:
	for chamber in CHAMBERS:
		var btn: Button = _chamber_buttons.get(chamber["key"])
		if not btn:
			continue
		var built: bool = GameManager.get(chamber["built_prop"])
		var cost_val: int = GameManager.get(chamber["cost_const"])
		var unlocked: bool = _is_chamber_unlocked(chamber["key"])

		btn.disabled = built or not unlocked or GameManager.mineral_currency < cost_val

		if built:
			btn.text = "[BUILT] %s — %s" % [chamber["name"], chamber["effect"]]
		elif not unlocked:
			btn.text = "[LOCKED] %s\n%s\n%s" % [chamber["name"], chamber["effect"], chamber["unlock_label"]]
		else:
			btn.text = "Build %s — %s\nCost: %d Minerals" % [chamber["name"], chamber["effect"], cost_val]


func _on_return_button_pressed() -> void:
	GameManager.load_overworld()
