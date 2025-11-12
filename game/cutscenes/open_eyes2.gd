extends Node3D

func _ready() -> void:
	# Start the animation
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	
	$AnimationPlayer.play("open eyes")
	
	# Add the quick wake-up effect (fade in and out in 2 seconds)
	await quick_wake_up_effect()
	

func _on_animation_finished(anim_name: String):
	if anim_name == "open eyes":
		create_blackout()

func create_blackout():
	var blackout_layer = CanvasLayer.new()
	blackout_layer.layer = 100
	
	var black_screen = ColorRect.new()
	black_screen.color = Color.TRANSPARENT
	black_screen.size = get_viewport().size  # Use viewport size
	black_screen.anchor_left = 0
	black_screen.anchor_top = 0
	black_screen.anchor_right = 1
	black_screen.anchor_bottom = 1
	
	blackout_layer.add_child(black_screen)
	add_child(blackout_layer)
	
	# Fade to black over 3 seconds
	var tween = create_tween()
	tween.tween_property(black_screen, "color", Color.BLACK, 3.0)
	

func quick_wake_up_effect() -> void:
	# This creates CanvasLayer automatically in code
	var canvas_layer = CanvasLayer.new()
	canvas_layer.name = "SleepOverlayLayer"
	canvas_layer.layer = 100  # Very high layer
	
	var overlay = ColorRect.new()
	overlay.name = "SleepOverlay"
	overlay.color = Color(0, 0, 0, 1.0)  # Start with full black (eyes closed)
	overlay.size = get_viewport().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Center it
	overlay.anchor_left = 0
	overlay.anchor_top = 0
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	
	canvas_layer.add_child(overlay)
	get_tree().root.add_child(canvas_layer)
	
	print("✅ Wake-up effect started")
	
	# Quick fade out over 2 seconds (simulating opening eyes)
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 4.0)
	await tween.finished
	
	# Remove the overlay
	canvas_layer.queue_free()
	print("✅ Wake-up effect completed")
