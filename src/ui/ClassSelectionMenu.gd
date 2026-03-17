extends CanvasLayer
## Class selection screen shown after choosing a save slot on New Game.
## Displays a horizontal scrollable row of class cards.  Emits [signal class_confirmed]
## with the chosen class id when the player clicks "BEGIN RUN".
## Emits [signal cancelled] when the player clicks "BACK".
##
## The UI is defined in ClassSelection.tscn.  Card0..Card9 in the HBoxContainer
## must remain in the same order as CLASS_IDS below.

signal class_confirmed(class_id: String)
signal cancelled

## Class IDs in the same order as Card0..Card9 in ClassSelection.tscn.
const CLASS_IDS: Array[String] = [
	"pioneer", "prospector", "brawler", "veteran", "scout",
	"engineer", "alchemist", "sentinel", "wanderer", "phantom",
]

const ACCENT_COLOR: Color = Color(0.90, 0.70, 0.28)

var _selected_index: int = -1
## Selection border ColorRects, one per card (populated in _ready).
var _card_borders: Array[ColorRect] = []

@onready var _hbox: HBoxContainer = $Root/ScrollContainer/CenterContainer/HBoxContainer
@onready var _confirm_btn: Button = $Root/BottomAnchor/BtnCenter/ConfirmButton
@onready var _back_btn: Button = $Root/BottomAnchor/BackButton


func _ready() -> void:
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	_back_btn.pressed.connect(_on_back_pressed)
	_wire_cards()


func _wire_cards() -> void:
	for i: int in range(_hbox.get_child_count()):
		var card := _hbox.get_child(i) as Control
		var border := card.get_node("Border") as ColorRect
		_card_borders.append(border)

		var lock_overlay := card.get_node("LockOverlay") as Control
		var click_btn := card.get_node("ClickButton") as Button

		# Runtime unlock based on global progress
		if lock_overlay.visible and GameManager.global_player_level >= 2:
			lock_overlay.visible = false
			click_btn.disabled = false

		if not click_btn.disabled:
			var idx := i
			click_btn.pressed.connect(func() -> void: _on_card_clicked(idx))
			click_btn.mouse_entered.connect(func() -> void: _on_card_hover(idx, true))
			click_btn.mouse_exited.connect(func() -> void: _on_card_hover(idx, false))


func _on_card_clicked(index: int) -> void:
	_selected_index = index
	_confirm_btn.disabled = false
	_update_selection_visuals()
	SoundManager.play_ui_click_sound()


func _on_card_hover(index: int, entered: bool) -> void:
	if index == _selected_index:
		return
	_card_borders[index].color = Color("222034ff") if entered else Color(0.0, 0.0, 0.0, 0.0)


func _update_selection_visuals() -> void:
	for i: int in range(_card_borders.size()):
		_card_borders[i].color = ACCENT_COLOR if i == _selected_index else Color(0.0, 0.0, 0.0, 0.0)


func _on_back_pressed() -> void:
	SoundManager.play_ui_close_sound()
	cancelled.emit()
	queue_free()


func _on_confirm_pressed() -> void:
	if _selected_index < 0:
		return
	GameManager.player_class = CLASS_IDS[_selected_index]
	SoundManager.play_ui_click_sound()
	class_confirmed.emit(GameManager.player_class)
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _selected_index >= 0:
		_on_confirm_pressed()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
