extends Node3D
@onready var rng = RandomNumberGenerator.new()
var ghost_in_trigger = false

func enter_trigger(body):
	if body.name == "ghost" and not ghost_in_trigger:
		ghost_in_trigger = true
		
		await get_tree().create_timer(0.2).timeout
		var wait_time = rng.randf_range(1.0, 8.0)
		await get_tree().create_timer(wait_time).timeout

		if not body.chasing:
			# --- SPECIAL RULE ---
			if self.name == "destination12":
				print("Ghost reached Destination12 — next will be forced to Destination1.")
				for node in body.patrol_destinations:
					if node.name == "destination1":
						body.destination = node
						body.destination_value = body.patrol_destinations.find(node)
						body.update_target_location()
						break
			else:
				body.pick_destination(body.destination_value)
		
		ghost_in_trigger = false
