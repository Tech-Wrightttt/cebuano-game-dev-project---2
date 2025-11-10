extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	# Start the ending animation
	$AnimationPlayer.play("telephone")
	
	# Wait for the entire animation to complete (60 seconds)
	await get_tree().create_timer(60.0).timeout
	
