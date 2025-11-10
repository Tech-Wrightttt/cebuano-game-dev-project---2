extends Node3D

var opened = false
@export var locked = false
var current_animation = ""  # Track which animation is currently active
var current_night = Global.get_night()
@onready var door_open: AudioStreamPlayer3D = $Door_Open
@onready var door_close: AudioStreamPlayer3D = $Door_Close
@onready var door_animation: AnimationPlayer = $Door_Animation
@onready var interaction_label: Label = $Head/Camera3D/Filters/Interaction_Label

# Function to determine which animation to use based on player position
func get_animation_name() -> String:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return "open_1" 
	
	# Get the door's forward direction (assuming -Z is forward in local space)
	var door_forward = -global_transform.basis.z
	
	# Get direction from door to player
	var to_player = (player.global_position - global_position).normalized()
	
	# Dot product determines which side player is on
	var dot = door_forward.dot(to_player)
	
	# REVERSED: If dot is positive, player is in front (use open_2), else behind (use open_1)
	if dot > 0:
		return "open_2"
	else:
		return "open_1"

func ai_open_door(body):
	if body.name == "ghost" and !locked and !opened:
		if !door_animation.is_playing():
			current_animation = get_animation_name()
			opened = true
			door_animation.play(current_animation)
		
func ai_close_door(body):
	if body.name == "ghost" and !locked and opened:
		if !door_animation.is_playing() and current_animation != "":
			opened = false
			door_animation.play_backwards(current_animation)

func interact():
	# Prevent interaction while animation is playing
	if current_night < 3:
		locked = true
		return
		
	if door_animation.is_playing():
		return
	
	if opened:
		# Closing: use the same animation that was used to open
		if current_animation != "":
			opened = false
			door_animation.play_backwards(current_animation)
			door_close.play()
	else:
		# Opening: determine which animation based on player position
		current_animation = get_animation_name()
		opened = true
		door_animation.play(current_animation)
		door_open.play()
