extends GutTest

func test_damage():
	var health_comp = load("res://src/components/HealthComponent.gd").new()
	health_comp.max_health = 100
	health_comp._ready()
	
	watch_signals(health_comp)
	
	health_comp.damage(10)
	
	assert_eq(health_comp.current_health, 90, "Health should decrease")
	assert_signal_emitted(health_comp, "health_changed", "Signal should emit")
	health_comp.free()

func test_death():
	var health_comp = load("res://src/components/HealthComponent.gd").new()
	health_comp.max_health = 10
	health_comp._ready()
	
	watch_signals(health_comp)
	
	health_comp.damage(10)
	
	assert_signal_emitted(health_comp, "died", "Died signal should emit")
	health_comp.free()
