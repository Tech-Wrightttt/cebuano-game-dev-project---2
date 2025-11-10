extends CharacterBody3D

@onready var agent = $NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
@onready var lana_task = get_tree().get_first_node_in_group("lana_task")
@onready var animation_player = $ghost_final_animation/AnimationPlayer
@onready var rng = RandomNumberGenerator.new()

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
			chase_timer = 0.0
			chasing = false
			resume_lure_behavior()
	elif !chasing:
		if speed != 2.0:
			speed = 2.0
		if animation_player.current_animation != "ghost_idle":
			animation_player.play("ghost_idle")
	
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
	haunt_player()

	# Check if reached lure
	if lured:
		var dist_to_lure = global_position.distance_to(lure_target_position)
		if dist_to_lure < lure_consumption_distance:
			consume_lure()

	# Move ghost
	if destination != null or lured:
		var current_location = global_transform.origin
		var next_location = agent.get_next_path_position()
		var new_velocity = (next_location - current_location).normalized() * speed
		animation_player.play("ghost_walk")
		agent.set_velocity(new_velocity)
		velocity = velocity.move_toward(new_velocity, speed)

		if not is_on_floor() and velocity.y <= 0:
			var next_pos = agent.get_next_path_position()
			var y_diff = next_pos.y - global_transform.origin.y
			if y_diff > 0.1 and y_diff < 1.5:
				velocity.y = 1.0

		move_and_slide()

# 👁️ NEW: Player proximity detection (1.5m range)
func check_player_distance():
	if not player:
		return
	
	var dist = global_position.distance_to(player.global_position)
	
	if dist <= 1.5 and not player_in_range:
		player_in_range = true
		start_chasing_player()
	elif dist > 1.5 and player_in_range:
		player_in_range = false  # reset once player leaves range

func start_chasing_player():
	if not chasing:
		print("🎯 Player within 1.5m — starting chase!")
		chasing = true
		lured = false
		destination = player
		if lured:
			previous_lure_position = lure_target_position
			has_previous_lure = true

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

func resume_lure_behavior() -> void:
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
		print("🔄 Found another active lure, heading there!")
		lured = true
		lure_target_position = lana_task.current_lana_pos
		last_known_lure_pos = lana_task.current_lana_pos
		destination = null
		agent.target_position = lure_target_position
		return
	
	print("📍 No lures available, resuming patrol")
	pick_destination()

func is_lure_still_there(pos: Vector3) -> bool:
	var tolerance = 1.0
	for id in lana_task.lana_map.keys():
		var data = lana_task.lana_map[id]
		if data["drop"] and data["drop"].visible:
			var distance = data["drop"].global_position.distance_to(pos)
			if distance < tolerance:
				return true
	return false

func consume_lure() -> void:
	if lana_task:
		print("😋 Ghost reached and consumed lure at: ", lure_target_position)
		lana_task.consume_lure_at_position(lure_target_position)
		lured = false
		has_previous_lure = false
		if lana_task.current_lana_pos.distance_to(lure_target_position) < 2.0:
			lana_task.current_lana_pos = Vector3.ZERO
			last_known_lure_pos = Vector3.ZERO
		if lana_task.current_lana_pos != Vector3.ZERO:
			print("🔄 Another lure detected, going there next!")
			lured = true
			lure_target_position = lana_task.current_lana_pos
			last_known_lure_pos = lana_task.current_lana_pos
			agent.target_position = lure_target_position
		else:
			print("📍 No more lures, resuming patrol")
			pick_destination()

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
				
func update_target_location():
	if destination:
		agent.target_position = destination.global_transform.origin

func haunt_player():
	if chasing:
		if !$chasecast/chasecast.enabled:
			$chasecast/chasecast.enabled = true
		$chasecast.look_at(player.global_transform.origin)
		if $chasecast/chasecast.is_colliding():
			var hit = $chasecast/chasecast.get_collider()
			print(hit.name)
			if hit.name == "Player" and !killed:
				killed = true
				$jumpscare_cam.current = true
				$ghost_final_animation/AnimationPlayer.speed_scale = 2
				$ghost_final_animation/AnimationPlayer.play("jumpscare")
				print("played")
				player.visible = false
				player.process_mode = Node.PROCESS_MODE_DISABLED
				print("💀 JUMPSCARE! Player killed!")
				await get_tree().create_timer(2.0).timeout
				get_tree().quit()

	else:
		if $chasecast/chasecast.enabled:
			$chasecast/chasecast.enabled = false
