extends Node3D

@onready var animation_player = $AnimationPlayer  # Adjust path if needed
var removed := false

func _ready() -> void:
	# Play Idle animation when node is ready
	if animation_player:
		animation_player.play("Sitting")
	else:
		print("AnimationPlayer not found!")

func _process(_delta: float) -> void:
	if not removed and Global.completed_dialogues.has("dialogue_trigger1") and Global.completed_dialogues["dialogue_trigger1"]:
		print("HEY NI TRIGGER NI!")
		removed = true
		queue_free()  # Remove grandma1 from scene
		print("DIALOGUE ONE IS FREED!")
		
		
