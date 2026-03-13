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
## Emitted whenever the run wallet (run_coins) or persistent wallet (coins) changes.
## `copper` is the new total of the wallet that changed (run or persistent).
signal coins_changed(copper: int)
## Emitted with each individual ore/bonus earn event (copper amount).
signal coins_earned(copper: int)
signal ore_mined_popup(amount: int, ore_name: String)  # Emitted on mine with ore type for HUD popup
signal boss_hint_popup(hint: String)  # Boss instructions and attack warnings — routed to a dedicated centre-bottom panel
signal ladder_count_changed(count: int)  # Emitted when the player's ladder inventory changes

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
signal chat_message_received(sender_name: String, message: String, sender_color: Color)  # Chat message delivered to local screen
signal game_notification(message: String, color: Color)  # Single-player game events shown in the chat log (streaks, NPC interactions, etc.)

# Perk / XP Signals
signal xp_changed(current_xp: int, xp_to_next: int)   # Emitted whenever XP changes
signal player_leveled_up(new_level: int, perk_points: int)  # Emitted on each level-up
signal perk_points_changed(perk_points: int)            # Emitted when points are spent/gained

# Trinket Signals
signal trinket_equipped(trinket_id: String)  # Emitted when a trinket is equipped or unequipped

# Save Signals
## Emitted by GameManager just before a save so MiningLevel can flush its current
## terrain state into GameManager before the snapshot is taken.
signal mining_state_capture_requested
