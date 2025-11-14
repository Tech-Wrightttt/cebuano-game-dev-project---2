extends Node

@onready var task_lana: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Lana"
@onready var task_candle: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Candle"
@onready var task_clean_statue: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Clean_Statue"
@onready var task_close_windows: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Close_Windows"
@onready var task_cover_mirror: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Cover_Mirror"
@onready var task_cover_food: Node3D = $"/root/level/House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/Task_Cover_Food"
@onready var dialogue_trigger1 = get_node_or_null("grandma 1/dialogue_trigger1")
@onready var dialogue_trigger2 = get_node_or_null("grandma 2/dialogue_trigger2")
@onready var ghost: CharacterBody3D = $"/root/level/House/doors/ghost"
@onready var player = get_node_or_null("res://game/player.tscn")
var timeshow: bool = false

var grandma2_scene := preload("res://game/lola_idle.tscn")
var grandma2_instance : Node3D = null
var completed_dialogues := {}
var available_task_pool: Array = []
var currently_active_tasks: Array = []
var active_task_count: int = 0
var completed_task_count: int = 0
signal night_time_up

var current_night: int = 1
const NIGHT_DURATION_REAL := 30 * 60.0# 9 minutes in seconds
var time_left: float = NIGHT_DURATION_REAL
#var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_triggers")

const NIGHT_START_HOUR := 18 # 6 pm
const NIGHT_END_HOUR := 24 # 12 am

func _ready() -> void:
	get_tree().connect("tree_changed", Callable(self, "_on_tree_changed"))
	call_deferred("connect_dialogue_triggers")
	
	if is_instance_valid(ghost):
		if not night_time_up.is_connected(ghost._on_night_time_up):
			night_time_up.connect(ghost._on_night_time_up)
			print("✅ Global connected to Ghost's time-out handler.") # <- CHECK THIS PRINT
	else:
		push_warning("Ghost node not found at: /root/level/House/doors/ghost")
		
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
		
	call_deferred("disable_grandma2_and_children")
	
func _process(delta: float) -> void:
	# 1. Update the countdown timer
	update_time(delta) 
	# 2. Check for Night End (Time Ran Out)
	# The active_task_count check stops this from running repeatedly after the night ends
	if time_left <= 0.0 and active_task_count > 0:
		print("GLOBAL: TIME RAN OUT! Triggering JUMPSCARE.")
		# Stop further tasks/progression and prevent repeated checks
		active_task_count = 0 
		# 🔔 Emit the signal! This calls the ghost's _on_night_time_up function
		emit_signal("night_time_up")
		# Prevent further updates/checks in this script
		set_process(false)
		set_physics_process(false)

func start_night_timer() -> void:
	timeshow = true
	print("⏱️ Night timer STARTED.")

func _on_tree_changed():
	if get_tree().current_scene:
		connect_dialogue_triggers()
		
func connect_dialogue_triggers() -> void:
	var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_triggers")
	for trigger in dialogue_triggers:
		var call = Callable(self, "_on_dialogue_finished")
		if trigger.has_signal("dialogue_finished"):
			if not trigger.is_connected("dialogue_finished", call):
				trigger.connect("dialogue_finished", call)
		else:
			print("Warning: Node", trigger, "does not have a 'dialogue_finished' signal.")

func _on_dialogue_finished(dialogue_name: String) -> void:
	completed_dialogues[dialogue_name] = true
	print("GLOBAL: Dialogue finished -> ", dialogue_name)
	if !completed_dialogues.is_empty(): # Replace with your actual intro dialogue name(s)
		if not timeshow:
			start_night_timer()

func progress_to_next_night():
	if not is_instance_valid(player):
		push_warning("Cannot progress night - no player")
		return
	
	if current_night >= 5:
		return
	current_night += 1
	time_left = NIGHT_DURATION_REAL

	Global.player.each_night_respawn()
	
	if current_night == 3:
		call_deferred("enable_grandma2_and_children")
	ready_task()
	
func disable_grandma2_and_children():
	var grandma2 = get_tree().current_scene.get_node_or_null("grandma 2")
	if grandma2:
		grandma2.visible = false
		grandma2.set_physics_process(false)
		grandma2.set_process(false)

		for child in grandma2.get_children():
			_disable_node_and_children(child)


func _disable_node_and_children(node):
	node.set_physics_process(false)
	node.set_process(false)

	# Disable areas (collision triggers)
	if node is Area3D or node.is_class("Area3D"):
		node.monitoring = false
		node.set_deferred("monitorable", false)
		# Optionally, also disable collision masks/layers
		node.collision_layer = 0
		node.collision_mask = 0

	# Disable collision shapes
	if node is CollisionShape3D or node.is_class("CollisionShape3D"):
		node.disabled = true

	# For any signals connected, optionally disconnect (if needed)

	# Recursively disable children
	for c in node.get_children():
		_disable_node_and_children(c)

func enable_grandma2_and_children():
	var grandma2 = get_tree().current_scene.get_node_or_null("grandma 2")
	if grandma2:
		grandma2.visible = true
		grandma2.set_physics_process(true)
		grandma2.set_process(true)

		for child in grandma2.get_children():
			_enable_node_and_children(child)


func _enable_node_and_children(node):
	node.set_physics_process(true)
	node.set_process(true)

	# Enable areas (collision triggers)
	if node is Area3D or node.is_class("Area3D"):
		node.monitoring = true
		node.set_deferred("monitorable", true)
		# Restore collision layers/masks if needed
		node.collision_layer = 1  # Adjust as needed
		node.collision_mask = 1   # Adjust as needed

	# Enable collision shapes
	if node is CollisionShape3D or node.is_class("CollisionShape3D"):
		node.disabled = false

	# Recursively enable children
	for c in node.get_children():
		_enable_node_and_children(c)
	
	
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
		
func reset_game_state():
	"""Call this when returning to main menu or starting a new game"""
	current_night = 0
	completed_dialogues.clear()
	player = null
	print("🔄 Game state reset")
		
