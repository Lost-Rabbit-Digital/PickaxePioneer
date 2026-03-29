class_name CooldownTimer
extends RefCounted

## Lightweight countdown timer for the repeated "tick then fire" pattern.
## Not a Godot Timer node — just a simple elapsed/duration tracker.

var duration: float
var _remaining: float

func _init(p_duration: float, start_ready: bool = false) -> void:
	duration = p_duration
	_remaining = 0.0 if start_ready else p_duration

## Advance the timer by delta. Returns true once when the timer fires.
func tick(delta: float) -> bool:
	_remaining -= delta
	if _remaining <= 0.0:
		_remaining += duration
		return true
	return false

## Reset the timer to full duration.
func reset() -> void:
	_remaining = duration

## Force the timer to fire on the next tick.
func expire() -> void:
	_remaining = 0.0

## Returns the fraction of time elapsed (0.0 = just reset, 1.0 = about to fire).
func progress() -> float:
	return 1.0 - clampf(_remaining / duration, 0.0, 1.0)
