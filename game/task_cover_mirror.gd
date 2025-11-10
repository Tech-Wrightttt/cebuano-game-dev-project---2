extends Node3D

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
	if mirror_map.size() < 3 or towel_map.size() < 3:
		push_warning("Not enough mirrors or towels to start the task.")
		return
		
	randomize()
	
	var all_mirror_ids = mirror_map.keys()
	all_mirror_ids.shuffle()
	chosen_mirror_ids = all_mirror_ids.slice(0, 3)
	
	var all_towel_ids = towel_map.keys()
	all_towel_ids.shuffle()
	chosen_towel_ids = all_towel_ids.slice(0, 3)
	
	update_all_item_states()


# --- INITIAL SETUP ---

# Populates the dictionaries with references to all the nodes
func populate_maps() -> void:
	for mirror_node in mirrors_parent.get_children():
		var id = mirror_node.name
		var collision_body = mirror_node.get_node_or_null("StaticBody3D")
		mirror_map[id] = {
			"node": mirror_node,
			"cover": mirror_node.get_node_or_null("covertowel"),
			"body": collision_body,
			"collision": collision_body.get_node_or_null("CollisionShape3D") if collision_body else null
		}
		
	for towel_node in towels_parent.get_children():
		var id = towel_node.name
		var collision_body = towel_node.get_node_or_null("StaticBody3D")
		towel_map[id] = {
			"node": towel_node,
			"body": collision_body,
			"collision": collision_body.get_node_or_null("CollisionShape3D") if collision_body else null
		}

func update_all_item_states() -> void:
	for id in towel_map.keys():
		var data = towel_map[id]
		var is_chosen = (id in chosen_towel_ids)
		data["node"].visible = is_chosen
		if data["collision"]:
			data["collision"].set_deferred("disabled", not is_chosen)

	for id in mirror_map.keys():
		var data = mirror_map[id]
		var is_chosen = (id in chosen_mirror_ids)
		
		if data["cover"]:
			data["cover"].visible = not is_chosen
			
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
			towels_player_is_holding -= 1
			chosen_mirror_ids.erase(id)
			towel_covering.play()
			if chosen_mirror_ids.is_empty():
				print("All 3 mirrors have been covered!")
			return 
