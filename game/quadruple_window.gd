extends Node3D

var opened = true
var is_interacting = false

# Check for both possible AnimationPlayer node names
@onready var window_animation: AnimationPlayer = $WindowAnimation if has_node("WindowAnimation") else $WindowAnimation

func _ready() -> void:
	# Check if animation player exists
	if not window_animation:
		push_error("No AnimationPlayer found for window: " + name)
		return
	
	# Force the window to start in closed position (beginning of "closed" animation)
	if window_animation.has_animation("close"):
		window_animation.play("close")
		#window_animation.seek(0.0, true)
		#window_animation.pause()

func interact():
	if not window_animation:
		return
		
	# Prevent interaction if already animating
	if is_interacting or window_animation.is_playing():
		return
	
	is_interacting = true
	opened = !opened
	
	if opened:
		window_animation.play_backwards("close")
	else:
		window_animation.play("close")
	
	# Wait for animation to finish, then allow interaction again
	await window_animation.animation_finished
	is_interacting = false
