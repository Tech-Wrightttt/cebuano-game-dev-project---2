extends Node3D

@onready var lights = $House/doors/NavigationRegion3D/Lights

func _ready():
	# Wait one frame so we are 100% sure the level and all its children exist
	lights.visible = false
	await get_tree().process_frame
	
	
	# Now, we tell Global "Here is the level node, find the tasks inside me."
	Global.start_night_logic(self)
	
