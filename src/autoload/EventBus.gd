extends Node

# Global Event Bus
# Use this to decouple systems.

# Mining Signals
signal ore_mined(ore_type: String, amount: int) # Deprecated
signal mining_started(node: Node)
signal mining_finished(node: Node, success: bool)

# Player Signals
signal player_health_changed(new_health: int, max_health: int)
signal player_died
signal inventory_updated(item_name: String, quantity: int)

# Game State Signals
signal game_state_changed(new_state: int)

# Currency Signals
signal scrap_changed(amount: int)
