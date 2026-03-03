extends Node

# Global Event Bus
# Use this to decouple systems.

# Mining Signals
signal ore_mined(ore_type: String, amount: int) # Deprecated
signal mining_started(node: Node)
signal mining_finished(node: Node, success: bool)

# Player Signals
signal player_health_changed(new_health: float, max_health: int)
signal player_died
signal inventory_updated(item_name: String, quantity: int)

# Game State Signals
signal game_state_changed(new_state: int)

# Currency Signals
signal minerals_changed(amount: int)
signal minerals_earned(amount: int)  # Emitted with each individual mining earn
signal ore_mined_popup(amount: int, ore_name: String)  # Emitted on mine with ore type for HUD popup
signal boss_hint_popup(hint: String)  # Boss instructions and attack warnings — routed to a dedicated centre-bottom panel
signal ladder_count_changed(count: int)  # Emitted when the player's ladder inventory changes
signal dollars_changed(amount: int)  # Emitted when player's dollar balance changes

# Energy Signals
signal energy_changed(current_energy: int, max_energy: int)

# Depth Signals
signal depth_changed(depth_rows: int)  # Rows below surface (0 = surface)

# Multiplayer Signals
signal multiplayer_guest_connected(peer_id: int)    # Host: a guest joined
signal multiplayer_guest_disconnected               # Host: guest left mid-session
signal multiplayer_connected_to_host               # Guest: successfully connected
signal multiplayer_connection_failed               # Guest: connection attempt failed
signal multiplayer_guest_kit_updated               # Guest HUD should refresh to show host's kit
signal chat_message_received(sender_name: String, message: String)  # Chat message delivered to local screen
