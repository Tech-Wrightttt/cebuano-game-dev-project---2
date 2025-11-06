extends Node3D

var door_opened = false

@onready var cabinet_animation: AnimationPlayer = $Cabinet_Animation
@onready var cabinet_open: AudioStreamPlayer3D = $Cabinet_Open
@onready var cabinet_close: AudioStreamPlayer3D = $Cabinet_Close

func _ready() -> void:
	cabinet_open.volume_db = -15
	cabinet_close.volume_db = -15
	
func interact():
	if not cabinet_animation.is_playing():
		door_opened = !door_opened
		if door_opened:
			cabinet_animation.play("open_cabinet_1")
			cabinet_open.play()
		else:
			cabinet_animation.play("close_cabinet_1")
			cabinet_close.play()
