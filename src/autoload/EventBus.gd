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
signal minerals_changed(amount: int)
signal minerals_earned(amount: int)  # Emitted with each individual mining earn
signal ore_mined_popup(amount: int, ore_name: String)  # Emitted on mine with ore type for HUD popup

# Fuel Signals
signal fuel_changed(current_fuel: int, max_fuel: int)

# Depth Signals
signal depth_changed(depth_rows: int)  # Rows below surface (0 = surface)
