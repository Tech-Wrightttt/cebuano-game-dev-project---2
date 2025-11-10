extends VBoxContainer

# Get a reference to the main buttons panel
@onready var main_buttons_panel = $"../VBoxContainer"

# --- JITTER CODE START ---
const JITTER_AMOUNT = 1
@onready var back_button: Button = $Back
var hovered_button: Button = null
# --- JITTER CODE END ---

# --- NEW RESOLUTION/VOLUME NODES ---
# Get references to your settings nodes
@onready var resolution_button: OptionButton = $Resolution
@onready var volume_slider: HSlider = $Volume # Assuming your slider is named "Volume"

func _ready():
	# --- JITTER CODE START ---
	if back_button:
		back_button.mouse_entered.connect(_on_button_mouse_entered.bind(back_button))
		back_button.mouse_exited.connect(_on_button_mouse_exited.bind(back_button))
	# --- JITTER CODE END ---
	
	# --- NEW CODE: SET CURRENT RESOLUTION ---
	# Get current window size
	var current_size = DisplayServer.window_get_size()
	
	# Match current size to the button index
	if current_size == Vector2i(1920, 1080):
		resolution_button.select(0)
	elif current_size == Vector2i(1600, 900):
		resolution_button.select(1)
	elif current_size == Vector2i(1280, 720):
		resolution_button.select(2)
	
	# --- NEW CODE: SET CURRENT VOLUME ---
	# Set slider to match the master volume
	volume_slider.value = AudioServer.get_bus_volume_db(0)


# --- JITTER CODE START ---
func _process(_delta):
	if hovered_button:
		var jitter_angle = randf_range(-JITTER_AMOUNT, JITTER_AMOUNT)
		hovered_button.rotation_degrees = jitter_angle

func _on_button_mouse_entered(button: Button):
	hovered_button = button

func _on_button_mouse_exited(button: Button):
	button.rotation_degrees = 0
	if hovered_button == button:
		hovered_button = null
# --- JITTER CODE END ---


# --- Your original functions ---

# This function runs when the slider value changes
func _on_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(0, value)

# This function runs when the "Back" button is pressed
func _on_back_pressed():
	main_buttons_panel.show()
	hide() # This hides the SettingsPanel this script is on
	get_tree().call_group("TitleLetters", "show")


func _on_resolution_item_selected(index: int) -> void:
	
	# Force the window into windowed mode first.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

	# Match the index of the item selected
	match index:
		0: # 1920x1080
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		1: # 1600x900
			DisplayServer.window_set_size(Vector2i(1600, 900))
		2: # 1280x720
			DisplayServer.window_set_size(Vector2i(1280, 720))

	# --- PASTE THE CODE HERE ---
	# Get the size of the monitor and the new window size
	var screen_size = DisplayServer.screen_get_size()
	var window_size = DisplayServer.window_get_size()
	
	# Calculate the center and set the position
	DisplayServer.window_set_position((screen_size - window_size) / 2)
