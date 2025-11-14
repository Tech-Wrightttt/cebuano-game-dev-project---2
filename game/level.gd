extends Node3D

func _ready():
	# Wait one frame so we are 100% sure the level and all its children exist
	await get_tree().process_frame
	
	# Now, we tell Global "Here is the level node, find the tasks inside me."
	Global.start_night_logic(self)
