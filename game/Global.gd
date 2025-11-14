extends Node

# --- 1. VARIABLES ARE DECLARED, BUT NOT ASSIGNED ---
# We remove the @onready paths. These will be assigned by start_night_logic()
var task_lana: Node3D 
var task_candle: Node3D 
var task_clean_statue: Node3D
var task_close_windows: Node3D 
var task_cover_mirror: Node3D 
var task_cover_food: Node3D
var dialogue_trigger1: Node
var dialogue_trigger2: Node
var ghost: CharacterBody3D
var player: Node # Use generic Node to avoid loading errors

# --- ALL YOUR OTHER VARIABLES (UNCHANGED) ---
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
const NIGHT_DURATION_REAL := 17 * 60.0 # 9 minutes in seconds
var time_left: float = NIGHT_DURATION_REAL

const NIGHT_START_HOUR := 18 # 6 pm
const NIGHT_END_HOUR := 24 # 12 am

# --- 2. _ready() IS MINIMAL ---
func _ready() -> void:
	# All setup logic is MOVED to start_night_logic()
	# We just reset the state when Global first loads.
	reset_game_state()

# --- 3. THE NEW "IGNITION" FUNCTION ---
# This function is called by level.gd *after* the level scene has loaded.
func start_night_logic(level_root: Node3D):
	print("🔌 Global: Connecting to level nodes inside: ", level_root.name)

	# --- ASSIGN NODE VARIABLES (Moved from the top) ---
	var chores_path = "House/doors/NavigationRegion3D/ITEMS/CHORES ITEMS/"
	task_lana = level_root.get_node_or_null(chores_path + "Task_Lana")
	task_candle = level_root.get_node_or_null(chores_path + "Task_Candle")
	task_clean_statue = level_root.get_node_or_null(chores_path + "Task_Clean_Statue")
	task_close_windows = level_root.get_node_or_null(chores_path + "Task_Close_Windows")
	task_cover_mirror = level_root.get_node_or_null(chores_path + "Task_Cover_Mirror")
	task_cover_food = level_root.get_node_or_null(chores_path + "Task_Cover_Food")
	
	dialogue_trigger1 = level_root.get_node_or_null("grandma 1/dialogue_trigger1")
	dialogue_trigger2 = level_root.get_node_or_null("grandma 2/dialogue_trigger2")
	ghost = level_root.get_node_or_null("House/doors/ghost")
	player = level_root.get_node_or_null("Player")

	# --- RUN ALL YOUR SETUP LOGIC (Moved from _ready) ---
	call_deferred("connect_dialogue_triggers")
	
	if is_instance_valid(ghost):
		if not night_time_up.is_connected(ghost._on_night_time_up):
			night_time_up.connect(ghost._on_night_time_up)
			print("✅ Global connected to Ghost's time-out handler.")
	else:
		push_warning("Ghost node not found. Check path in start_night_logic.")
		
	time_left = NIGHT_DURATION_REAL
	
	# Build the task pool *after* nodes are found
	available_task_pool = [
		task_candle,
		task_close_windows,
		task_cover_mirror,
		task_cover_food,
		task_clean_statue
	]
	available_task_pool.shuffle()
	
	if current_night == 1:
		var dialogue_triggers = get_tree().get_nodes_in_group("dialogue_triggers")
		for trigger in dialogue_triggers:
			if trigger.name == "DialogueTrigger1":
				trigger.queue_free()
		call_deferred("ready_task")
	else:
		call_deferred("ready_task")
		
	call_deferred("disable_grandma2_and_children")
	
	# Enable processing (for the timer) only when the game starts
	set_process(true)


# --- 4. _process() IS MODIFIED TO PREVENT DOUBLE-SPEED TIMER ---
func _process(delta: float) -> void:
	# This check prevents the timer from running on the main menu
	# and STOPS the "double-speed" bug from your UI script.
	if not timeshow:
		return
		
	# 1. Update the countdown timer (ONLY DO IT HERE)
	update_time(delta) 
	
	# 2. Check for Night End
	if time_left <= 0.0 and active_task_count > 0:
		print("GLOBAL: TIME RAN OUT! Triggering JUMPSCARE.")
		active_task_count = 0 
		emit_signal("night_time_up")
		set_process(false) # Stop processing
		timeshow = false # Stop timer logic


# --- 5. YOUR ORIGINAL FUNCTIONS (UNCHANGED) ---
# All your game logic functions are preserved.

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
	if !completed_dialogues.is_empty():
		if not timeshow:
			start_night_timer()

func progress_to_next_night():
	# Check for player (which is now assigned correctly)
	if not is_instance_valid(player):
		push_warning("Cannot progress night - no player")
		return
	
	if current_night > 6:
		return
		
	current_night += 1
	time_left = NIGHT_DURATION_REAL

	if player.has_method("each_night_respawn"):
		player.each_night_respawn()
	
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
	if node is Area3D or node.is_class("Area3D"):
		node.monitoring = false
		node.set_deferred("monitorable", false)
		node.collision_layer = 0
		node.collision_mask = 0
	if node is CollisionShape3D or node.is_class("CollisionShape3D"):
		node.disabled = true
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
	if node is Area3D or node.is_class("Area3D"):
		node.monitoring = true
		node.set_deferred("monitorable", true)
		node.collision_layer = 1 
		node.collision_mask = 1 
	if node is CollisionShape3D or node.is_class("CollisionShape3D"):
		node.disabled = false
	for c in node.get_children():
		_enable_node_and_children(c)
	
func update_time(delta: float) -> void:
	time_left = max(time_left - delta, 0.0)

# --- 6. YOUR get_game_time() (UNCHANGED, IT WAS ALREADY CORRECT) ---
func get_game_time() -> Dictionary:
	var progress = 1.0 - (time_left / NIGHT_DURATION_REAL)
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
	active_task_count = 0
	completed_task_count = 0
	currently_active_tasks = [] 
	
	var all_tasks = [
		task_lana, task_candle, task_clean_statue, 
		task_close_windows, task_cover_mirror, task_cover_food
	]
	
	for task in all_tasks:
		if is_instance_valid(task):
			task.deactivate_all()
			if task.task_completed.is_connected(_on_task_completed):
				task.task_completed.disconnect(_on_task_completed)
		else:
			# This will help debug if a task is still null
			print("Warning: A task in all_tasks is not valid during ready_task()")

	# --- 1. Activate Lana (Always) ---
	if is_instance_valid(task_lana):
		task_lana.initialize_task()
		task_lana.task_completed.connect(_on_task_completed)
		active_task_count += 1
		currently_active_tasks.append(task_lana)
	else:
		# This is the error you were seeing before
		push_error("Task Lana is NULL. Cannot start night.")
		return # Stop here to prevent errors
		
	# --- 2. Activate Random Tasks (Re-enabled) ---
	# We slice from the *available_task_pool*, which doesn't include Lana
	var tasks_needed = min(2 + (current_night - 1), available_task_pool.size())
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
			# --- ADD RANDOM TASK TO THE ACTIVE ARRAY ---
			currently_active_tasks.append(task_node)
		else:
			push_warning("Tried to activate an invalid task instance from the pool.")
			
	if active_task_count == 1: # Only Lana is active
		print("Warning: No random tasks were activated (this is normal for Night 1).")
	
	# Check if no tasks were activated at all (in case Lana was also null)
	if active_task_count == 0:
		print("GLOBAL: No tasks active. Progressing.")
		progress_to_next_night()
		
func _on_task_completed():
	completed_task_count += 1
	print("GLOBAL: Task completed! Progress: %d / %d" % [completed_task_count, active_task_count])

	if completed_task_count >= active_task_count:
		print("GLOBAL: All tasks for Night %d finished. Progressing..." % current_night)
		call_deferred("progress_to_next_night")
		
# --- 7. IMPROVED reset_game_state() ---
func reset_game_state():
	"""Call this when returning to main menu or starting a new game"""
	current_night = 1 # Start at Night 1, not 0
	completed_dialogues.clear()
	player = null
	
	# Reset timer state completely
	timeshow = false
	time_left = NIGHT_DURATION_REAL
	active_task_count = 0
	
	# Ensure process is stopped (it will be re-enabled by start_night_logic)
	set_process(false)
	
	print("🔄 Game state reset")
