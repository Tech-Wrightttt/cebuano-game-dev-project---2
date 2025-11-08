extends CharacterBody3D
@onready var agent = $NavigationAgent3D
@export var patrol_destinations: Array[Node3D]
@onready var player = get_tree().get_first_node_in_group("player")
var speed = 3.0
@onready var rng = RandomNumberGenerator.new()
var destination
var chasing = false
var destination_value
var chase_timer = 0.0

func _ready() -> void:
	agent.velocity_computed.connect(_on_velocity_computed)
	pick_destination()

func _process(delta: float) -> void:
	if chasing:
		if speed != 5.0:
			speed = 5.0
		if chase_timer < 15:
			chase_timer += 1 * delta
		else:
			chase_timer = 0.0
			chasing = false
			pick_destination()
	elif !chasing:
		if speed != 3.0:
			speed = 3.0
	
	if destination != null:
		update_target_location()

func _physics_process(_delta: float) -> void:
	chase_player($RayCast3D)
	chase_player($RayCast3D2)
	chase_player($RayCast3D3)
	chase_player($RayCast3D4)
	chase_player($RayCast3D5)
	
	if destination != null:
		var current_location = global_position
		var distance_to_dest = current_location.distance_to(destination.global_position)
		
		# Continue moving until within 1.5m of destination
		if distance_to_dest > 1.5:
			var next_location = agent.get_next_path_position()
			
			# Calculate direction including vertical component
			var direction = (next_location - current_location).normalized()
			
			# Speed boost for stairs
			var speed_multiplier = 1.3 if direction.y > 0.02 else 1.0
			var new_velocity = direction * speed * speed_multiplier
			
			# Use the NavigationAgent's velocity computation
			agent.set_velocity(new_velocity)
		else:
			# Stop when close enough
			if !chasing:
				pick_destination(destination_value)

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
