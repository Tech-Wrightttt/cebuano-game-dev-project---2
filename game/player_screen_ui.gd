extends CanvasLayer

# --- Link to your new UI nodes ---

# The "Night 1" label
@onready var night_label = $"Night Counter"

# The "SAMPLE TASK" label
@onready var task_list_label = $"TaskToDoLabel"
@onready var tasklabel: Label = $Task

# The "12:" label
@onready var time_hour_label = $Panel/TimerLabelHour

# The ":00" label
@onready var time_minute_label = $Panel/TimerLabelMinutes
@onready var canvas_layer_2: CanvasLayer = $"../CanvasLayer2"


# In your UI Script (the CanvasLayer one)

func _process(_delta):
	# --- 1. Update Night Label (Always) ---
	# This is correct. We always want to see the current night.
	night_label.text = "Night: %d" % Global.current_night
	# --- 2. Check if the game is "active" (timer running) ---
	if not Global.timeshow:
		# Game is paused or in dialogue. Hide tasks AND clock.
		task_list_label.visible = false
		time_hour_label.visible = false
		time_minute_label.visible = false
	
	else:
		# Game is active! Show and update everything.
		task_list_label.visible = true
		time_hour_label.visible = true
		time_minute_label.visible = true

		# --- 3. Update Clock ---
		var time_dict = Global.get_game_time()
		time_hour_label.text = "%02d" % time_dict["display_hour"]
		time_minute_label.text = "%02d" % time_dict["minute"]

		# --- 4. Build and Update the Task List ---
		var task_text = "TASKS: \n\n"
		
		for task in Global.currently_active_tasks:
			if is_instance_valid(task) and task.has_method("get_progress_string"):
				var progress_string = task.get_progress_string()
				if not progress_string.is_empty():
					task_text += "- " + progress_string + "\n"
		
		task_list_label.text = task_text
