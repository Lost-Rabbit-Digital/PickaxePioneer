class_name RunSummary
extends CanvasLayer

@onready var scrap_label: Label = $Control/Panel/ScrapLabel
@onready var return_button: Button = $Control/Panel/ReturnButton

func _ready() -> void:
	scrap_label.text = "Scrap Collected: %d" % GameManager.run_scrap_currency
	return_button.pressed.connect(_on_return_pressed)

func _on_return_pressed() -> void:
	GameManager.bank_currency()
	queue_free()
	GameManager.load_overworld()
