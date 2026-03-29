class_name ScrapLoot
extends LootBase

## Scrap loot — generic collectible that awards currency.

@export var scrap_value: int = 1


func _on_collect() -> void:
	GameManager.add_currency(scrap_value)
