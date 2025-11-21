extends SceneTree

func _init():
	print("Running Tests...")
	test_health_component()
	quit()

func test_health_component():
	print("Testing HealthComponent...")
	var health_comp = load("res://src/components/HealthComponent.gd").new()
	health_comp.max_health = 100
	health_comp._ready()
	
	assert(health_comp.current_health == 100, "Initial health should be 100")
	
	health_comp.damage(30)
	assert(health_comp.current_health == 70, "Health should be 70 after 30 damage")
	
	health_comp.heal(10)
	assert(health_comp.current_health == 80, "Health should be 80 after 10 healing")
	
	health_comp.damage(100)
	assert(health_comp.current_health == 0, "Health should be 0 after lethal damage")
	
	print("HealthComponent Tests Passed!")
