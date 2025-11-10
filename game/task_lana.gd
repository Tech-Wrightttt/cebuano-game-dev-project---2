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

# NEW VARIABLES (from baa2... branch)
var current_lana_pos: Vector3 = Vector3.ZERO  # Ghost reads this to find lures
var deployed_lures: Array[Vector3] = []  # Track all active lure positions

# --- MERGED _ready() ---
func _ready() -> void:
	# From baa2... (for the AI)
	add_to_group("lana_task")
	print("✅ Lana Task added to group 'lana_task'")
	
	# From HEAD (for Global.gd)
	deactivate_all()

# --- MERGED initialize_task() ---
func initialize_task() -> void:
	# From HEAD
	randomize()
	current_night = Global.get_night() 
	
	if current_night == 5:
		chosen_bottle = 10
		# From baa2...
		print("🌙 Night 5: Chose bottle #10")
	else:
		chosen_bottle =  randi() % 9 + 1
		# From baa2...
		print("🌙 Night %d: Chose bottle #%d" % [current_night, chosen_bottle])
	
	# From baa2...
	print("🍾 Lana Task initialized with bottle: %d" % chosen_bottle)
	
	# From HEAD
	update_lana_tasking()

# --- NEW FUNCTION (from HEAD) ---
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

# --- MERGED update_lana_tasking() ---
func update_lana_tasking() -> void:
	# From baa2...
	print("⚙️ Updating lana tasking...")
	
	# From HEAD
	for id in lana_map.keys():
		var data = lana_map[id]
		var is_active = (id == chosen_bottle)
		data["bottle"].visible = is_active
		data["bottle_collision"].set_deferred("disabled", not is_active)
		
		if data["drop"]:
			data["drop"].visible = false
		if data["drop_collision"]:
			data["drop_collision"].set_deferred("disabled", true)
		if data["shadow"]:
			data["shadow"].visible = false
	
	# From baa2...
	print("✅ Lana tasking updated. Active bottle: %d" % chosen_bottle)

# --- MERGED take() ---
func take(_collider_body: PhysicsBody3D) -> void:
	# From baa2...
	print("👜 Player took lana bottle #%d" % chosen_bottle)
	
	# From HEAD
	var bottle_data = lana_map[chosen_bottle]
	bottle_data["bottle"].visible = false
	bottle_data["bottle_collision"].set_deferred("disabled", true)
	drops_deployed_count = 0
	
	# From baa2...
	var shadow_count = 0
	
	# From HEAD
	for id in lana_map.keys():
		var drop_data = lana_map[id]
		if drop_data["shadow"] and drop_data["drop_collision"]:
			drop_data["shadow"].visible = true
			drop_data["drop_collision"].set_deferred("disabled", false)
			# From baa2...
			shadow_count += 1
	
	# From baa2...
	print("👥 Enabled %d drop shadows for deployment" % shadow_count)

# --- MERGED start_deploy_sound() ---
func start_deploy_sound() -> void:
	if not lana_prayer.is_playing():
		lana_prayer.play()
		# From baa2...
		print("🔊 Started lana prayer sound")

# --- MERGED stop_deploy_sound() ---
func stop_deploy_sound() -> void:
	lana_prayer.stop()
	# From baa2...
	print("🔇 Stopped lana prayer sound")

# --- NEW FUNCTION (from baa2...) ---
func consume_lure_at_position(pos: Vector3) -> void:
	print("🔍 Attempting to consume lure at position: %s" % pos)
	var tolerance = 2.0
	
	for id in lana_map.keys():
		var data = lana_map[id]
		if data["drop"] and data["drop"].visible:
			var distance = data["drop"].global_position.distance_to(pos)
			if distance < tolerance:
				print("🍽️ ✅ Lure #%d consumed! (Distance: %.2f)" % [id, distance])
				data["drop"].visible = false
				if data["drop_collision"]:
					data["drop_collision"].set_deferred("disabled", true)
				
				# Remove from deployed lures array
				for i in range(deployed_lures.size() - 1, -1, -1):
					if deployed_lures[i].distance_to(pos) < tolerance:
						deployed_lures.remove_at(i)
						print("📉 Removed lure from array. Remaining lures: %d" % deployed_lures.size())
				
				# Update current_lana_pos
				update_current_lana_pos()
				return
	
	print("❌ No lure found at position %s (tolerance: %.2f)" % [pos, tolerance])

# --- NEW FUNCTION (from baa2...) ---
func update_current_lana_pos() -> void:
	if deployed_lures.is_empty():
		current_lana_pos = Vector3.ZERO
		print("📍 No more lures active, current_lana_pos = Vector3.ZERO")
	else:
		# Point to first active lure
		current_lana_pos = deployed_lures[0]
		print("📍 Updated current_lana_pos to: %s" % current_lana_pos)

# --- MERGED deploy() ---
func deploy(collider_body: PhysicsBody3D) -> void:
	# From baa2...
	print("🎯 Deploy called. Current count: %d/2" % drops_deployed_count)
	
	# From HEAD
	if drops_deployed_count >= 2:
		# From baa2...
		print("⚠️ Already deployed 2 lures, ignoring deploy request")
		return

	for id in lana_map.keys():
		var data = lana_map[id]
		if data["drop_collision"]:
			var body_in_map = data["drop_collision"].get_parent()

			if collider_body == body_in_map:
				var shadow_visual_node = data["shadow"]
				if shadow_visual_node.visible:
					# From baa2...
					print("✨ Deploying lure #%d..." % id)
					
					# From HEAD
					shadow_visual_node.visible = false
					data["drop"].visible = true
					data["drop_collision"].set_deferred("disabled", true)
					
					drops_deployed_count += 1
					
					# --- NEW CODE (from baa2...) ---
					var drop_position = data["drop"].global_position
					deployed_lures.append(drop_position)
					current_lana_pos = drop_position  # Update to latest lure
					
					print("✨ ✅ Lure #%d deployed at: %s" % [id, drop_position])
					print("📍 current_lana_pos updated to: %s" % current_lana_pos)
					print("📊 Total deployed lures: %d" % deployed_lures.size())
					# --- END of baa2... block ---
					
					# From HEAD
					if drops_deployed_count == 2:
						# From baa2...
						print("🔒 Reached max lures (2), disabling remaining shadows...")
						_disable_all_remaining_shadows()
						task_completed.emit()
					return
				else:
					# From baa2...
					print("⚠️ Shadow for lure #%d already hidden" % id)
					return

# --- MERGED _disable_all_remaining_shadows() ---
func _disable_all_remaining_shadows() -> void:
	# From baa2...
	var disabled_count = 0
	
	# From HEAD
	for id in lana_map.keys():
		var data = lana_map[id]
		if data["shadow"] and data["shadow"].visible:
			data["shadow"].visible = false
			if data["drop_collision"]:
				data["drop_collision"].set_deferred("disabled", true)
			# From baa2...
			disabled_count += 1
	
	# From baa2...
	print("🚫 Disabled %d remaining shadows" % disabled_count)

# --- (No changes, just added for completeness) ---
func get_bottle_number() -> int:
	return chosen_bottle