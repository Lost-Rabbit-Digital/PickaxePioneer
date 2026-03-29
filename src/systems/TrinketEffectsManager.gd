class_name TrinketEffectsManager
extends RefCounted

## Per-frame trinket passive effects extracted from PlayerProbe.
## Manages regen, boots energy, curse damage, and cosmic bitflip timers.
## PlayerProbe calls update() each frame and acts on the returned actions.

const REGEN_INTERVAL: float = 4.0
const CURSE_DAMAGE_INTERVAL: float = 8.0
const COSMIC_INTERVAL: float = 15.0

var _regen_timer: float = 0.0
var _boots_energy_accum: float = 0.0
var _curse_timer: float = 0.0
var _cosmic_timer: float = 0.0


## Advance all trinket timers. Returns a dictionary of actions to perform:
## - "heal": int (HP to restore, 0 if none)
## - "energy_restore": int (energy to restore, 0 if none)
## - "curse_damage": int (damage to deal, 0 if none)
## - "cosmic_bitflip": bool (whether to trigger a random bitflip)
func update(delta: float, is_underground: bool, is_on_floor: bool,
		is_moving: bool, current_hp: int, max_hp: int) -> Dictionary:
	var actions := {"heal": 0, "energy_restore": 0, "curse_damage": 0, "cosmic_bitflip": false}

	# Stone of Regeneration — +1 HP every 4 sec
	if GameManager.trinket_stone_of_regen:
		_regen_timer += delta
		if _regen_timer >= REGEN_INTERVAL:
			_regen_timer -= REGEN_INTERVAL
			if current_hp < max_hp:
				actions["heal"] = 1
	else:
		_regen_timer = 0.0

	# Boots of Sprinting — +1 energy/sec while walking on ground
	if GameManager.trinket_boots_of_sprinting:
		if is_on_floor and is_moving:
			_boots_energy_accum += delta
			if _boots_energy_accum >= 1.0:
				_boots_energy_accum -= 1.0
				actions["energy_restore"] = 1
		else:
			_boots_energy_accum = 0.0
	else:
		_boots_energy_accum = 0.0

	# Curse of the Core — -1 HP every 8 sec underground
	if GameManager.trinket_curse_of_core and is_underground:
		_curse_timer += delta
		if _curse_timer >= CURSE_DAMAGE_INTERVAL:
			_curse_timer -= CURSE_DAMAGE_INTERVAL
			actions["curse_damage"] = 1
	else:
		_curse_timer = 0.0

	# Cosmic Radiation — random bitflip every 15 sec underground
	if GameManager.trinket_cosmic_radiation and is_underground:
		_cosmic_timer += delta
		if _cosmic_timer >= COSMIC_INTERVAL:
			_cosmic_timer -= COSMIC_INTERVAL
			actions["cosmic_bitflip"] = true
	else:
		_cosmic_timer = 0.0

	return actions


## Reset all timers (call at start of a new mine run).
func reset() -> void:
	_regen_timer = 0.0
	_boots_energy_accum = 0.0
	_curse_timer = 0.0
	_cosmic_timer = 0.0
