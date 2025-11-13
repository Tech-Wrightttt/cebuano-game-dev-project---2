extends VBoxContainer

const BUSSCENE = preload("res://game/cutscenes/game_intro.tscn")

# Get a reference to the other panel using a relative path
@onready var settings_panel = $"../SettingsPanel"
@onready var controls_panel = $"../ControlsPanel"

# --- JITTER CODE START ---
# How "wild" the jitter is (in degrees).
const JITTER_AMOUNT = 1

# 1. Get references to all buttons
@onready var start_game_button: Button = $"Start Game"
@onready var settings_button: Button = $"Settings"
@onready var controls_button: Button = $"Controls"
@onready var quit_button: Button = $"Quit"

# This variable will store whichever button is *currently* being hovered
var hovered_button: Button = null
# --- JITTER CODE END ---


func _ready():
	# --- JITTER CODE START ---
	# Group all our buttons into an array to set them up easily
	var buttons = [start_game_button, settings_button, controls_button, quit_button]
	
	for button in buttons:
		if button:
			# 2. Connect signals, using bind() to pass the button itself
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	# --- JITTER CODE END ---


# --- JITTER CODE START ---
func _process(_delta):
	# 3. If a button is being hovered, apply rotation jitter
	if hovered_button:
		# Get a random rotation angle (in degrees)
		var jitter_angle = randf_range(-JITTER_AMOUNT, JITTER_AMOUNT)
		
		# Apply jitter to the specific button being hovered
		hovered_button.rotation_degrees = jitter_angle

# 4. This function runs when the mouse enters ANY of the connected buttons
func _on_button_mouse_entered(button: Button):
	hovered_button = button

# 5. This function runs when the mouse leaves ANY of the connected buttons
func _on_button_mouse_exited(button: Button):
	# IMPORTANT: Reset the rotation so it stops shaking
	button.rotation_degrees = 0
	
	# If the mouse is leaving the button we are currently jittering, stop jittering
	if hovered_button == button:
		hovered_button = null
# --- JITTER CODE END ---


# --- Your original functions ---
func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_packed(BUSSCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

# This function runs when the "Settings" button is pressed
func _on_settings_pressed():
	settings_panel.show()
	hide() # This hides the VBoxContainer this script is on
	# This hides all letter nodes in the "TitleLetters" group
	get_tree().call_group("TitleLetters", "hide")
	
func _on_controls_pressed():
	controls_panel.show()
	hide()
	get_tree().call_group("TitleLetters", "hide")
