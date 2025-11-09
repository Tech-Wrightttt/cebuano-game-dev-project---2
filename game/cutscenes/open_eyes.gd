extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("open eyes")
	await get_tree().create_timer(15, false).timeout
	#get_tree().change_scene_to_file("res://game/level.tscn")
