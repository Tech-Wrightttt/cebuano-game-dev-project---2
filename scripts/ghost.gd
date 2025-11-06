extends CharacterBody3D
@onready var agent = $NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
var speed = 2.0
@onready var rng = RandomNumberGenerator.new()
@onready var animation_player = $ghost_model_animation/AnimationPlayer
var destination
var chasing = false
var destination_value
var chase_timer = 0.0
var is_moving = false

func _ready() -> void:
	agent.velocity_computed.connect(_on_velocity_computed)
	print("is there animation player? ", animation_player)
	animation_player.play("ghost_idle")
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
			pick_destination()
	elif !chasing:
		if speed != 2.0:
			speed = 2.0
	
	if destination != null:
		update_target_location()
	
	# Handle animations based on movement
	if is_moving:
		if animation_player.current_animation != "ghost_walk":
			animation_player.play("ghost_walk")
	else:
		if animation_player.current_animation != "ghost_idle":
			animation_player.play("ghost_idle")

func _physics_process(_delta: float) -> void:
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)
	
	if destination != null and not agent.is_navigation_finished():
		var current_location = global_position
		var next_location = agent.get_next_path_position()
		
		# Calculate direction including vertical component
		var direction = (next_location - current_location).normalized()
		
		# Boost speed when climbing stairs
		var speed_multiplier = 1.3 if direction.y > 0.05 else 1.0
		
		var new_velocity = direction * speed * speed_multiplier
		
		# Use the NavigationAgent's velocity computation
		agent.set_velocity(new_velocity)
		
		is_moving = true
	else:
		is_moving = false

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	# Use the computed velocity from NavigationAgent
	velocity = safe_velocity
	move_and_slide()
	
	# Rotate to face movement direction (horizontal only)
	var horizontal_vel = Vector3(velocity.x, 0, velocity.z)
	if horizontal_vel.length() > 0.1:
		var target_angle = atan2(-velocity.x, -velocity.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 0.15)

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
				destination = patrol_destinations[dont_choose + 1]
			elif dont_choose > 0 and dont_choose <= patrol_destinations.size() - 1:
				destination = patrol_destinations[dont_choose - 1]
				
func update_target_location():
	agent.target_position = destination.global_position
