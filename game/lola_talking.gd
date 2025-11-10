extends Node3D

@onready var animation_player = $AnimationPlayer  # Adjust path if needed

func _ready() -> void:
	# Play Idle animation when node is ready
	if animation_player:
		animation_player.play("Talking")
	else:
		print("AnimationPlayer not found!")

func _process(_delta: float) -> void:
	pass
