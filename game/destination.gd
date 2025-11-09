extends Node3D
@onready var rng = RandomNumberGenerator.new()
var ghost_in_trigger = false

func enter_trigger(body):
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("🚪 TRIGGER ENTERED: ", self.name)
	print("Body detected: ", body.name if body else "null")
	
	if body.name == "ghost" and not ghost_in_trigger:
		print("✅ Ghost confirmed, trigger not active yet")
		
		# CHECK: Is ghost close enough to THIS destination?
		var distance_to_trigger = body.global_position.distance_to(self.global_position)
		print("  Distance to trigger: %.2f" % distance_to_trigger)
		
		if distance_to_trigger > 2.0:
			print("  ⚠️ Ghost too far from trigger center - ignoring")
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
			return
		
		# CHECK: Is this trigger the current destination?
		if body.destination != self:
			print("  ⚠️ Ghost's destination is ", body.destination.name, " not ", self.name, " - ignoring")
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
			return
		
		ghost_in_trigger = true
		
		print("⏱️ Initial wait: 0.2 seconds...")
		await get_tree().create_timer(0.2).timeout
		
		var wait_time = rng.randf_range(1.0, 8.0)
		print("⏱️ Random wait time: %.2f seconds" % wait_time)
		await get_tree().create_timer(wait_time).timeout
		
		print("🔍 Checking ghost state...")
		print("  - Ghost chasing: ", body.chasing)
		print("  - Current destination: ", body.destination.name if body.destination else "null")
		print("  - Current destination_value: ", body.destination_value)
		
		if not body.chasing:
			print("👻 Ghost NOT chasing - proceeding with destination change")
			
			# --- SPECIAL RULE ---
			if self.name == "destination12":
				print("🎯 SPECIAL RULE: Destination12 detected!")
				print("  → Forcing next destination to Destination1...")
				
				var found = false
				for node in body.patrol_destinations:
					if node.name == "destination1":
						print("  ✅ Found Destination1 in patrol list")
						body.destination = node
						body.destination_value = body.patrol_destinations.find(node)
						print("  → Set destination_value to: ", body.destination_value)
						body.update_target_location()
						print("  → Target location updated")
						found = true
						break
				
				if not found:
					print("  ⚠️ WARNING: Destination1 NOT found in patrol_destinations!")
			else:
				print("📍 Regular destination - calling pick_destination()")
				print("  → Avoiding destination_value: ", body.destination_value)
				body.pick_destination(body.destination_value)
		else:
			print("🏃 Ghost IS chasing - skipping destination change")
		
		ghost_in_trigger = false
		print("🔓 Trigger released")
	else:
		if body.name != "ghost":
			print("❌ Not a ghost (body name: ", body.name, ")")
		if ghost_in_trigger:
			print("⏳ Trigger already active, ignoring")
	
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
