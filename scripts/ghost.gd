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

func _ready() -> void:
	animation_player.play("ghost_idle")
	await get_tree().create_timer(2.0).timeout
	print("Ghost ready! Collision layer: ", collision_layer)
	print("Ghost collision mask: ", collision_mask)
	pick_destination()

func _process(delta: float) -> void:
	if chasing:
		if speed != 4.0:
			speed = 4.0
		if chase_timer < 15:
			chase_timer += 1 * delta
		else:
			chase_timer = 0.0
			chasing = false
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
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)
	
	if destination != null:
		var current_location = global_transform.origin
		var next_location = $NavigationAgent3D.get_next_path_position()
		#var distance_to_next = current_location.distance_to(next_location)
		#var distance_to_dest = current_location.distance_to(destination.global_transform.origin)
		#
		## Debug info every 60 frames (once per second at 60fps)
		#if Engine.get_physics_frames() % 60 == 0:
			#print("Ghost position: ", current_location)
			#print("Destination: ", destination.name, " at ", destination.global_transform.origin)
			#print("Distance to destination: ", distance_to_dest)
			#print("Distance to next nav point: ", distance_to_next)
			#print("is_navigation_finished: ", agent.is_navigation_finished())
		
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
			chasing = true
			destination = player

func pick_destination(dont_choose = null):
	if !chasing:
		var num = rng.randi_range(0, patrol_destinations.size() - 1)
		destination_value = num
		destination = patrol_destinations[num]
		if destination != null and dont_choose != null and destination == patrol_destinations[dont_choose]:
			if dont_choose <= 0:
				destination = patrol_destinations[dont_choose +1]
			if dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
				destination = patrol_destinations[dont_choose - 1]
		
		#print("=== PICKED DESTINATION ===")
		#print("Destination name: ", destination.name if destination else "null")
		#print("Destination position: ", destination.global_transform.origin if destination else "null")
		#print("Ghost current position: ", global_transform.origin)
				#
func update_target_location():
	$NavigationAgent3D.target_position = destination.global_transform.origin

func compute_velocity(safe_velocity: Vector3) -> void:
	velocity = velocity.move_toward(safe_velocity, speed)
	move_and_slide()
