extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Add screen darkening at start
	add_sleep_overlay()
	
	# Start your animation
	anim_player.play("wake")
	
	# Wait for animation
	await get_tree().create_timer(15.0).timeout
	
	# Remove overlay
	remove_sleep_overlay()

func add_sleep_overlay() -> void:
	var overlay = ColorRect.new()
	overlay.name = "SleepOverlay"
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.size = get_viewport().size
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(overlay)

func remove_sleep_overlay() -> void:
	var overlay = get_tree().root.get_node_or_null("SleepOverlay")
	if overlay:
		var tween = create_tween()
		tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 2.0)
		await tween.finished
		overlay.queue_free()
