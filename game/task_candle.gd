extends Node3D

var collect_Candles: Array = []
var chosen_candles: Array = []
@onready var candle_Scattered = $candleAroundTheHouse
@onready var altar_Candles = $altarTable
@onready var altar_Table_Interaction: CollisionShape3D = $altarTable/StaticBody3D/CollisionShape3D

func _ready():
	randomize()
	collect_Candles = candle_Scattered.get_children()
	
	# --- NIGHT 5 LOGIC ---
	if Global.get_night() == 5:
		print("Night 5: Forcing mandatory candles (13, 14, 15, 16).")
		var mandatory_names = ["Candle13", "Candle14", "Candle15", "Candle16"]
		var mandatory_candles = []
		var other_candles = []
		
		# 1. Separate mandatory candles from other candles
		for candle in collect_Candles:
			if candle.name in mandatory_names:
				mandatory_candles.push_back(candle)
			else:
				other_candles.push_back(candle)
		
		# 2. Shuffle the *other* candles
		other_candles.shuffle()
		
		# 3. We need 8 total candles.
		#    (Calculate how many random ones we need to add to our mandatory list)
		var random_candles_to_get = 8 - mandatory_candles.size()
		
		# 4. Combine the lists (mandatory first, then the random ones)
		chosen_candles = mandatory_candles + other_candles.slice(0, random_candles_to_get)
		
	else:
		# --- Original Logic (for other nights) ---
		collect_Candles.shuffle()
		chosen_candles = collect_Candles.slice(0, 8)
		
	# 5. Continue with setup
	update_candle_tasking()

func update_candle_tasking():
	for candle in collect_Candles:
		var is_active = (candle in chosen_candles)
		candle.visible = is_active
		var collision_shape: CollisionShape3D = candle.get_node_or_null("StaticBody3D/CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", not is_active)
			
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
