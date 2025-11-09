extends Panel

@onready var hour_label: Label = $Label
@onready var ampm_label: Label = $Label2

func _ready() -> void:
	update_time()
	# Update every second
	set_process(true)

func _process(_delta: float) -> void:
	update_time()

func update_time():
	var now = Time.get_time_dict_from_system()
	var hour = int(now["hour"])
	var minute = int(now["minute"])
	var ampm = "AM"
	if hour >= 12:
		ampm = "PM"
	var display_hour = hour % 12
	if display_hour == 0:
		display_hour = 12
	# Format minutes with a leading zero
	var time_text = "%02d:%02d" % [display_hour, minute]
	hour_label.text = time_text
	ampm_label.text = ampm
