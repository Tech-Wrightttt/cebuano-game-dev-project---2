extends Node3D

signal task_completed
# --- PARENT NODES ---
@onready var mirrors_parent = $Mirrors
@onready var towels_parent = $TowelsAroundTheHouse
@onready var towel_covering: AudioStreamPlayer3D = $Towel_Covering

# --- MAPS TO HOLD NODE REFERENCES ---
# We use Dictionaries (maps) to link an ID to all of its parts
var mirror_map := {}
var towel_map := {}

# --- TASK STATE ---
var chosen_mirror_ids := []
var chosen_towel_ids := []
var towels_player_is_holding := 0 # We just need a count

func _ready() -> void:
	populate_maps()
	deactivate_all()
	
func initialize_task() -> void:
	# 1. Check if we have enough items to start the task
	if mirror_map.size() < 3 or towel_map.size() < 3:
		push_warning("Not enough mirrors or towels to start the task.")
		return
		
	# 2. Randomize and pick the items for this task
	randomize()
	
	var all_mirror_ids = mirror_map.keys()
	all_mirror_ids.shuffle()
	chosen_mirror_ids = all_mirror_ids.slice(0, 3)
	
	var all_towel_ids = towel_map.keys()
	if "towel11" in all_towel_ids:
		all_towel_ids.erase("towel11")
	if "towel12" in all_towel_ids:
		all_towel_ids.erase("towel12")
	all_towel_ids.shuffle()
	chosen_towel_ids = all_towel_ids.slice(0, 3)
	
	# --- NIGHT 5 LOGIC (FOR TOWELS) ---
	if Global.get_night() == 5:
		var mandatory_towels_added = 0
		if chosen_towel_ids.size() > 0:
			chosen_towel_ids.resize(3 - 2) # If 3-2 = 1, we resize the array to 1 item
		if "towel11" in towel_map:
			chosen_towel_ids.push_back("towel11")
			mandatory_towels_added += 1
		if "towel12" in towel_map:
			chosen_towel_ids.push_back("towel12")
			mandatory_towels_added += 1
		print("Night 5: Mandatory towels 'towel11' and 'towel12' added to task (Total added: %d)." % mandatory_towels_added)
	# 3. Activate the chosen items
	update_all_item_states()

func deactivate_all() -> void:
	# Set up towels (all hidden)
	for id in towel_map.keys():
		var data = towel_map[id]
		data["node"].visible = false
		if data["collision"]:
			data["collision"].set_deferred("disabled", true)

	# Set up mirrors (all covered)
	for id in mirror_map.keys():
		var data = mirror_map[id]
		if data["cover"]:
			data["cover"].visible = true
		if data["collision"]:
			data["collision"].set_deferred("disabled", true)
			
	# Reset task state
	chosen_mirror_ids.clear()
	chosen_towel_ids.clear()
	towels_player_is_holding = 0
	
func populate_maps() -> void:
	# Map all mirrors
	for mirror_node in mirrors_parent.get_children():
		var id = mirror_node.name
		# This assumes a structure of:
		# ▼ broken mirror (mirror_node)
		#   ► covertowel
		#   ▼ StaticBody3D (This is the collider_body)
		#     ► CollisionShape3D
		var collision_body = mirror_node.get_node_or_null("StaticBody3D")
		if not collision_body:
			# Fallback for the weird structure in the screenshot:
			# ▼ broken mirror (mirror_node)
			#   ► covertowel
			#   ► StaticBodyShape3D (This is the collider_body, a StaticBody3D)
			collision_body = mirror_node.get_node_or_null("StaticBodyShape3D")

		mirror_map[id] = {
			"node": mirror_node,
			"cover": mirror_node.get_node_or_null("covertowel"),
			"body": collision_body,
			"collision": collision_body.get_node_or_null("CollisionShape3D") if collision_body else null
		}
		
	# Map all towels
	for towel_node in towels_parent.get_children():
		var id = towel_node.name
		# This assumes a structure of:
		# ▼ towel (towel_node)
		#   ▼ StaticBody3D (collider_body)
		#     ► CollisionShape3D
		var collision_body = towel_node.get_node_or_null("StaticBody3D")
		towel_map[id] = {
			"node": towel_node,
			"body": collision_body,
			"collision": collision_body.get_node_or_null("CollisionShape3D") if collision_body else null
		}

# Sets the initial state for all towels and mirrors
func update_all_item_states() -> void:
	# Set up towels
	for id in towel_map.keys():
		var data = towel_map[id]
		var is_chosen = (id in chosen_towel_ids)
		
		data["node"].visible = is_chosen
		if data["collision"]:
			data["collision"].set_deferred("disabled", not is_chosen)

	# Set up mirrors
	for id in mirror_map.keys():
		var data = mirror_map[id]
		var is_chosen = (id in chosen_mirror_ids)
		
		# The "cover" is visible if the mirror is NOT chosen
		if data["cover"]:
			data["cover"].visible = not is_chosen
			
		# The mirror's collision is enabled ONLY if it IS chosen
		if data["collision"]:
			data["collision"].set_deferred("disabled", not is_chosen)


# --- PLAYER INTERACTION FUNCTIONS ---

# Call this when the player interacts with a TOWEL
func take(collider_body: PhysicsBody3D) -> void:
	# Find which towel this collider belongs to
	for id in chosen_towel_ids: # Only need to check the chosen ones
		var data = towel_map[id]
		
		# Check if the collider_body is the one from our map
		if data["body"] == collider_body:
			# Found it. Hide the towel and disable its collision.
			data["node"].visible = false
			data["collision"].set_deferred("disabled", true)
			
			# Remove from task list and add to player "inventory"
			chosen_towel_ids.erase(id)
			towels_player_is_holding += 1
			
			# (Optional) Play a pickup sound
			return # We found our item, no need to keep looping

# Call this when the player interacts with a MIRROR
func use(collider_body: PhysicsBody3D) -> void:
	# 1. Check if the player is holding a towel
	if towels_player_is_holding == 0:
		print("Player has no towels to use.")
		# (Optional) Play a "failure" sound
		return
		
	# 2. Find which mirror this collider belongs to
	for id in chosen_mirror_ids: # Only need to check the chosen ones
		var data = mirror_map[id]
		
		# Check if the collider_body is the one from our map
		if data["body"] == collider_body:
			# Found it. Show the "covertowel" and disable collision.
			if data["cover"]:
				data["cover"].visible = true
				
			data["collision"].set_deferred("disabled", true)
			
			# "Use up" one towel and remove the mirror from the task
			towels_player_is_holding -= 1
			chosen_mirror_ids.erase(id)
			towel_covering.play()
			if chosen_mirror_ids.is_empty():
				print("All 3 mirrors have been covered!")
				# --- RE-ADDED SIGNAL EMIT ---
				task_completed.emit()
			return

func get_progress_string() -> String:
	
	var total_items = 3
	var covered_mirrors = total_items - chosen_mirror_ids.size()
	var collected_towels = total_items - chosen_towel_ids.size()
	
	# --- State 1: Collecting Towels ---
	# Show this text if the chosen_towel_ids list is NOT empty.
	# (i.e., the towels are still scattered around the house)
	if not chosen_towel_ids.is_empty():
		return "%d/%d towels collected" % [collected_towels, total_items]

	# --- State 2: Covering Mirrors ---
	# Show this text if the chosen_towel_ids list IS empty 
	# (all towels are collected/in inventory) AND mirrors are NOT fully covered.
	if not chosen_mirror_ids.is_empty():
		return "%d/%d mirrors covered" % [covered_mirrors, total_items]

	# --- State 3: Task Complete ---
	# If chosen_mirror_ids is also empty, the task is done.
	return ""
