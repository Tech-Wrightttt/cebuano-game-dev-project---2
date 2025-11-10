extends Node3D
@onready var cleaning: AudioStreamPlayer3D = $Cleaning_Statue
var chosen_statue_keys: Array = []
@onready var statue_map := {
	1: {
		"cleaned_node": $cleanedStatue/StatueAnte,
		"cleaned_collision": $cleanedStatue/StatueAnte/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueAnte,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueAnte/StaticBody3D/CollisionShape3D
	},
	2: {
		"cleaned_node": $cleanedStatue/StatueMary,
		"cleaned_collision": $cleanedStatue/StatueMary/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueMary,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueMary/StaticBody3D/CollisionShape3D
	},
	3: {
		"cleaned_node": $cleanedStatue/StatueMary2,
		"cleaned_collision": $cleanedStatue/StatueMary2/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueMary2,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueMary2/StaticBody3D/CollisionShape3D
	},
	4: {
		"cleaned_node": $cleanedStatue/StatueMary3,
		"cleaned_collision": $cleanedStatue/StatueMary3/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueMary3,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueMary3/StaticBody3D/CollisionShape3D
	},
	5: {
		"cleaned_node": $cleanedStatue/StatueSaint,
		"cleaned_collision": $cleanedStatue/StatueSaint/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueSaint,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueSaint/StaticBody3D/CollisionShape3D
	},
	6: {
		"cleaned_node": $cleanedStatue/StatueSaint2,
		"cleaned_collision": $cleanedStatue/StatueSaint2/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueSaint2,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueSaint2/StaticBody3D/CollisionShape3D
	},
	7: {
		"cleaned_node": $cleanedStatue/StatueSaint3,
		"cleaned_collision": $cleanedStatue/StatueSaint3/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueSaint3,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueSaint3/StaticBody3D/CollisionShape3D
	}
}


func _ready():
	randomize()
	var all_task_keys = statue_map.keys()
	all_task_keys.shuffle()
	chosen_statue_keys = all_task_keys.slice(0, 3)
	update_statue_tasking()


func update_statue_tasking():
	# Debug: Print which keys were randomly chosen
	print("Chosen statue keys: ", chosen_statue_keys)
	
	for key in statue_map.keys():
		var data = statue_map[key]
		
		# --- Debugger Check ---
		if is_instance_valid(data["uncleaned_node"]):
			# This node is valid, print its name and key
			print("Key [", key, "]: ", data["uncleaned_node"].name, " is valid.")
		else:
			# This node is NOT valid (e.g., null or freed), print an error
			print("ERROR: Key [", key, "]: uncleaned_node is NOT valid!")
			continue # Skip this loop iteration to avoid a crash
		# --- End Debugger Check ---

		var is_active_task = (key in chosen_statue_keys)
		
		# Debug: Print what the function is deciding to do
		if is_active_task:
			print("  -> Key [", key, "] is an active task. Setting uncleaned to VISIBLE.")
		else:
			print("  -> Key [", key, "] is not active. Setting uncleaned to HIDDEN.")
		
		data["cleaned_node"].visible = not is_active_task
		data["uncleaned_node"].visible = is_active_task
		
		data["cleaned_collision"].set_deferred("disabled", true)
		data["uncleaned_collision"].set_deferred("disabled", not is_active_task)

func start_deploy_sound() -> void:
	if not cleaning.is_playing():
		cleaning.play()

func stop_deploy_sound() -> void:
	cleaning.stop()

func deploy(collider_body: PhysicsBody3D) -> void:
	for key in statue_map.keys():
		var data = statue_map[key]
		var uncleaned_body_in_map = data["uncleaned_collision"].get_parent()
		if uncleaned_body_in_map and uncleaned_body_in_map == collider_body:
			data["uncleaned_node"].visible = false
			data["uncleaned_collision"].set_deferred("disabled", true)
			data["cleaned_node"].visible = true
			data["cleaned_collision"].set_deferred("disabled", false) 
			return
