# floor_wake_up.gd
extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var my_camera: Camera3D = $Camera3D  # Adjust path to your camera

func _ready() -> void:
	# Don't auto-start anything, just get references
	print("floor_wake_up ready - AnimationPlayer: ", anim_player != null)
	print("floor_wake_up ready - Camera3D: ", my_camera != null)

func start_wake_sequence() -> void:
	print("Starting wake sequence in floor_wake_up...")
	
	# Make sure we're visible and ready
	show()
	
	# SWITCH TO OUR CAMERA
	if my_camera:
		my_camera.current = true
		print("Switched to floor_wake_up camera")
	else:
		print("WARNING: No camera found in floor_wake_up")
	
	# Wait one frame to ensure everything is initialized
	await get_tree().process_frame
	
	if anim_player and anim_player.has_animation("wake"):
		print("Playing wake animation...")
		anim_player.play("wake")
		print("Wake animation started successfully")
		
		# Wait for animation to finish
		await anim_player.animation_finished
		print("Wake animation completed")
	else:
		print("ERROR: Cannot play wake animation")
