extends Node3D

signal task_completed
var altar_candles_to_light: int = 0
var collect_Candles: Array = []
var chosen_candles: Array = []
@onready var candle_Scattered = $candleAroundTheHouse
@onready var altar_Candles = $altarTable
@onready var altar_Table_Interaction: CollisionShape3D = $altarTable/StaticBody3D/CollisionShape3D
var is_lighting_phase_active: bool

func _ready():
	collect_Candles = candle_Scattered.get_children()
	deactivate_all()

func initialize_task():
	randomize()
	
	# Create a list of all *non-mandatory* candles for general use.
	var mandatory_names = ["Candle13", "Candle14", "Candle15", "Candle16"]
	var mandatory_candles = []
	var other_candles = []
	
	# Split all candles into mandatory and non-mandatory groups
	for candle in collect_Candles:
		if candle.name in mandatory_names:
			mandatory_candles.push_back(candle)
		else:
			other_candles.push_back(candle)
			
	# --- GENERAL LOGIC (Nights 2, 3, 4) ---
	if Global.get_night() != 5:
		other_candles.shuffle() # Only shuffle the non-mandatory ones
		# Select 8 candles from the non-mandatory pool
		chosen_candles = other_candles.slice(0, 8) 
		print("Night %d: Chosen %d random candles." % [Global.get_night(), chosen_candles.size()])

	# --- NIGHT 5 LOGIC ---
	else:
		print("Night 5: Forcing mandatory candles (%s)." % ", ".join(mandatory_names))
		other_candles.shuffle()
		
		# Calculate how many additional random candles are needed to reach 8 total.
		# (e.g., 8 total - 4 mandatory = 4 random needed)
		var random_candles_to_get = 8 - mandatory_candles.size()
		
		# Combine the mandatory candles with the required number of random candles
		chosen_candles = mandatory_candles + other_candles.slice(0, random_candles_to_get)
		print("Night 5: Chosen %d total candles (%d mandatory + %d random)." % [chosen_candles.size(), mandatory_candles.size(), random_candles_to_get])
		
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
	altar_candles_to_light = 8 
	is_lighting_phase_active = true
	
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

func get_progress_string() -> String:
	var total_candles = 8
	
	# 1. Check for Task COMPLETELY DONE
	# The task is done ONLY if the lighting phase was started AND finished.
	if is_lighting_phase_active and altar_candles_to_light == 0:
		return "" # Hide the progress string

	# 2. Check for Lighting ACTIVE/IN PROGRESS
	# If the lighting phase has started AND not finished.
	if is_lighting_phase_active and altar_candles_to_light > 0:
		var lit = total_candles - altar_candles_to_light
		return "%d/%d candles lighted" % [lit, total_candles]
	
	# 3. Check for Collection COMPLETE, Awaiting Placement
	# This state is reached when lighting hasn't started (is_lighting_phase_active == false)
	# AND collection is finished (chosen_candles.is_empty()).
	if chosen_candles.is_empty():
		return "Place the candles on the altar"
	
	# 4. Collection ACTIVE/IN PROGRESS (Fallback state)
	# If we reached here, lighting hasn't started and collection is NOT empty.
	var collected = total_candles - chosen_candles.size()
	return "%d/%d candles collected" % [collected, total_candles]
