extends Node3D
@onready var rng = RandomNumberGenerator.new()

func enter_trigger(body) :
	if body.name == "ghost":
		var agent: NavigationAgent3D = body.get_node("NavigationAgent3D")
		var animation_player: AnimationPlayer = body.get_node("ghost_model_animation/AnimationPlayer")
		if agent and agent.is_navigation_finished():
			if animation_player:
				animation_player.play("ghost_idle")
			await get_tree().create_timer(rng.randf_range(1.0, 5.0)).timeout
			body.pick_destination(body.destination_value)
			print("DV: ", body.destination_value)
