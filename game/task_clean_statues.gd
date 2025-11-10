extends Node3D

signal task_completed

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
	},
	8: {
		"cleaned_node": $cleanedStatue/StatueAngel,
		"cleaned_collision": $cleanedStatue/StatueAngel/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueAngel,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueAngel/StaticBody3D/CollisionShape3D
	},
	9: {
		"cleaned_node": $cleanedStatue/StatueAngel2,
		"cleaned_collision": $cleanedStatue/StatueAngel2/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueAngel2,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueAngel2/StaticBody3D/CollisionShape3D
	},
	10: {
		"cleaned_node": $cleanedStatue/StatueCreepy,
		"cleaned_collision": $cleanedStatue/StatueCreepy/StaticBody3D/CollisionShape3D,
		"uncleaned_node": $uncleanedStatue/UncleanedStatueCreepy,
		"uncleaned_collision": $uncleanedStatue/UncleanedStatueCreepy/StaticBody3D/CollisionShape3D
	}
}


func _ready():
	deactivate_all()

func initialize_task():
	randomize()
	var number_of_tasks_to_find = 3
	
	# These are the "special" keys for Night 5
	var mandatory_key_1 = 8
	var mandatory_key_2 = 9
	var mandatory_key_3 = 10
	
	if Global.get_night() == 5:
		# --- NIGHT 5 LOGIC (This part was correct) ---
		# Force the 3 mandatory statues
		print("Night 5: Forcing mandatory statues (Angel, Angel2, Creepy).")
		
		# Get all keys
		var all_task_keys = statue_map.keys()
		
		# Remove the mandatory ones from the list
		all_task_keys.erase(mandatory_key_1)
		all_task_keys.erase(mandatory_key_2)
		all_task_keys.erase(mandatory_key_3)
		all_task_keys.shuffle()
		
		# This will slice(0, 0) which is an empty array, which is correct
		chosen_statue_keys = all_task_keys.slice(0, number_of_tasks_to_find - 3)
		
		# Add the mandatory keys
		chosen_statue_keys.push_back(mandatory_key_1)
		chosen_statue_keys.push_back(mandatory_key_2)
		chosen_statue_keys.push_back(mandatory_key_3)
		
	else:
		# --- NIGHTS 1-4 LOGIC (This is the new part) ---
		# Pick 3 statues, *excluding* 8, 9, and 10.
		print("Night %s: Picking 3 random 'safe' statues." % Global.get_night())
		
		# 1. Get all keys
		var safe_task_keys = statue_map.keys()
		
		# 2. Remove the "special" keys from the pool
		safe_task_keys.erase(mandatory_key_1)
		safe_task_keys.erase(mandatory_key_2)
		safe_task_keys.erase(mandatory_key_3)
		
		# 3. Now, safe_task_keys only contains keys 1-7. Shuffle them.
		safe_task_keys.shuffle()
		
		# 4. Pick 3 from this safe list.
		chosen_statue_keys = safe_task_keys.slice(0, number_of_tasks_to_find)
	
	# Activate the chosen "dirty" statues
	update_statue_tasking()
	
func deactivate_all():
	for key in statue_map.keys():
		var data = statue_map[key]
		
		if not is_instance_valid(data["cleaned_node"]) or \
		   not is_instance_valid(data["uncleaned_node"]):
			print("ERROR: Invalid node in statue_map for key ", key)
			continue

		# Set to default "clean" state
		data["cleaned_node"].visible = true
		data["uncleaned_node"].visible = false
		
		# Disable all collisions
		data["cleaned_collision"].set_deferred("disabled", true)
		data["uncleaned_collision"].set_deferred("disabled", true)

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
			if key in chosen_statue_keys:
				chosen_statue_keys.erase(key)
			# If the list is now empty, the task is done
			if chosen_statue_keys.is_empty():
				print("TASK_STATUE: All statues cleaned. Task complete.")
				task_completed.emit()
			return

# ADD THIS ENTIRE FUNCTION
func get_progress_string() -> String:
	if chosen_statue_keys.is_empty():
		return ""
		
	# This assumes you start with 3. Change '3' if it's different.
	var total_statues = 3
	var cleaned = total_statues - chosen_statue_keys.size()
	return "%d/%d statues cleaned" % [cleaned, total_statues]
