extends Node3D

var opened = false
@export var locked = false
var current_animation = ""  # Track which animation is currently active
var player_is_locked_out = false # CHANGED: Renamed this variable for clarity

@onready var door_open: AudioStreamPlayer3D = $Door_Open
@onready var door_close: AudioStreamPlayer3D = $Door_Close
@onready var door_animation: AnimationPlayer = $Door_Animation

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
	if door_animation.is_playing():
		return
		
	# --- NEW CHECK ---
	# If player is locked out, they can never interact again.
	if player_is_locked_out:
		print("Door is permanently locked.") # Optional: for debugging
		return
	# --- END NEW CHECK ---
	
	# Determine which side the player is on
	var anim_to_play = get_animation_name()
	var player_side = "outside" # Default to "outside"
	if anim_to_play == "open_2":
		player_side = "inside" # Player is in front, so they are "inside"

	if opened:
		# --- CLOSING THE DOOR ---
		# Player can always close an open door, from inside or out.
		if current_animation != "":
			opened = false
			door_animation.play_backwards(current_animation)
			door_close.play()
	else:
		# --- OPENING THE DOOR ---
		# Check if player is "outside"
		if player_side == "outside":
			# Player is outside and trying to open the closed door.
			# This locks them out permanently.
			player_is_locked_out = true
			print("Cannot open from the outside. Door is now locked.")
			return
		else:
			# Player is "inside", open normally.
			current_animation = anim_to_play # will be "open_2"
			opened = true
			door_animation.play(current_animation)
			door_open.play()
