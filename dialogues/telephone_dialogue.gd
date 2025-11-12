extends Node3D

func _ready() -> void:
	# Connect the signal first
	$AnimationPlayer.animation_finished.connect(_on_animation_finished)
	
	# Start the ending animation
	$AnimationPlayer.play("telephone")

func _on_animation_finished(anim_name: String):
	if anim_name == "telephone":
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
