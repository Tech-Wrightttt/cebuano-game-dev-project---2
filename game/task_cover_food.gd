extends Node3D

signal task_completed

# --- PARENT NODES ---
@onready var foods_parent = $Foods
@onready var covers_parent = $CoversAroundTheHouse
@onready var put_cover: AudioStreamPlayer3D = $Put_Cover

# --- MAPS TO HOLD NODE REFERENCES ---
var food_map := {}
var cover_map := {}

# --- TASK STATE ---
var chosen_food_ids := []
var chosen_cover_ids := []
var covers_player_is_holding := 0 # We just need a count

func _ready() -> void:
	populate_maps()
	deactivate_all()

func initialize_task() -> void:
	# 1. Check if we have enough items to start the task
	if food_map.size() < 4 or cover_map.size() < 4:
		push_warning("Not enough foods or covers to start the task.")
		return
		
	# 2. Randomize and pick the items for this task
	randomize()
	
	# --- Setup Food ---
	var all_food_ids = food_map.keys()
	all_food_ids.shuffle()
	chosen_food_ids = all_food_ids.slice(0, 4)
	
	# --- Setup Covers ---
	var all_cover_ids = cover_map.keys()
	all_cover_ids.shuffle()
	chosen_cover_ids = all_cover_ids.slice(0, 4)
	
	# --- NIGHT 5 LOGIC (FOR COVERS) ---
	if Global.get_night() == 5:
		if "cover11" in cover_map and "cover12" in cover_map:
			all_cover_ids.erase("cover11")
			all_cover_ids.erase("cover12")
			chosen_cover_ids = all_cover_ids.slice(0, 4 - 2)
			chosen_cover_ids.push_back("cover11")
			chosen_cover_ids.push_back("cover12")
			print("Night 5: Mandatory covers 'cover11' and 'cover12' added to task.")

	# 3. Set the initial visibility and collisions for everything
	update_all_item_states()

func deactivate_all() -> void:
	# Set up covers (all hidden)
	for id in cover_map.keys():
		var data = cover_map[id]
		data["node"].visible = false
		if data["collision"]:
			data["collision"].set_deferred("disabled", true)

	# Set up food items (all covered)
	for id in food_map.keys():
		var data = food_map[id]
		if data["cover"]:
			data["cover"].visible = true
		if data["collision"]:
			data["collision"].set_deferred("disabled", true)
			
	# Reset task state
	chosen_food_ids.clear()
	chosen_cover_ids.clear()
	covers_player_is_holding = 0
	
# Populates the dictionaries with references to all the nodes
func populate_maps() -> void:
	# Map all food items
	for food_node in foods_parent.get_children():
		var id = food_node.name
		# This assumes a structure of:
		# ▼ food (food_node)
		#   ► dish_cover
		#     ► CollisionShape3D
		var collision_body = food_node.get_node_or_null("StaticBody3D")
		food_map[id] = {
			"node": food_node,
			# --- FIX: Changed "cover" to "dish_cover" to match node structure ---
			"cover": food_node.get_node_or_null("cover"),
			"body": collision_body,
			"collision": collision_body.get_node_or_null("CollisionShape3D") if collision_body else null
		}
		
	# Map all covers
	for cover_node in covers_parent.get_children():
		var id = cover_node.name
		# This assumes a structure of:
		# ▼ cover (cover_node)
		#   ▼ StaticBody3D (collider_body)
		#     ► CollisionShape3D
		var collision_body = cover_node.get_node_or_null("StaticBody3D")
		cover_map[id] = {
			"node": cover_node,
			"body": collision_body,
			"collision": collision_body.get_node_or_null("CollisionShape3D") if collision_body else null
		}

# Sets the initial state for all covers and food items
func update_all_item_states() -> void:
	# Set up covers (the ones the player picks up)
	for id in cover_map.keys():
		var data = cover_map[id]
		var is_chosen = (id in chosen_cover_ids)
		
		data["node"].visible = is_chosen
		if data["collision"]:
			data["collision"].set_deferred("disabled", not is_chosen)

	# Set up food items (the ones the player covers)
	for id in food_map.keys():
		var data = food_map[id]
		var is_chosen = (id in chosen_food_ids)
		
		# The "dish_cover" is visible if the food is NOT chosen
		if data["cover"]:
			data["cover"].visible = not is_chosen
			
		# The food's collision is enabled ONLY if it IS chosen
		if data["collision"]:
			data["collision"].set_deferred("disabled", not is_chosen)


# --- PLAYER INTERACTION FUNCTIONS ---

# Call this when the player interacts with a COVER (to pick up)
func take(collider_body: PhysicsBody3D) -> void:
	# Find which cover this collider belongs to
	for id in chosen_cover_ids: # Only need to check the chosen ones
		var data = cover_map[id]
		
		# Check if the collider_body is the one from our map
		if data["body"] == collider_body:
			# Found it. Hide the cover and disable its collision.
			data["node"].visible = false
			data["collision"].set_deferred("disabled", true)
			
			# Remove from task list and add to player "inventory"
			chosen_cover_ids.erase(id)
			covers_player_is_holding += 1
			
			# (Optional) Play a pickup sound
			return # We found our item, no need to keep looping

# Call this when the player interacts with FOOD (to cover)
func use(collider_body: PhysicsBody3D) -> void:
	# 1. Check if the player is holding a cover
	if covers_player_is_holding == 0:
		print("Player has no covers to use.")
		# (Optional) Play a "failure" sound
		return
		
	# 2. Find which food item this collider belongs to
	for id in chosen_food_ids: # Only need to check the chosen ones
		var data = food_map[id]
		
		# Check if the collider_body is the one from our map
		if data["body"] == collider_body:
			# Found it. Show the "dish_cover" and disable collision.
			if data["cover"]:
				data["cover"].visible = true
				
			data["collision"].set_deferred("disabled", true)
			
			# "Use up" one cover and remove the food from the task
			covers_player_is_holding -= 1
			chosen_food_ids.erase(id)
			put_cover.play()
			# 3. Check if the task is complete
			if chosen_food_ids.is_empty():
				# --- FIX: Changed "3" to "4" ---
				print("All 4 food items have been covered!")
				task_completed.emit()
				
			return # We found our item, no need to keep looping
