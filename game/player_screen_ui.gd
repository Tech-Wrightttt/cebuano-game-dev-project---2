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


func _process(_delta):
	# NEW: Only update and show the UI when the timer is active
	if not Global.timeshow:
		# Hide the clock elements when the timer isn't running
		time_hour_label.visible = false
		time_minute_label.visible = false
		return
		
	# Ensure clock elements are visible once timer starts
	time_hour_label.visible = true
	time_minute_label.visible = true
	
	# --- 1. Update Night Label ---
	# Uses the variable from Global.gd
	night_label.text = "Night: %d" % Global.current_night

	# --- 2. Update Clock ---
	# Calls the get_game_time() function from Global.gd
	var time_dict = Global.get_game_time()
	
	# "%02d" formats the number to always have 2 digits (e.g., "07" instead of "7")
	time_hour_label.text = "%02d" % time_dict["display_hour"]
	time_minute_label.text = "%02d" % time_dict["minute"]

	# --- 3. Build and Update the Task List ---
	var task_text = "TASKS: \n\n"
	
	# Loop through the active tasks given to us by Global.gd
	for task in Global.currently_active_tasks:
		
		# Check if the task is valid and has our progress function
		if is_instance_valid(task) and task.has_method("get_progress_string"):
			
			# Get the status string from the task itself
			# (e.g., "2/3 statues cleaned")
			var progress_string = task.get_progress_string()
			
			# Add it to our list if it's not empty
			if not progress_string.is_empty():
				# The "- " adds a nice bullet point
				task_text += "- " + progress_string + "\n"
				
	# Set the label's text to the new list we built
	task_list_label.text = task_text
