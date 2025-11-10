extends Control

# --- ADD THIS FIRST ---
@onready var player_screen_ui: CanvasLayer = $"../PlayerScreenUI"
# --- ADD THIS NEW LINE ---
# This gets the *other* UI layer that holds the sanity/sprint bars
@onready var stats_ui_layer: CanvasLayer = $"../CanvasLayer2"


func _ready() -> void:
	$pause_menu.visible = false

func resume_game ():
	get_tree().paused = false
	$pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# --- ADD THIS SECOND ---
	if is_instance_valid(player_screen_ui):
		player_screen_ui.visible = true
	# --- ADD THIS NEW LINE ---
	if is_instance_valid(stats_ui_layer):
		stats_ui_layer.visible = true
	
func quit_game():
	get_tree().quit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		$pause_menu.visible = !$pause_menu.visible
		get_tree().paused = $pause_menu.visible
		
		# --- ADD THIS THIRD ---
		# This hides the HUD when paused, and shows it when unpaused.
		if is_instance_valid(player_screen_ui):
			player_screen_ui.visible = !$pause_menu.visible
		# --- ADD THIS NEW LINE ---
		if is_instance_valid(stats_ui_layer):
			stats_ui_layer.visible = !$pause_menu.visible

		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if !get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
