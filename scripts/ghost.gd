extends CharacterBody3D
@onready var agent = $NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
@onready var lana_task = get_tree().get_first_node_in_group("lana_task")
var speed = 2.0
@onready var rng = RandomNumberGenerator.new()
@onready var animation_player = $ghost_model_animation.get_node("AnimationPlayer")
var destination
var chasing = false
var destination_value
var chase_timer = 0.0
var lured = false
var lure_target_position: Vector3
var previous_lure_position: Vector3
var has_previous_lure = false
var lure_consumption_distance = 2.0
var last_known_lure_pos: Vector3 = Vector3.ZERO

func _ready() -> void:
	animation_player.play("ghost_idle")
	await get_tree().create_timer(2.0).timeout
	
	if lana_task:
		lana_task.add_to_group("lana_task")
		print("✅ Ghost found lana_task")
	else:
		print("❌ lana_task not found!")
	
	pick_destination()

func _process(delta: float) -> void:
	# ALWAYS check for new lures, even while patrolling (but not while chasing player)
	if not chasing and lana_task:
		check_for_new_lure()
	
	if chasing:
		if speed != 4.0:
			speed = 4.0
		if chase_timer < 15:
			chase_timer += 1 * delta
		else:
			chase_timer = 0.0
			chasing = false
			# Resume lure behavior after chase ends
			resume_lure_behavior()
	elif !chasing:
		if speed != 2.0:
			speed = 2.0
		if animation_player.current_animation != "ghost_idle":
			animation_player.play("ghost_idle")
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Update navigation target based on state (FIXED - works even when destination is null)
	if lured:
		$NavigationAgent3D.target_position = lure_target_position
	elif destination != null:
		update_target_location()
	
	# Rotation code (works with both lured and destination states)
	if destination != null or lured:
		var look_dir = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.5)
		global_rotation_degrees.y = rad_to_deg(look_dir)

func _physics_process(_delta: float) -> void:
	# Player chase ALWAYS has priority over everything
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)
	
	# Check if reached lure position
	if lured:
		var dist_to_lure = global_position.distance_to(lure_target_position)
		if dist_to_lure < lure_consumption_distance:
			consume_lure()

	# Move if we have a destination OR are lured
	if destination != null or lured:
		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()

		var new_velocity = (next_location - current_location).normalized() * speed
		animation_player.play("ghost_walk")
		$NavigationAgent3D.set_velocity(new_velocity)
		velocity = velocity.move_toward(new_velocity, speed)

		if not is_on_floor() and velocity.y <= 0:
			var next_pos = agent.get_next_path_position()
			var y_diff = next_pos.y - global_transform.origin.y
			
			if y_diff > 0.1 and y_diff < 1.5:
				velocity.y = 1.0

		move_and_slide()

func chase_player(cast: RayCast3D):
	if cast.is_colliding():
		var hit = cast.get_collider()
		if hit and hit.is_in_group("player"):
			if not chasing:
				# Save current lure position before chasing
				if lured:
					previous_lure_position = lure_target_position
					has_previous_lure = true
					print("🎯 Ghost spotted player! Saving lure position: ", previous_lure_position)
			chasing = true
			lured = false  # Pause lure behavior while chasing
			destination = player

# Check if a new lure was deployed
func check_for_new_lure() -> void:
	var current_pos = lana_task.current_lana_pos
	
	# Check if position is valid (not zero) and different from what we know
	if current_pos != Vector3.ZERO and current_pos != last_known_lure_pos:
		print("🔔 Ghost detected NEW lure at: ", current_pos)
		print("🚫 CANCELING PATROL - Going to lure immediately!")
		last_known_lure_pos = current_pos
		
		# IMMEDIATELY switch to lured mode
		lured = true
		lure_target_position = current_pos
		destination = null  # Cancel patrol destination
		$NavigationAgent3D.target_position = lure_target_position
		print("🏃 Ghost heading straight to lure!")

# Resume lure behavior after player chase ends
func resume_lure_behavior() -> void:
	if has_previous_lure:
		# Check if the lure we were chasing still exists
		var lure_still_exists = is_lure_still_there(previous_lure_position)
		
		if lure_still_exists:
			print("🔙 Ghost resuming pursuit of saved lure at: ", previous_lure_position)
			lured = true
			lure_target_position = previous_lure_position
			destination = null
			$NavigationAgent3D.target_position = lure_target_position
			has_previous_lure = false
			return
		else:
			print("❌ Saved lure no longer exists")
			has_previous_lure = false
	
	# Check if there's any active lure
	if lana_task.current_lana_pos != Vector3.ZERO:
		print("🔄 Found another active lure, heading there!")
		lured = true
		lure_target_position = lana_task.current_lana_pos
		last_known_lure_pos = lana_task.current_lana_pos
		destination = null
		$NavigationAgent3D.target_position = lure_target_position
		return
	
	# No lures available, go back to patrolling
	print("📍 No lures available, resuming patrol")
	pick_destination()

# Check if lure still exists
func is_lure_still_there(pos: Vector3) -> bool:
	var tolerance = 1.0
	for id in lana_task.lana_map.keys():
		var data = lana_task.lana_map[id]
		if data["drop"] and data["drop"].visible:
			var distance = data["drop"].global_position.distance_to(pos)
			if distance < tolerance:
				return true
	return false

# Consume lure when reached
func consume_lure() -> void:
	if lana_task:
		print("😋 Ghost reached and consumed lure at: ", lure_target_position)
		lana_task.consume_lure_at_position(lure_target_position)
		
		# Clear lure tracking
		lured = false
		has_previous_lure = false
		
		# Reset current_lana_pos if it matches what we consumed
		if lana_task.current_lana_pos.distance_to(lure_target_position) < 2.0:
			lana_task.current_lana_pos = Vector3.ZERO
			last_known_lure_pos = Vector3.ZERO
		
		# Check if there's another lure, otherwise patrol
		if lana_task.current_lana_pos != Vector3.ZERO:
			print("🔄 Another lure detected, going there next!")
			lured = true
			lure_target_position = lana_task.current_lana_pos
			last_known_lure_pos = lana_task.current_lana_pos
			$NavigationAgent3D.target_position = lure_target_position
		else:
			print("📍 No more lures, resuming patrol")
			pick_destination()

func pick_destination(dont_choose = null):
	# Only pick patrol destinations when NOT lured and NOT chasing
	if !chasing and !lured:
		var num = rng.randi_range(0, patrol_destinations.size() - 1)
		destination_value = num
		destination = patrol_destinations[num]

		if destination != null and dont_choose != null and destination == patrol_destinations[dont_choose]:
			if dont_choose <= 0:
				destination = patrol_destinations[dont_choose + 1]
			elif dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
				destination = patrol_destinations[dont_choose - 1]
				
func update_target_location():
	if destination:
		$NavigationAgent3D.target_position = destination.global_transform.origin

func compute_velocity(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, speed)
	move_and_slide()
