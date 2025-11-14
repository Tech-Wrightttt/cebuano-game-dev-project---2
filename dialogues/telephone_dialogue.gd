extends Node3D

var blackout_layer: CanvasLayer

func _ready() -> void:
	print("=== SCENE DEBUG INFO ===")
	print("AnimationPlayer exists: ", $AnimationPlayer != null)
	print("floor_wake_up exists: ", has_node("floor_wake_up"))
	
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	
	if has_node("floor_wake_up"):
		$floor_wake_up.hide()
		print("floor_wake_up hidden successfully")
	
	$AnimationPlayer.play("telephone")
	print("Started telephone animation")

func _on_animation_finished(anim_name: String):
	print("Animation finished: ", anim_name)
	if anim_name == "telephone":
		create_blackout()

func create_blackout():
	print("Creating blackout...")
	blackout_layer = CanvasLayer.new()
	blackout_layer.layer = 100
	
	var black_screen = ColorRect.new()
	black_screen.color = Color.TRANSPARENT
	black_screen.size = get_viewport().size
	black_screen.anchor_left = 0
	black_screen.anchor_top = 0
	black_screen.anchor_right = 1
	black_screen.anchor_bottom = 1
	
	blackout_layer.add_child(black_screen)
	add_child(blackout_layer)
	
	var tween = create_tween()
	tween.tween_property(black_screen, "color", Color.BLACK, 5.0)
	await tween.finished
	transition_to_wake_up()

func transition_to_wake_up():
	print("Attempting to transition to wake up...")
	
	if has_node("floor_wake_up"):
		# Remove blackout first so we can see the animation
		if blackout_layer:
			blackout_layer.queue_free()
			print("Blackout removed")
		
		# Show the floor_wake_up node
		$floor_wake_up.show()
		print("floor_wake_up shown successfully")
		
		# Wait a frame for it to initialize
		await get_tree().process_frame
		
		# Call the wake sequence method directly
		if $floor_wake_up.has_method("start_wake_sequence"):
			print("Calling start_wake_sequence on floor_wake_up...")
			await $floor_wake_up.start_wake_sequence()
			print("Wake sequence completed!")
		else:
			print("ERROR: floor_wake_up doesn't have start_wake_sequence method!")
			
			# Fallback: try to play animation directly
			if $floor_wake_up.has_node("AnimationPlayer"):
				$floor_wake_up/AnimationPlayer.play("wake")
				print("Fallback: playing wake animation directly")
	else:
		print("ERROR: floor_wake_up node not found!")
