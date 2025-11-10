extends Node

var current_night: int = 1
const NIGHT_DURATION_REAL := 9 * 60.0 # 9 minutes in seconds
var time_left: float = NIGHT_DURATION_REAL

const NIGHT_START_HOUR := 18 # 6 pm
const NIGHT_END_HOUR := 24 # 12 am

func _ready() -> void:
	time_left = NIGHT_DURATION_REAL

func progress_to_next_night():
	current_night += 1
	time_left = NIGHT_DURATION_REAL
	# reset other night-related logic here

func update_time(delta: float) -> void:
	# Decrement time left each frame (or however you track time)
	time_left = max(time_left - delta, 0.0)

func get_game_time() -> Dictionary:
	var progress = 1.0 - (time_left / NIGHT_DURATION_REAL) # 0.0 at start, 1.0 at end
	var in_game_hour_f = NIGHT_START_HOUR + (NIGHT_END_HOUR - NIGHT_START_HOUR) * progress
	var in_game_hour = int(floor(in_game_hour_f))
	var in_game_minute = int((in_game_hour_f - in_game_hour) * 60)

	var ampm = "PM"
	var display_hour = in_game_hour
	if display_hour == 24 or display_hour == 0:
		ampm = "AM"
		display_hour = 12
	else:
		display_hour = display_hour % 12
		if display_hour == 0:
			display_hour = 12

	return {
		"display_hour": display_hour,
		"minute": in_game_minute,
		"ampm": ampm,
		"time_left": time_left,
		"night_over": time_left <= 0
	}
	
func get_night() -> int:
	return current_night
