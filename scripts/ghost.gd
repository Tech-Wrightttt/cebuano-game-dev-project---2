extends CharacterBody3D
@onready var agent =$NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
var speed = 2.0
@onready var rng = RandomNumberGenerator.new()
@onready var animation_player = $ghost_model_animation.get_node("AnimationPlayer")
var destination
var chasing = false
var destination_value
var chase_timer = 0.0
var last_position: Vector3
var stuck_timer: float = 0.0
var frame_counter: int = 0

func _ready() -> void:
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
	print("👻 GHOST INITIALIZING...")
	animation_player.play("ghost_idle")
	
	print("⏱️ Waiting 2 seconds before starting...")
	await get_tree().create_timer(2.0).timeout
	
	print("Ghost ready! Collision layer: ", collision_layer)
	print("Ghost collision mask: ", collision_mask)
	print("Ghost spawn position: ", global_position)
	print("Patrol destinations count: ", patrol_destinations.size())
	
	last_position = global_position
	pick_destination()
	print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

func _process(delta: float) -> void:
	if chasing:
		if speed != 4.0:
			print("🏃 CHASE MODE ACTIVATED - Speed changed to 4.0")
			speed = 4.0
		if chase_timer < 15:
			chase_timer += 1 * delta
		else:
			print("⏰ Chase timer expired - Ending chase")
			chase_timer = 0.0
			chasing = false
			print("📍 Returning to patrol mode")
	elif !chasing:
		if speed != 2.0:
			print("🚶 PATROL MODE - Speed changed to 2.0")
			speed = 2.0
		if animation_player.current_animation != "ghost_idle":
			animation_player.play("ghost_idle")
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if destination != null:
		# Look at the NEXT NAVIGATION POINT, not the final destination
		var next_location = agent.get_next_path_position()
		var direction_to_next = (next_location - global_position).normalized()
		
		# Only rotate on the Y axis (ignore vertical direction)
		var look_dir = lerp_angle(
			deg_to_rad(global_rotation_degrees.y), 
			atan2(-direction_to_next.x, -direction_to_next.z), 
			0.1  # Lower value = smoother rotation
		)
		global_rotation_degrees.y = rad_to_deg(look_dir)
		
		update_target_location()

func _physics_process(_delta: float) -> void:
	frame_counter += 1
	
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)
	
	if destination != null:
		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()
		
		# Stuck detection
		var distance_moved = global_position.distance_to(last_position)
		if distance_moved < 0.05:
			stuck_timer += _delta
			if stuck_timer > 2.5:
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
				print("⚠️ GHOST STUCK DETECTED!")
				print("  Position: ", global_position)
				print("  Current destination: ", destination.name)
				print("  Distance moved: %.3f" % distance_moved)
				print("  Stuck timer: %.2f seconds" % stuck_timer)
				print("  → Picking new destination...")
				stuck_timer = 0.0
				pick_destination()
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
				return
		else:
			if stuck_timer > 0:
				stuck_timer = 0.0
		
		last_position = global_position
		
		# Navigation finished check
		if agent.is_navigation_finished() and !chasing:
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
			print("✅ REACHED DESTINATION: ", destination.name)
			print("  Ghost position: ", global_position)
			print("  Destination position: ", destination.global_position)
			print("  → Picking next destination...")
			pick_destination(destination_value)
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
			return
		
		# Debug info every 120 frames (every 2 seconds at 60fps)
		if frame_counter % 120 == 0:
			var distance_to_dest = current_location.distance_to(destination.global_position)
			var distance_to_next = current_location.distance_to(next_location)
			print("━━━ GHOST STATUS (Frame ", frame_counter, ") ━━━")
			print("  Position: ", current_location)
			print("  Destination: ", destination.name, " at ", destination.global_position)
			print("  Distance to destination: %.2f" % distance_to_dest)
			print("  Distance to next nav point: %.2f" % distance_to_next)
			print("  Navigation finished: ", agent.is_navigation_finished())
			print("  Chasing: ", chasing)
			print("  Speed: ", speed)
			print("  Velocity magnitude: %.2f" % velocity.length())
			print("  Stuck timer: %.2f" % stuck_timer)
			print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		
		var new_velocity = (next_location - current_location).normalized() * speed
		animation_player.play("ghost_walk")
		$NavigationAgent3D.set_velocity(new_velocity)
		velocity = velocity.move_toward(new_velocity, speed)
		
		# Allow a bit of upward movement when near stairs
		if not is_on_floor() and velocity.y <= 0:
			if global_transform.origin.y < destination.global_transform.origin.y + 0.3:
				velocity.y = 1.0
				
		move_and_slide()

func chase_player(cast: RayCast3D):
	if cast.is_colliding():
		var hit = cast.get_collider()
		if hit and hit.is_in_group("player"):
			if not chasing:
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
				print("👁️ PLAYER SPOTTED by ", cast.name, "!")
				print("  Player position: ", player.global_position)
				print("  Ghost position: ", global_position)
				print("  → Starting chase!")
				print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
			chasing = true
			destination = player

func pick_destination(dont_choose = null):
	if !chasing:
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
		print("🎲 PICKING NEW DESTINATION...")
		print("  Patrol destinations available: ", patrol_destinations.size())
		print("  Avoiding destination_value: ", dont_choose if dont_choose != null else "none")
		
		var num = rng.randi_range(0, patrol_destinations.size() - 1)
		destination_value = num
		destination = patrol_destinations[num]
		
		print("  Random roll: ", num)
		print("  Initial pick: ", destination.name if destination else "null")
		
		# Make sure it doesn't choose the same as dont_choose
		if destination != null and dont_choose != null and destination == patrol_destinations[dont_choose]:
			print("  ⚠️ Picked same as dont_choose! Adjusting...")
			if dont_choose <= 0:
				destination = patrol_destinations[dont_choose + 1]
				destination_value = dont_choose + 1
			elif dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
				destination = patrol_destinations[dont_choose - 1]
				destination_value = dont_choose - 1
			print("  → Adjusted to: ", destination.name)
				
		print("=== PICKED DESTINATION ===")
		print("Destination name: ", destination.name if destination else "null")
		print("Destination position: ", destination.global_position if destination else "null")
		print("Destination value: ", destination_value)
		
		stuck_timer = 0.0
		update_target_location()
		print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

func update_target_location():
	var old_target = agent.target_position
	agent.target_position = destination.global_transform.origin
	
	# Only log if target actually changed (to avoid spam during chasing)
	if old_target.distance_to(agent.target_position) > 0.1:
		print("🎯 Navigation target updated to: ", agent.target_position)

func compute_velocity(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, speed)
	move_and_slide()
