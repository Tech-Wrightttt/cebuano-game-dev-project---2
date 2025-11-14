extends Node3D

var level_scene = null
var is_loading = false

func _ready() -> void:
	# Start loading the level in the background
	ResourceLoader.load_threaded_request("res://game/level.tscn")
	is_loading = true
	
	# Play animation
	$AnimationPlayer.play("cutscene")
	await $AnimationPlayer.animation_finished
	
	# Wait for level to finish loading (if not already done)
	while is_loading:
		var status = ResourceLoader.load_threaded_get_status("res://game/level.tscn")
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			level_scene = ResourceLoader.load_threaded_get("res://game/level.tscn")
			is_loading = false
			break
		await get_tree().process_frame
	
	# Change scene (instant because it's already loaded)
	if level_scene:
		get_tree().change_scene_to_packed(level_scene)
	else:
		push_error("Failed to load level!")
