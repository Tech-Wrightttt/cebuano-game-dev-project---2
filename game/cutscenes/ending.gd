extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide all characters at start
	$"lola talking".hide()
	$"paulette offered".hide()
	$"lola laugh".hide()
	
	# Start the ending animation
	$AnimationPlayer.play("ending")
	
	# Set up all character appearances at their absolute times
	setup_character_timings()
	
	# Wait for the entire animation to complete (60 seconds)
	await get_tree().create_timer(60.0).timeout
	
	# Uncomment when ready to change scene
	# get_tree().change_scene_to_file("res://game/level.tscn")

func setup_character_timings() -> void:
	# lola talking shows at 8s, hides at 30s
	get_tree().create_timer(8.0).timeout.connect(func(): $"lola talking".show())
	get_tree().create_timer(30.0).timeout.connect(func(): $"lola talking".hide())
	
	# paulette offered shows at 28s
	get_tree().create_timer(0.0).timeout.connect(func(): $"paulette offered".show())
	
	# lola laugh shows at 44s
	get_tree().create_timer(44.0).timeout.connect(func(): $"lola laugh".show())
