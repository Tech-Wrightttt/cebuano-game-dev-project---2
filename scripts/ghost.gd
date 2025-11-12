extends CharacterBody3D

@onready var agent = $NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
@onready var lana_task = get_tree().get_first_node_in_group("lana_task")
@onready var animation_player = $ghost_final_animation/AnimationPlayer
@onready var rng = RandomNumberGenerator.new()

# for audio
@export var walking_audio : Array[AudioStream]
var can_play_ambient = true
var has_spotted_player = false 

var speed = 2.0
var destination
var destination_value
var chasing = false
var chase_timer = 0.0
var lured = false
var lure_target_position: Vector3
var previous_lure_position: Vector3
var has_previous_lure = false
var lure_consumption_distance = 2.0
var last_known_lure_pos: Vector3 = Vector3.ZERO
var killed = false
var player_in_range = false
var performing_jumpscare = false  # Prevent multiple jumpscares
var ghost_disabled = false  # NEW: Completely disable ghost during respawn/game over

func _ready() -> void:
	visible = true
	animation_player.play("ghost_idle")
	await get_tree().create_timer(2.0).timeout
	
	if lana_task:
		lana_task.add_to_group("lana_task")
		print("✅ Ghost found lana_task")
	else:
		print("❌ lana_task not found!")
	pick_destination()

func _process(delta: float) -> void:
	# CRITICAL: Don't process ANYTHING if ghost is disabled
	if ghost_disabled or performing_jumpscare:
		return
		
	# Check for player proximity every frame
	check_player_distance()

	# Check for new lures while not chasing
	if not chasing and lana_task:
		check_for_new_lure()
	
	if chasing:
		if speed != 4.0:
			speed = 4.0
		if chase_timer < 15:
			chase_timer += 1 * delta
		else:
			print("⏱️ Chase timer expired (15s)")
			chase_timer = 0.0
			chasing = false
			resume_lure_behavior()
	elif !chasing:
		if speed != 2.0:
			speed = 2.0
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Update navigation target based on state
	if lured:
		agent.target_position = lure_target_position
	elif destination != null:
		update_target_location()
	
	# Rotation for smooth facing direction
	if destination != null or lured:
		var look_dir = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.5)
		global_rotation_degrees.y = rad_to_deg(look_dir)

func _physics_process(delta: float) -> void:
	# CRITICAL: Don't process physics if ghost is disabled
	if ghost_disabled or performing_jumpscare:
		velocity = Vector3.ZERO
		return
		
	# RAYCAST CHASE - Player detection has TOP priority
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)

	# Check if reached lure
	if lured:
		var dist_to_lure = global_position.distance_to(lure_target_position)
		if dist_to_lure < lure_consumption_distance:
			consume_lure()

	# Move ghost - needs a valid destination OR lure target
	if destination != null or lured or chasing:
		var current_location = global_transform.origin
		var next_location = agent.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * speed
		
		# Play appropriate animation based on actual velocity after move_and_slide
		if velocity.length() > 0.5:  # Ghost is actually moving
			if animation_player.current_animation != "ghost_walk":
				animation_player.play("ghost_walk")
		else:  # Ghost is standing still
			if animation_player.current_animation != "ghost_idle":
				animation_player.play("ghost_idle")
		
		agent.set_velocity(new_velocity)
		velocity = velocity.move_toward(new_velocity, speed)

		if not is_on_floor() and velocity.y <= 0:
			var next_pos = agent.get_next_path_position()
			var y_diff = next_pos.y - global_transform.origin.y
			if y_diff > 0.1 and y_diff < 1.5:
				velocity.y = 1.0

		footsteps()
		move_and_slide()
	
	# Jumpscare/haunt system - ONLY when chasing
	if chasing and not performing_jumpscare:
		haunt_player()

# 👁️ RAYCAST CHASE - Detects player through raycasts
func chase_player(cast: RayCast3D):
	if ghost_disabled or performing_jumpscare:
		return
		
	if cast.is_colliding():
		var hit = cast.get_collider()
		if hit and hit.is_in_group("player"):
			if not has_spotted_player:
				$near_audio.play()
				has_spotted_player = true
			
			if not chasing:
				# Save current lure position before chasing
				if lured:
					previous_lure_position = lure_target_position
					has_previous_lure = true
					print("💾 Saved lure position: ", previous_lure_position)
			chasing = true
			lured = false  # Pause lure behavior while chasing
			destination = player

# 👁️ PROXIMITY DETECTION - 1.5m instant detection
func check_player_distance():
	if not player or ghost_disabled or performing_jumpscare:
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= 1.5 and not player_in_range:
		player_in_range = true
		$near_audio.play()
		start_chasing_player()
		print("🚨 Player within 1.5m! Emergency chase!")
	elif dist > 1.5 and player_in_range:
		player_in_range = false

func start_chasing_player():
	if not chasing and not ghost_disabled and not performing_jumpscare:
		print("🎯 Starting proximity-based chase!")
		chasing = true
		lured = false
		destination = player
		if lured:
			previous_lure_position = lure_target_position
			has_previous_lure = true
			print("💾 Saved lure position: ", previous_lure_position)

# 🍯 Check if a new lure was deployed
func check_for_new_lure() -> void:
	var current_pos = lana_task.current_lana_pos
	if current_pos != Vector3.ZERO and current_pos != last_known_lure_pos:
		print("🔔 Ghost detected NEW lure at: ", current_pos)
		print("🚫 CANCELING PATROL - Going to lure immediately!")
		last_known_lure_pos = current_pos
		lured = true
		lure_target_position = current_pos
		destination = null
		agent.target_position = lure_target_position
		print("🏃 Ghost heading straight to lure!")

# 🔄 Resume lure behavior after player chase ends
func resume_lure_behavior() -> void:
	print("🔄 Resume lure behavior called")
	has_spotted_player = false 
	if has_previous_lure:
		var lure_still_exists = is_lure_still_there(previous_lure_position)
		if lure_still_exists:
			print("🔙 Ghost resuming pursuit of saved lure at: ", previous_lure_position)
			lured = true
			lure_target_position = previous_lure_position
			destination = null
			agent.target_position = lure_target_position
			has_previous_lure = false
			return
		else:
			print("❌ Saved lure no longer exists")
			has_previous_lure = false
	
	if lana_task.current_lana_pos != Vector3.ZERO:
		print("🔄 Found another active lure at: ", lana_task.current_lana_pos)
		lured = true
		lure_target_position = lana_task.current_lana_pos
		last_known_lure_pos = lana_task.current_lana_pos
		destination = null
		agent.target_position = lure_target_position
		return
	
	print("📍 No lures available, resuming patrol")
	pick_destination()

# 🔍 Check if lure still exists
func is_lure_still_there(pos: Vector3) -> bool:
	var tolerance = 1.0
	for id in lana_task.lana_map.keys():
		var data = lana_task.lana_map[id]
		if data["drop"] and data["drop"].visible:
			var distance = data["drop"].global_position.distance_to(pos)
			if distance < tolerance:
				return true
	return false

# 😋 Consume lure when reached
func consume_lure() -> void:
	if lana_task:
		print("🍽️ Consuming lure at: ", lure_target_position)
		lana_task.consume_lure_at_position(lure_target_position)
		lured = false
		has_previous_lure = false
		
		if lana_task.current_lana_pos.distance_to(lure_target_position) < 2.0:
			lana_task.current_lana_pos = Vector3.ZERO
			last_known_lure_pos = Vector3.ZERO
		
		if lana_task.current_lana_pos != Vector3.ZERO:
			print("🔄 Another lure detected at: ", lana_task.current_lana_pos)
			print("🏃 Going there next!")
			lured = true
			lure_target_position = lana_task.current_lana_pos
			last_known_lure_pos = lana_task.current_lana_pos
			agent.target_position = lure_target_position
		else:
			print("📍 No more lures, resuming patrol")
			pick_destination()

# 🎲 Pick random patrol destination
func pick_destination(dont_choose = null):
	if !chasing and !lured:
		var num = rng.randi_range(0, patrol_destinations.size() - 1)
		destination_value = num
		destination = patrol_destinations[num]
		if destination != null and dont_choose != null and destination == patrol_destinations[dont_choose]:
			if dont_choose <= 0:
				destination = patrol_destinations[dont_choose + 1]
			elif dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
				destination = patrol_destinations[dont_choose - 1]
		#print("🚶 Picked patrol destination: ", destination.name if destination else "null")

# 🎯 Update navigation target
func update_target_location():
	if destination:
		agent.target_position = destination.global_transform.origin

# 💀 Jumpscare and kill player
func haunt_player():
	if not chasing or ghost_disabled or performing_jumpscare or killed:
		return
		
	# Enable chase raycast
	if !$chasecast/chasecast.enabled:
		$chasecast/chasecast.enabled = true
	
	# Look at player
	$chasecast.look_at(player.global_transform.origin)
	
	if $chasecast/chasecast.is_colliding():
		var hit = $chasecast/chasecast.get_collider()
		if hit.name == "Player":
			# Trigger jumpscare immediately
			trigger_jumpscare()

func trigger_jumpscare():
	if ghost_disabled or performing_jumpscare or killed:
		return
		
	killed = true
	performing_jumpscare = true
	
	print("💀 JUMPSCARE! Player caught!")
	
	# IMMEDIATELY stop all ghost movement
	chasing = false
	lured = false
	destination = null
	velocity = Vector3.ZERO
	
	# Disable ghost raycasts
	$chasecast/chasecast.enabled = false
	
	# Switch to jumpscare camera immediately
	player.visible = false
	$jumpscare_cam.current = true
	
	# Play jumpscare animation and audio
	$jumpscare_audio.play()
	$ghost_final_animation/AnimationPlayer.play("jumpscare")
	
	# Wait for jumpscare animation
	await get_tree().create_timer(4.0).timeout
	
	# CRITICAL: Disable ghost completely during player respawn sequence
	ghost_disabled = true
	print("🚫 Ghost disabled for respawn sequence")
	
	# Handle player death
	if player.has_method("take_sanity_damage"):
		player.take_sanity_damage()
		
		# Wait for respawn fade + message (0.5s fade + 3s message + 0.5s fade = 4s total)
		await get_tree().create_timer(6.5).timeout
		
		# Check if player still exists (they might have game over'd)
		if is_instance_valid(player) and player.can_be_killed:
			# Player respawned successfully
			reset_ghost_after_catch()
		else:
			# Player died permanently (game over)
			print("💀 Player game over - ghost staying disabled")
	else:
		print("⚠️ Player doesn't have take_sanity_damage method!")
		player.process_mode = Node.PROCESS_MODE_DISABLED
		await get_tree().create_timer(2.0).timeout
		get_tree().quit()

# Reset ghost after catching player
func reset_ghost_after_catch():
	print("🔄 Resetting ghost...")
	
	# Reset all ghost state
	performing_jumpscare = false
	killed = false
	chasing = false
	lured = false
	has_previous_lure = false
	last_known_lure_pos = Vector3.ZERO
	velocity = Vector3.ZERO
	player_in_range = false
	chase_timer = 0.0
	has_spotted_player = false 
	
	# Switch camera back to player
	$jumpscare_cam.current = false
	if player and player.has_node("Head/Camera3D"):
		var player_cam = player.get_node("Head/Camera3D")
		player_cam.current = true
		print("📷 Camera switched back to player")
	
	# Re-enable ghost
	ghost_disabled = false
	print("✅ Ghost re-enabled")
	
	# Resume patrol
	pick_destination()
	print("✅ Ghost reset complete")

# NEW: Public function to permanently disable ghost (called when game over)
func disable_permanently():
	print("💀 Ghost permanently disabled (game over)")
	ghost_disabled = true
	performing_jumpscare = false
	killed = false
	chasing = false
	lured = false
	velocity = Vector3.ZERO
	set_physics_process(false)
	set_process(false)
	
func footsteps():
	if can_play_ambient and !$jumpscare_audio.playing:
		$walking_audio.stream = walking_audio[rng.randi_range(0, walking_audio.size() - 1)]
		$walking_audio.play()
		can_play_ambient = false

		var wait_time = randf_range(2.0, 5.0)
		await get_tree().create_timer(wait_time).timeout
		can_play_ambient = true
