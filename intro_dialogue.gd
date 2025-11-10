extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer  # Adjust path if needed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Play the typewriter animation when the dialogue starts
	if animation_player and animation_player.has_animation("typewriter"):
		animation_player.play("typewriter")
	else:
		print("Error: AnimationPlayer not found or 'typewriter' animation missing")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
