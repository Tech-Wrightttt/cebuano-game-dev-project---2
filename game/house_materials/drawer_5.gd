extends Node3D

var drawer_opened = false

@onready var drawer_animation: AnimationPlayer = $"../../Drawer_Animation"
@onready var drawer_open: AudioStreamPlayer3D = $"../../Drawer_Open"
@onready var drawer_close: AudioStreamPlayer3D = $"../../Drawer_Close"

func _ready() -> void:
	drawer_open.volume_db = -15
	drawer_close.volume_db = -15
	
func interact():
	if not drawer_animation.is_playing():
		drawer_opened = !drawer_opened
		if drawer_opened:
			drawer_animation.play("open_shelf_5")
			drawer_open.play()
		else:
			drawer_animation.play("close_shelf_5")
			drawer_close.play()
