extends CharacterBody3D
@onready var agent = $NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
@onready var lana_task = get_tree().get_first_node_in_group("lana_task")  # NEW: Get lana task manager
var speed = 2.0
@onready var rng = RandomNumberGenerator.new()
@onready var animation_player = $ghost_model_animation.get_node("AnimationPlayer")
var destination
var chasing = false
var destination_value
var chase_timer = 0.0
var lured = false  # NEW: Track if ghost is currently lured
var lure_detection_radius = 15.0  # NEW: How far ghost can detect lures
var lure_consumption_distance = 1.5  # NEW: How close to consume lure

func _ready() -> void:
	animation_player.play("ghost_idle")
	await get_tree().create_timer(2.0).timeout
	print("Ghost ready! Collision layer: ", collision_layer)
	print("Ghost collision mask: ", collision_mask)
	
	# NEW: Make sure lana_task has the correct group
	if lana_task:
		lana_task.add_to_group("lana_task")
	
	pick_destination()

func _process(delta: float) -> void:
	# NEW: Check for nearby lures (only if not chasing player)
	if not chasing and lana_task:
		check_for_lures()
	
	if chasing:
		if speed != 4.0:
			speed = 4.0
		if chase_timer < 15:
			chase_timer += 1 * delta
		else:
			chase_timer = 0.0
			chasing = false
			lured = false  # Reset lured state when chase ends
	elif !chasing:
		if speed != 2.0:
			speed = 2.0
		if animation_player.current_animation != "ghost_idle":
			animation_player.play("ghost_idle")
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if destination != null:
		var look_dir = lerp_angle(deg_to_rad(global_rotation_degrees.y), atan2(-velocity.x, -velocity.z), 0.5)
		global_rotation_degrees.y = rad_to_deg(look_dir)
		update_target_location()

func _physics_process(_delta: float) -> void:
	# Player chase has priority over lures
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)
	
	# NEW: Check if reached lure
	if lured and destination and destination.is_in_group("lana_lure"):
		var dist_to_lure = global_position.distance_to(destination.global_position)
		if dist_to_lure < lure_consumption_distance:
			consume_lure()

	if destination != null:
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
			chasing = true
			lured = false  # Cancel lure when spotting player
			destination = player

# NEW: Check for nearby lures
func check_for_lures() -> void:
	if not lana_task or chasing:
		return
	
	var nearest_lure = lana_task.get_nearest_lure(global_position)
	
	if nearest_lure:
		var distance = global_position.distance_to(nearest_lure.global_position)
		
		# If lure is within detection radius and we're not already going to it
		if distance < lure_detection_radius and destination != nearest_lure:
			print("👃 Ghost detected lure at distance: %.2f" % distance)
			lured = true
			destination = nearest_lure
			update_target_location()

# NEW: Consume the lure when reached
func consume_lure() -> void:
	if lana_task and destination:
		lana_task.consume_lure(destination)
		lured = false
		# After consuming, pick a new patrol destination
		pick_destination()

func pick_destination(dont_choose = null):
	if !chasing and !lured:  # NEW: Don't pick random destination if lured
		var num = rng.randi_range(0, patrol_destinations.size() - 1)
		destination_value = num
		destination = patrol_destinations[num]

		if destination != null and dont_choose != null and destination == patrol_destinations[dont_choose]:
			if dont_choose <= 0:
				destination = patrol_destinations[dont_choose + 1]
			elif dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
				destination = patrol_destinations[dont_choose - 1]

		print("=== PICKED DESTINATION ===")
		print("Destination name: ", destination.name if destination else "null")
				
func update_target_location():
	$NavigationAgent3D.target_position = destination.global_transform.origin

func compute_velocity(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, speed)
	move_and_slide()
