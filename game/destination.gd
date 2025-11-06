extends Node3D
@onready var rng = RandomNumberGenerator.new()

func enter_trigger(body):
	if body.name == "ghost":
		var agent: NavigationAgent3D = body.get_node("NavigationAgent3D")
		
		if agent and agent.is_navigation_finished():
			# Ghost reached destination, wait then pick new one
			await get_tree().create_timer(rng.randf_range(1.0, 8.0)).timeout
			
			# Check if ghost is still not chasing before picking new destination
			if not body.chasing:
				body.pick_destination(body.destination_value)
				print("Picked new destination, avoiding index: ", body.destination_value)
