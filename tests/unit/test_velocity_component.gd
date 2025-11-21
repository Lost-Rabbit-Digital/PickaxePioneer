extends GutTest

func test_acceleration():
	var velocity_comp = load("res://src/components/VelocityComponent.gd").new()
	velocity_comp.max_speed = 100.0
	velocity_comp.acceleration = 100.0
	
	# Simulate 1 second of acceleration
	velocity_comp.accelerate(Vector2.RIGHT, 1.0)
	
	assert_eq(velocity_comp.velocity, Vector2(100, 0), "Should accelerate to max speed")
	velocity_comp.free()

func test_friction():
	var velocity_comp = load("res://src/components/VelocityComponent.gd").new()
	velocity_comp.velocity = Vector2(100, 0)
	velocity_comp.friction = 50.0
	
	# Simulate 1 second of friction
	velocity_comp.decelerate(1.0)
	
	assert_eq(velocity_comp.velocity, Vector2(50, 0), "Should decelerate by friction amount")
	velocity_comp.free()
