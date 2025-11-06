extends RayCast3D

@onready var rock_step: AudioStreamPlayer3D = $"../Sounds/Rock_Step"
@onready var stone_step: AudioStreamPlayer3D = $"../Sounds/Stone_Step"
@onready var grass_step: AudioStreamPlayer3D = $"../Sounds/Grass_Step"
@onready var wood_step: AudioStreamPlayer3D = $"../Sounds/Wood_Step"
@onready var outside_bg: AudioStreamPlayer3D = $"../Sounds/Outside_BG"

var current_surface: String = ""
var outside_bg_playing: bool = false

func play_step_sounds():
	if not is_colliding():
		return
	var collider = get_collider()
	if collider == null:
		return

	var new_surface := ""
	if collider.is_in_group("grass"):
		new_surface = "grass"
	elif collider.is_in_group("wood"):
		new_surface = "wood"
	elif collider.is_in_group("stone"):
		new_surface = "stone"
	elif collider.is_in_group("pavement"):
		new_surface = "pavement"
	else:
		new_surface = "default"

	if new_surface != current_surface:
		match new_surface:
			"grass":
				if not outside_bg_playing:
					outside_bg.play()
					outside_bg_playing = true
				_fade_outside_bg_volume(0.0, 2.5)
			"wood", "stone":
				_fade_outside_bg_volume(-25.0, 2.5)
			"default":
				_fade_outside_bg_volume(0.0, 2.5)
		current_surface = new_surface

	match new_surface:
		"grass":
			grass_step.play()
		"wood":
			wood_step.volume_db = -15
			wood_step.play()
		"stone":
			stone_step.volume_db = -30
			stone_step.play()
		"pavement":
			rock_step.volume_db = -28
			rock_step.play()

func _fade_outside_bg_volume(target_db: float, duration: float):
	if not is_instance_valid(outside_bg):
		return
	var tween := create_tween()
	tween.tween_property(outside_bg, "volume_db", target_db, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
