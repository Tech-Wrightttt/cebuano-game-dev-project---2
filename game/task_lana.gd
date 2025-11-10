extends Node3D

signal task_completed
@onready var lana_prayer: AudioStreamPlayer3D = $Lana_Prayer
# Lana bottle nodes
@onready var lana_map := {
	1: {
		"bottle": $"lanabottles/lana bottle1",
		"bottle_collision": $lanabottles/"lana bottle1"/lanastatic1/lanacollision1,
		"drop": $lanadropsarray/lanadropscontainer1/lanadrops1,
		"drop_collision": $lanadropsarray/lanadropscontainer1/lanadrops1/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer1/lanadropsshadow1
	},
	2: {
		"bottle": $lanabottles/"lana bottle2",
		"bottle_collision": $lanabottles/"lana bottle2"/lanastatic2/lanacollision2,
		"drop": $lanadropsarray/lanadropscontainer2/lanadrops2,
		"drop_collision": $lanadropsarray/lanadropscontainer2/lanadrops2/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer2/lanadropsshadow2
	},
	3: {
		"bottle": $lanabottles/"lana bottle3",
		"bottle_collision": $lanabottles/"lana bottle3"/lanastatic3/lanacollision3,
		"drop": $lanadropsarray/lanadropscontainer3/lanadrops3,
		"drop_collision": $lanadropsarray/lanadropscontainer3/lanadrops3/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer3/lanadropsshadow3
	},
	4: {
		"bottle": $lanabottles/"lana bottle4",
		"bottle_collision": $lanabottles/"lana bottle4"/lanastatic4/lanacollision4,
		"drop": $lanadropsarray/lanadropscontainer4/lanadrops4,
		"drop_collision": $lanadropsarray/lanadropscontainer4/lanadrops4/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer4/lanadropsshadow4
	},
	5: {
		"bottle": $lanabottles/"lana bottle5",
		"bottle_collision": $lanabottles/"lana bottle5"/lanastatic5/lanacollision5,
		"drop": $lanadropsarray/lanadropscontainer5/lanadrops5,
		"drop_collision": $lanadropsarray/lanadropscontainer5/lanadrops5/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer5/lanadropsshadow5
	},
	6: {
		"bottle": $"../../2ND FLOOR ITEMS/shelf3(maopen)/RootNode/DRAWER3/Door/lana bottle6",
		"bottle_collision": $"../../2ND FLOOR ITEMS/shelf3(maopen)/RootNode/DRAWER3/Door/lana bottle6/lanastatic6/lanacollision6",
		"drop": $lanadropsarray/lanadropscontainer6/lanadrops6,
		"drop_collision": $lanadropsarray/lanadropscontainer6/lanadrops6/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer6/lanadropsshadow6
	},
	7: {
		"bottle": $"../../2ND FLOOR ITEMS/shelf2(maopen)/RootNode/DRAWER1/Door/lana bottle7",
		"bottle_collision": $"../../2ND FLOOR ITEMS/shelf2(maopen)/RootNode/DRAWER1/Door/lana bottle7/lanastatic7/lanacollision7",
		"drop": $lanadropsarray/lanadropscontainer7/lanadrops7,
		"drop_collision": $lanadropsarray/lanadropscontainer7/lanadrops7/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer7/lanadropsshadow7
	},
	8: {
		"bottle":$"../../2ND FLOOR ITEMS/shelf4(maopen)/RootNode/DRAWER1/Door/lana bottle8",
		"bottle_collision": $"../../2ND FLOOR ITEMS/shelf4(maopen)/RootNode/DRAWER1/Door/lana bottle8/lanastatic8/lanacollision8",
		"drop": $lanadropsarray/lanadropscontainer8/lanadrops8,
		"drop_collision": $lanadropsarray/lanadropscontainer8/lanadrops8/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer8/lanadropsshadow8
	},
	9: {
		"bottle": $"../../2ND FLOOR ITEMS/shelf4(maopen)/RootNode/DRAWER6/Door/lana bottle9",
		"bottle_collision": $"../../2ND FLOOR ITEMS/shelf4(maopen)/RootNode/DRAWER6/Door/lana bottle9/lanastatic9/lanacollision9",
		"drop": $lanadropsarray/lanadropscontainer9/lanadrops9,
		"drop_collision": $lanadropsarray/lanadropscontainer9/lanadrops9/StaticBody3D/CollisionShape3D,
		"shadow": $lanadropsarray/lanadropscontainer9/lanadropsshadow9
	},
	10: {
		"bottle": $"lanabottles/lana bottle10",
		"bottle_collision": $lanabottles/"lana bottle10"/lanastatic10/lanacollision10,
		"drop": null,
		"drop_collision": null,
		"shadow": null
	}
}

var current_night = 1
var chosen_bottle: int = -1
var drops_deployed_count: int = 0

func _ready() -> void:
	deactivate_all()

func initialize_task() -> void:
	randomize()
	# Get the most current night info from Global
	current_night = Global.get_night() 
	
	if current_night == 5:
		chosen_bottle = 10
	else:
		chosen_bottle = randi() % 9 + 1
	update_lana_tasking()

func deactivate_all() -> void:
	for id in lana_map.keys():
		var data = lana_map[id]
		data["bottle"].visible = false
		data["bottle_collision"].set_deferred("disabled", true)
		
		if data["drop"]:
			data["drop"].visible = false
		if data["drop_collision"]:
			data["drop_collision"].set_deferred("disabled", true)
		if data["shadow"]:
			data["shadow"].visible = false
			
func update_lana_tasking() -> void:
	for id in lana_map.keys():
		var data = lana_map[id]
		var is_active = (id == chosen_bottle)
		data["bottle"].visible = is_active
		data["bottle_collision"].set_deferred("disabled", not is_active)
		# Drops and shadows hidden/disabled initially
		# --- ADDED NULL CHECKS ---
		if data["drop"]:
			data["drop"].visible = false
		if data["drop_collision"]:
			data["drop_collision"].set_deferred("disabled", true)
		if data["shadow"]:
			data["shadow"].visible = false
		# --- END OF NULL CHECKS ---

func take(_collider_body: PhysicsBody3D) -> void:
	var bottle_data = lana_map[chosen_bottle]
	bottle_data["bottle"].visible = false
	bottle_data["bottle_collision"].set_deferred("disabled", true)
	# Enable chosen drop shadows
	drops_deployed_count = 0
	# Activate shadows for chosen drops
	for id in lana_map.keys():
		var drop_data = lana_map[id]
		# Check if the shadow and collision nodes exist (they are null for ID 10)
		if drop_data["shadow"] and drop_data["drop_collision"]:
			drop_data["shadow"].visible = true
			drop_data["drop_collision"].set_deferred("disabled", false)

func start_deploy_sound() -> void:
	if not lana_prayer.is_playing():
		lana_prayer.play()

func stop_deploy_sound() -> void:
	lana_prayer.stop()
	
func deploy(collider_body: PhysicsBody3D) -> void:
	# --- NEW: Guard clause to stop after 2 deployments
	if drops_deployed_count >= 2:
		return

	for id in lana_map.keys():
		var data = lana_map[id]
		# Make sure this ID has a drop_collision before checking it
		if data["drop_collision"]:
			# Get the StaticBody3D from the CollisionShape3D
			var body_in_map = data["drop_collision"].get_parent()

			if collider_body == body_in_map:
				var shadow_visual_node = data["shadow"]
				# Check if the shadow is still visible (prevents deploying twice)
				if shadow_visual_node.visible:
					shadow_visual_node.visible = false # Hide the SHADOW
					data["drop"].visible = true        # Show the DROP
					data["drop_collision"].set_deferred("disabled", true)
					
					# --- NEW: Increment counter
					drops_deployed_count += 1
					
					# --- NEW: If this was the 2nd drop, disable all other shadows
					if drops_deployed_count == 2:
						_disable_all_remaining_shadows()
						task_completed.emit()
				return

# --- NEW FUNCTION ---
# Loops through and disables all shadows that are still visible
func _disable_all_remaining_shadows() -> void:
	for id in lana_map.keys():
		var data = lana_map[id]
		# Check if shadow exists and is currently visible
		if data["shadow"] and data["shadow"].visible:
			data["shadow"].visible = false
			# Also disable its collision
			if data["drop_collision"]:
				data["drop_collision"].set_deferred("disabled", true)

func get_bottle_number() -> int:
	return chosen_bottle
