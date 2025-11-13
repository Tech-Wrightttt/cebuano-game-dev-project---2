extends RayCast3D

@onready var crosshair = get_parent().get_parent().get_node("player_ui/CanvasLayer/crosshair")
@onready var item_interact: AudioStreamPlayer3D = $"../../Sounds/Take_Item"
@onready var interaction_label: Label = $"../Camera3D/Filters/Interaction_Label"
# Map groups to the method to call and the key to display
var group_interactions := {
	"interactable": {"method": "interact", "key": "E", "type": "press"},
	"equipable": {"method": "take", "key": "F", "type": "press"},
	"deployable": {"method": "use", "key": "F", "type": "press"}, 
	"hold_deploy": {"method": "use", "key": "F", "type": "hold"},
}

var hold_time: float = 0.0
const USE_HOLD_DURATION: float = 7.0  # The time to hold for deployables, in seconds
var last_collider: Node = null # To track if we look away
var last_node_with_method: Node = null
var is_holding_interact: bool = false  # Track when player is holding an interaction

func _physics_process(delta: float) -> void:
	var collider = get_collider()
	# --- RESET LOGIC (WHEN LOOKING AT NOTHING) ---
	if not collider or (collider is CollisionShape3D and collider.disabled):
		if interaction_label:
			interaction_label.hide()
		if last_node_with_method and last_node_with_method.has_method("stop_deploy_sound"):
			last_node_with_method.call("stop_deploy_sound")
		hold_time = 0.0 # Reset timer
		last_collider = null
		last_node_with_method = null  # FIX: Added this reset
		is_holding_interact = false  # FIX: Added this reset
		if crosshair.visible:
			crosshair.visible = false
		return
	if collider is Node3D:
		var col = collider.get_node_or_null("CollisionShape3D")
		if col and col.disabled:
			if interaction_label:
				interaction_label.hide()
			if last_node_with_method and last_node_with_method.has_method("stop_deploy_sound"):
				last_node_with_method.call("stop_deploy_sound")
			hold_time = 0.0 # Reset timer
			last_collider = null
			last_node_with_method = null  # FIX: Added this reset
			is_holding_interact = false  # FIX: Added this reset
			if crosshair.visible:
				crosshair.visible = false
			return
	# --- END RESET LOGIC ---

	var interaction_found := false
	for group_name in group_interactions.keys():
		if collider.is_in_group(group_name):
			if !crosshair.visible:
				crosshair.visible = true
			# Get all interaction data from the map
			var data = group_interactions[group_name]
			var method_name = data["method"]
			var key_text = data["key"]
			var interaction_type = data["type"] # Get the "type" ("press" or "hold")
			# Walk up the tree to find the method
			var node = collider
			while node and not node.has_method(method_name):
				node = node.get_parent()

			if node and node.has_method(method_name):
				# Check if player looked at a NEW object
				if last_collider != collider:
					if last_node_with_method and last_node_with_method.has_method("stop_deploy_sound"):
						last_node_with_method.call("stop_deploy_sound")
					hold_time = 0.0 # Reset timer
					last_collider = collider # Update what we're looking at
					is_holding_interact = false  # FIX: Reset when looking at new object
				
				# FIX: Update the last node with method (THIS WAS MISSING!)
				last_node_with_method = node

				var input_action = "interact" if key_text == "E" else "item_interact"
				# --- START: LOGIC BASED ON INTERACTION TYPE ---
				if interaction_type == "hold":
					# Determine hold duration based on group
					var hold_duration = USE_HOLD_DURATION
					# --- HOLD LOGIC (for "hold_deploy" and "window") ---
					if Input.is_action_just_pressed(input_action):
						if node.has_method("start_deploy_sound") and group_name == "hold_deploy":
							node.call("start_deploy_sound")
							
					if Input.is_action_pressed(input_action):
						# Key is being held
						is_holding_interact = true  # FIX: Set to true when holding
						hold_time += delta
						# Update label to show progress
						var percent = int(clamp(hold_time / hold_duration, 0.0, 1.0) * 100)
						if interaction_label:
							interaction_label.text = "[Hold %s] %s... %d%%" % [key_text, method_name.capitalize(), percent]
							interaction_label.show()
						if hold_time >= hold_duration:
							# --- ACTION TRIGGERED ---
							if group_name == "hold_deploy":
								node.call(method_name, collider) # Pass collider for deployables
							else:
								node.call(method_name) # Don't pass collider for windows
							hold_time = 0.0
							is_holding_interact = false
							if interaction_label:
								interaction_label.hide()
					
					elif Input.is_action_just_released(input_action):
						# Key was released too early
						if node.has_method("stop_deploy_sound") and group_name == "hold_deploy":
							node.call("stop_deploy_sound")
						hold_time = 0.0
						is_holding_interact = false
						if interaction_label:
							interaction_label.text = "[Hold %s] %s" % [key_text, method_name.capitalize()]
							interaction_label.show()
					
					else:
						# Key is not being pressed
						hold_time = 0.0
						is_holding_interact = false
						if interaction_label:
							interaction_label.text = "[Hold %s] %s" % [key_text, method_name.capitalize()]
							interaction_label.show()
						
				elif interaction_type == "press":
					# --- PRESS LOGIC (for "interactable", "equipable", "deployable") ---
					is_holding_interact = false
					if interaction_label:
						interaction_label.text = "[%s] %s" % [key_text, method_name.capitalize()]
						interaction_label.show()
					
					if Input.is_action_just_pressed(input_action):
						if method_name == "use":
							node.call("use", collider)
						elif method_name == "take":
							item_interact.volume_db = -33
							item_interact.play()
							node.call("take", collider)
						else: # This will catch "interact"
							node.call(method_name)
						if interaction_label:
							interaction_label.hide()

				# --- END: NEW LOGIC ---
				
				interaction_found = true
				break

	if not interaction_found:
		if last_node_with_method and last_node_with_method.has_method("stop_deploy_sound"):
			last_node_with_method.call("stop_deploy_sound")
		if interaction_label:
			interaction_label.hide()
		hold_time = 0.0 # Reset timer
		last_collider = null
		last_node_with_method = null  # FIX: Added this reset
		is_holding_interact = false  # FIX: Added this reset
		if crosshair.visible:
			crosshair.visible = false

# Called by player movement script to check if movement should be disabled
# Returns true when player is holding E to interact with a window or holding F for deployables
func is_player_movement_disabled() -> bool:
	return is_holding_interact
