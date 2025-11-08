extends Node

var current_night : int = 1
var max_time_per_night : float = 300
var time_left : float

func _ready() -> void:
	time_left = max_time_per_night

func progress_to_next_night():
	current_night += 1
	time_left = max_time_per_night
	# reset other night-related logic here
