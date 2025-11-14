extends Control

@onready var player_screen_ui: CanvasLayer = $"../PlayerScreenUI"
@onready var stats_ui_layer: CanvasLayer = $"../CanvasLayer2"
const MAIN_MENU_SCENE = preload("res://game/main_menu.tscn")

func _ready() -> void:
	$pause_menu.visible = false

func resume_game ():
	get_tree().paused = false
	$pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if is_instance_valid(player_screen_ui):
		player_screen_ui.visible = true
	if is_instance_valid(stats_ui_layer):
		stats_ui_layer.visible = true
	
func quit_game():
	get_tree().quit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		$pause_menu.visible = !$pause_menu.visible
		get_tree().paused = $pause_menu.visible
		
		if is_instance_valid(player_screen_ui):
			player_screen_ui.visible = !$pause_menu.visible
		if is_instance_valid(stats_ui_layer):
			stats_ui_layer.visible = !$pause_menu.visible

		if get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if !get_tree().paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_main_menu_pressed() -> void:
	# 1. Unpause the game (crucial before changing scenes)
	get_tree().paused = false
	
	# 2. Reset the Global state (PREVENTS CARRY-OVER NIGHT/TASK DATA)
	# Assuming 'Global' is the name of your AutoLoad script
	if is_instance_valid(Global):
		Global.reset_game_state()
	
	# 3. Change the scene to the Main Menu
	# change_scene_to_packed() unloads the current game scene before loading the new one.
	var error = get_tree().change_scene_to_packed(MAIN_MENU_SCENE)
	
	if error != OK:
		push_error("Failed to load Main Menu scene: ", error)
	
