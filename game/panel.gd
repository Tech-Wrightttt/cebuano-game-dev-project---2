extends Panel

@onready var hour_label: Label = $TimerLabelHour
@onready var ampm_label: Label = $TimerLabelMinutes

func _ready() -> void:
	# Show initial time immediately (should be 6:00 PM at night start)
	Global.update_time(0) # No delta needed, just refresh time_left state
	update_display()
	set_process(true)

func _process(_delta: float) -> void:
	Global.update_time(_delta)
	update_display()

func update_display():
	var game_time = Global.get_game_time()

	hour_label.text = "%02d:%02d" % [game_time.display_hour, game_time.minute]
	ampm_label.text = game_time.ampm

	if game_time.night_over:
		hour_label.add_theme_color_override("font_color", Color(1, 0, 0)) # Red
		ampm_label.add_theme_color_override("font_color", Color(1, 0, 0))
	else:
		hour_label.add_theme_color_override("font_color", Color(1, 1, 1)) # White
		ampm_label.add_theme_color_override("font_color", Color(1, 1, 1))
	
