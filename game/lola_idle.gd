extends Node3D

@onready var animation_player = $AnimationPlayer  # Adjust path if needed
var removed := false
func _ready() -> void:
	# Play Idle animation when node is ready
	if animation_player:
		animation_player.play("Idle")
	else:
		print("AnimationPlayer not found!")

func _process(_delta: float) -> void:
	if not removed and Global.completed_dialogues.has("dialogue_trigger2") and Global.completed_dialogues["dialogue_trigger2"]:
		print("HEY NI TRIGGER NING DIALOGUE 2!")
		removed = true
		queue_free()  # Remove grandma1 from scene
		print("DIALOGUE TWO IS FREED!")
