extends Node

@onready var task_lana: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Lana"
@onready var task_candle: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Candle"
@onready var task_clean_statue: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Clean_Statue"
@onready var task_close_windows: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Close_Windows"
@onready var task_cover_mirror: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Cover_Mirror"
@onready var task_cover_food: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Cover_Food"
@onready var dialogue_trigger1 = get_node_or_null("grandma 1/dialogue_trigger1")

var completed_dialogues := {}
var available_task_pool: Array = []
var currently_active_tasks: Array = []
var active_task_count: int = 0
var completed_task_count: int = 0

var current_night: int = 1
const NIGHT_DURATION_REAL := 9 * 60.0 # 9 minutes in seconds
var time_left: float = NIGHT_DURATION_REAL
#var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_triggers")

const NIGHT_START_HOUR := 18 # 6 pm
const NIGHT_END_HOUR := 24 # 12 am

func _ready() -> void:
	get_tree().connect("tree_changed", Callable(self, "_on_tree_changed"))
	call_deferred("connect_dialogue_triggers")
	var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_triggers")
	time_left = NIGHT_DURATION_REAL
	available_task_pool = [
		task_candle,
		task_close_windows,
		task_cover_mirror,
		task_cover_food,
		task_clean_statue
	]
	available_task_pool.shuffle()
	
	if current_night == 1:
		for trigger in dialogue_triggers:
			if trigger.name == "DialogueTrigger1":
				trigger.queue_free()
		call_deferred("ready_task")
	# Similar connections for other triggers if needed
	else:
		call_deferred("ready_task")
	
	
func _on_tree_changed():
	if get_tree().current_scene:
		connect_dialogue_triggers()
		
func connect_dialogue_triggers() -> void:
	var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_triggers")
	for trigger in dialogue_triggers:
		var call = Callable(self, "_on_dialogue_finished")
		if not trigger.is_connected("dialogue_finished", call):
			trigger.connect("dialogue_finished", call)


func _on_dialogue_finished(dialogue_name: String) -> void:
	completed_dialogues[dialogue_name] = true
	print("GLOBAL: Dialogue finished -> ", dialogue_name)



func progress_to_next_night():
	# Stop at Night 5
	if current_night >= 5:
		# Add logic here for what happens after the final night
		return

	current_night += 1
	time_left = NIGHT_DURATION_REAL
	
	# Re-ready the tasks for the new night
	# This will call our new logic
	ready_task()
	
func update_time(delta: float) -> void:
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
	
func ready_task()-> void:
	# --- 1. RESET COUNTERS ---
	active_task_count = 0
	completed_task_count = 0
	# FIX: Initialize the active tasks array here, and start it with Lana
	currently_active_tasks = [] 
	# --- 2. DEACTIVATE AND DISCONNECT ALL TASKS ---
	var all_tasks = [
		task_lana, task_candle, task_clean_statue, 
		task_close_windows, task_cover_mirror, task_cover_food
	]
	for task in all_tasks:
		if is_instance_valid(task):
			task.deactivate_all()
			# Disconnect the signal if it was connected from a previous night
			if task.task_completed.is_connected(_on_task_completed):
				task.task_completed.disconnect(_on_task_completed)
	# --- 3. ACTIVATE AND CONNECT LANA (ALWAYS) ---
	if is_instance_valid(task_lana):
		task_lana.initialize_task()
		task_lana.task_completed.connect(_on_task_completed)
		active_task_count += 1
		# FIX: ADD TASK_LANA TO THE ACTIVE ARRAY
		currently_active_tasks.append(task_lana)
	# --- 4. ACTIVATE AND CONNECT RANDOM TASKS ---
	var tasks_needed = min(2 + (current_night - 1), available_task_pool.size())
	# Select the random tasks (excluding Lana)
	var random_tasks_to_add = available_task_pool.slice(0, tasks_needed)
	print("--- Night %s ---" % current_night)
	print("Activating tasks: [Lana] (Always)")
	for task_node in random_tasks_to_add:
		if is_instance_valid(task_node):
			print(" - %s" % task_node.name)
			task_node.initialize_task()
			# --- CONNECT THE SIGNAL ---
			task_node.task_completed.connect(_on_task_completed)
			active_task_count += 1
			# FIX: ADD RANDOM TASK TO THE ACTIVE ARRAY
			currently_active_tasks.append(task_node)
		else:
			push_warning("Tried to activate an invalid task instance.")
	# --- 5. (FOR DEBUGGING) CHECK IF NIGHT SHOULD END ---
	if active_task_count == 0:
		print("GLOBAL: No tasks active. Progressing to next night.")
		progress_to_next_night()


# --- This function handles all "task_completed" signals ---
func _on_task_completed():
	completed_task_count += 1
	print("GLOBAL: Task completed! Progress: %d / %d" % [completed_task_count, active_task_count])

	# Check if all tasks for the night are done
	if completed_task_count >= active_task_count:
		print("GLOBAL: All tasks for Night %d finished. Progressing to next night." % current_night)
		
		# We use call_deferred to prevent bugs from changing night
		# in the middle of a physics frame
		call_deferred("progress_to_next_night")
