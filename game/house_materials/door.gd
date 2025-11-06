extends Node3D

var opened = false
@export var locked = false

@onready var door_open: AudioStreamPlayer3D = $Door_Open
@onready var door_close: AudioStreamPlayer3D = $Door_Close
@onready var door_animation: AnimationPlayer = $Door_Animation

func ai_open_door(body):
	if body.name == "ghost" and !locked and door_animation.current_animation != "open" and !opened:
		opened = true
		door_animation.play("open")
		
func ai_close_door(body):
	if body.name == "ghost" and !locked and door_animation.current_animation != "open" and opened:
		opened = false
		door_animation.play_backwards("open")

func interact():
	if door_animation.current_animation != "open" and door_animation.current_animation != "close":
		opened = !opened
		if !opened:
			door_animation.play_backwards("open")
			door_close.play()
		if opened:
			door_animation.play("open") 
			door_open.play()
			
