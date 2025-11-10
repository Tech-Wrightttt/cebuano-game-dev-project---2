extends Node3D

signal task_completed
var altar_candles_to_light: int = 0
var collect_Candles: Array = []
var chosen_candles: Array = []
@onready var candle_Scattered = $candleAroundTheHouse
@onready var altar_Candles = $altarTable
@onready var altar_Table_Interaction: CollisionShape3D = $altarTable/StaticBody3D/CollisionShape3D

func _ready():
	collect_Candles = candle_Scattered.get_children()
	deactivate_all()

func initialize_task():
	randomize()
	# --- NIGHT 5 LOGIC ---
	if Global.get_night() == 5:
		print("Night 5: Forcing mandatory candles (13, 14, 15, 16).")
		var mandatory_names = ["Candle13", "Candle14", "Candle15", "Candle16"]
		var mandatory_candles = []
		var other_candles = []
		for candle in collect_Candles:
			if candle.name in mandatory_names:
				mandatory_candles.push_back(candle)
			else:
				other_candles.push_back(candle)
		other_candles.shuffle()
		var random_candles_to_get = 8 - mandatory_candles.size()
		chosen_candles = mandatory_candles + other_candles.slice(0, random_candles_to_get)
	else:
		# --- Original Logic (for other nights) ---
		collect_Candles.shuffle()
		chosen_candles = collect_Candles.slice(0, 8)
	# 5. Activate the chosen candles
	update_candle_tasking()

func deactivate_all():
	# Deactivate scattered candles
	for candle in collect_Candles:
		candle.visible = false
		var collision_shape: CollisionShape3D = candle.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
			
	# Deactivate altar candles
	var altar_candle_nodes = altar_Candles.get_children()
	for candle in altar_candle_nodes:
		candle.visible = false
		var collision_shape: CollisionShape3D = candle.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
			
	# Deactivate altar table interaction
	altar_Table_Interaction.set_deferred("disabled", true)
	
func update_candle_tasking():
	# Activate only the chosen scattered candles
	for candle in collect_Candles:
		var is_active = (candle in chosen_candles)
		candle.visible = is_active
		var collision_shape: CollisionShape3D = candle.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", not is_active)
			
	# Altar candles and interaction remain disabled *until*
	# the 'take' function finds that chosen_candles is empty.
	# So, this part of the original function is fine.
	var altar_candle_nodes = altar_Candles.get_children()
	for candle in altar_candle_nodes:
		candle.visible = false
		var collision_shape: CollisionShape3D = candle.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
	altar_Table_Interaction.set_deferred("disabled", true)
	
func take(collider_body: PhysicsBody3D):
	var candle_node = collider_body.get_parent()
	if candle_node in chosen_candles:
		candle_node.visible = false
		var collision_shape = candle_node.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		chosen_candles.erase(candle_node)
		if chosen_candles.is_empty():
			altar_Table_Interaction.set_deferred("disabled", false) 
			
func interact():
	var altar_candle_nodes = altar_Candles.get_children()
	altar_candles_to_light = altar_candle_nodes.size()
	for candle in altar_candle_nodes:
		candle.visible = true
		var collision_shape: CollisionShape3D = candle.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			# Set 'disabled' to 'false' to ENABLE collision
			collision_shape.set_deferred("disabled", false) 
			
	altar_Table_Interaction.set_deferred("disabled", true)
	
func use(collider_body: PhysicsBody3D):
	var candle_node = collider_body.get_parent()
	var anim_player: AnimationPlayer = candle_node.get_node_or_null("AnimationPlayer")
	anim_player.play("burnwick")
	var collision_shape: CollisionShape3D = collider_body.get_node_or_null("CollisionShape3D")
	collision_shape.set_deferred("disabled", true)
	if altar_candles_to_light > 0:
		altar_candles_to_light -= 1
		if altar_candles_to_light == 0:
			print("TASK_CANDLE: All altar candles lit. Task complete.")
			task_completed.emit()

# ADD THIS ENTIRE FUNCTION
func get_progress_string() -> String:
	# Check if we're lighting candles on the altar
	if altar_candles_to_light > 0:
		var total = altar_Candles.get_children().size()
		var lit = total - altar_candles_to_light
		return "%d/%d candles lighted" % [lit, total]
	
	# Check if we're still collecting candles
	if not chosen_candles.is_empty():
		# This assumes you start with 8. Change '8' if it's different.
		var total_to_collect = 8 
		var collected = total_to_collect - chosen_candles.size()
		return "%d/%d candles collected" % [collected, total_to_collect]
		
	# If task is done, hide it
	return ""
