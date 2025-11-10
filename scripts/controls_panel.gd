extends Control

# Get a reference to the main buttons panel
@onready var main_buttons_panel = $"../VBoxContainer"

# --- JITTER CODE START ---
const JITTER_AMOUNT = 1

# 1. Get reference to the back button
@onready var back_button: Button = $Back2 

var hovered_button: Button = null
# --- JITTER CODE END ---


func _ready():
	# --- JITTER CODE START ---
	# 2. Connect signals for the back button
	if back_button:
		back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
		back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
	# --- JITTER CODE END ---


# --- JITTER CODE START ---
func _process(_delta):
	# 3. If a button is being hovered, apply rotation jitter
	if hovered_button:
		var jitter_angle = randf_range(-JITTER_AMOUNT, JITTER_AMOUNT)
		hovered_button.rotation_degrees = jitter_angle

# 4. This function runs when the mouse enters the back button
func _on_button_mouse_entered(button: Button):
	hovered_button = button

# 5. This function runs when the mouse leaves the back button
func _on_button_mouse_exited(button: Button):
	# IMPORTANT: Reset the rotation so it stops shaking
	button.rotation_degrees = 0
	
	if hovered_button == button:
		hovered_button = null
# --- JITTER CODE END ---


# --- Your original functions ---

# This is the function connected to your "Back2" button's 'pressed' signal
func _on_back_2_pressed() -> void:
	main_buttons_panel.show()
	hide() # This hides the ControlsPanel
	# This shows all letter nodes in the "TitleLetters" group
	get_tree().call_group("TitleLetters", "show")
