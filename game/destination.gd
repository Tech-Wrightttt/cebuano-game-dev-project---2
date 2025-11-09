extends Node3D
@onready var rng = RandomNumberGenerator.new()
var ghost_in_trigger = false

func enter_trigger(body):
	#print("enter_trigger called with body: ", body.name)
	if body.name == "ghost" and not ghost_in_trigger:
		ghost_in_trigger = true
		#print("Ghost entered trigger! Starting wait sequence...")
		
		# Wait a tiny bit for navigation to settle
		await get_tree().create_timer(0.2).timeout
		
		# Now wait the random patrol time
		var wait_time = rng.randf_range(1.0, 8.0)
		#print("Waiting for ", wait_time, " seconds...")
		await get_tree().create_timer(wait_time).timeout
		
		#print("Wait finished. Ghost chasing? ", body.chasing)
		# Check if ghost is still not chasing before picking new destination
		if not body.chasing:
			body.pick_destination(body.destination_value)
			#print("Picked new destination, avoiding index: ", body.destination_value)
		
		ghost_in_trigger = false
