extends Node3D
signal task_completed

var all_windows: Array = []
var chosen_windows_to_close: Array = [] 
@onready var windows_Scattered = $windowsAroundTheHouse
@onready var window_double_close: AudioStreamPlayer3D = $Window_Double_Close
@onready var window_single_close: AudioStreamPlayer3D = $Window_Single_Close

func _ready():
	all_windows = windows_Scattered.get_children()
	deactivate_all()

func initialize_task():
	randomize()
	all_windows.shuffle()
	chosen_windows_to_close = all_windows.slice(0, 10)
	update_window_tasking()

func deactivate_all():
	for window_node in all_windows:
		var anim_player: AnimationPlayer = window_node.get_node_or_null("WindowAnimation")
		var collision_shape: CollisionShape3D = window_node.get_node_or_null("StaticBody3D/CollisionShape3D")

		if not anim_player or not collision_shape:
			continue
		
		# Play the "close" animation to ensure it's shut
		anim_player.play("close")
		# Disable collision
		collision_shape.set_deferred("disabled", true)
		
	# --- THIS IS THE FIX ---
	# Reset the list of active tasks for the next night
	chosen_windows_to_close.clear()
		
func update_window_tasking():
	for window_node in all_windows:
		var is_a_chosen_window = (window_node in chosen_windows_to_close)
		
		var anim_player: AnimationPlayer = window_node.get_node_or_null("WindowAnimation")
		var collision_shape: CollisionShape3D = window_node.get_node_or_null("StaticBody3D/CollisionShape3D")

		if not anim_player or not collision_shape:
			push_warning("Window %s is missing AnimationPlayer or StaticBody3D/CollisionShape3D" % window_node.name)
			continue

		if is_a_chosen_window:
			anim_player.play_backwards("close")
			collision_shape.set_deferred("disabled", false)
		else:
			anim_player.play("close")
			collision_shape.set_deferred("disabled", true)

func use(collider_body: PhysicsBody3D):
	var window_node = collider_body.get_parent()
	if window_node in chosen_windows_to_close:
		var anim_player: AnimationPlayer = window_node.get_node_or_null("WindowAnimation")
		var collision_shape: CollisionShape3D = window_node.get_node_or_null("StaticBody3D/CollisionShape3D")
		if anim_player:
			anim_player.play("close")
			var node_name: String = window_node.name
			if node_name.begins_with("single"):
				window_single_close.play()
			elif node_name.begins_with("double"):
				window_double_close.play()
			elif node_name.begins_with("quadruple"):
				window_double_close.play()
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		chosen_windows_to_close.erase(window_node)
		if chosen_windows_to_close.is_empty():
			print("TASK_WINDOWS: All windows closed. Task complete.")
			task_completed.emit()

# ADD THIS ENTIRE FUNCTION
func get_progress_string() -> String:
	if chosen_windows_to_close.is_empty():
		return ""
		
	# This assumes you start with 10. Change '10' if it's different.
	var total_windows = 10
	var closed = total_windows - chosen_windows_to_close.size()
	return "%d/%d windows closed" % [closed, total_windows]
