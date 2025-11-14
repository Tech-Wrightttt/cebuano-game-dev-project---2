extends VBoxContainer

const BUSSCENE = preload("res://game/cutscenes/game_intro.tscn")

# Get a reference to the other panel using a relative path
@onready var settings_panel = $"../SettingsPanel"
@onready var controls_panel = $"../ControlsPanel"

# --- SPECTRAL PARTICLE CODE START ---
var spectral_particles: GPUParticles2D
var spectral_timer: Timer
# --- SPECTRAL PARTICLE CODE END ---

# --- JITTER CODE START ---
const JITTER_AMOUNT = 1
@onready var start_game_button: Button = $"Start Game"
@onready var settings_button: Button = $"Settings"
@onready var controls_button: Button = $"Controls"
@onready var quit_button: Button = $"Quit"
var hovered_button: Button = null
# --- JITTER CODE END ---


func _ready():
	# --- JITTER CODE START ---
	Global.reset_game_state()
	var buttons = [start_game_button, settings_button, controls_button, quit_button]
	
	for button in buttons:
		if button:
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			button.mouse_exited.connect(_on_button_mouse_exited.bind(button))
	# --- JITTER CODE END ---
	
	# --- SPECTRAL PARTICLE CODE START ---
	_setup_spectral_particles()
	# --- SPECTRAL PARTICLE CODE END ---


# --- SPECTRAL PARTICLE CODE START ---
func _setup_spectral_particles():
	# Create the particle system programmatically
	spectral_particles = _create_spectral_particles()
	
	# Create timer for random spectral flashes
	spectral_timer = Timer.new()
	add_child(spectral_timer)
	spectral_timer.timeout.connect(_trigger_spectral_flash)
	spectral_timer.wait_time = randf_range(3.0, 8.0) # Random interval between 3-8 seconds
	spectral_timer.start()

func _create_spectral_particles() -> GPUParticles2D:
	var particles = GPUParticles2D.new()
	particles.name = "SpectralParticles"
	
	# Add to canvas layer to ensure they're on top of everything
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 100 # High number to render above menu
	get_tree().root.add_child(canvas_layer)
	canvas_layer.add_child(particles)
	
	# Basic particle settings
	particles.amount = 3
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.one_shot = true
	particles.emitting = false # Start not emitting
	
	# Process material - particles don't move
	var process_material = ParticleProcessMaterial.new()
	process_material.direction = Vector3(0, 0, 0)
	process_material.spread = 0
	process_material.initial_velocity_min = 0
	process_material.initial_velocity_max = 0
	process_material.gravity = Vector3(0, 0, 0)
	particles.process_material = process_material
	
	# Particles material - use ADD blend mode for ghostly effect
	var particles_material = CanvasItemMaterial.new()
	particles_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	particles.material = particles_material
	
	# Note: You'll need to set the texture programmatically or create one
	# For now, we'll use a default white texture that Godot can use
	# You can replace this with your own spectral texture later
	
	return particles

func _trigger_spectral_flash():
	if spectral_particles:
		# Randomize position for next flash (avoid covering buttons)
		var viewport_size = get_viewport().get_visible_rect().size
		spectral_particles.position = Vector2(
			randf_range(100, viewport_size.x - 100), # Keep away from edges
			randf_range(100, viewport_size.y - 100)
		)
		
		# Optional: Randomize scale for variety
		spectral_particles.scale = Vector2.ONE * randf_range(0.8, 1.2)
		
		# Trigger a brief emission
		spectral_particles.restart()
		spectral_particles.emitting = true
		
		# Optional: Add a subtle sound effect here later
		# $SpectralSound.play()
	
	# Reset timer with new random interval
	spectral_timer.wait_time = randf_range(4.0, 12.0) # 4-12 second intervals
	spectral_timer.start()
# --- SPECTRAL PARTICLE CODE END ---

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
func _on_start_game_pressed() -> void:
	get_tree().change_scene_to_packed(BUSSCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed():
	settings_panel.show()
	hide()
	get_tree().call_group("TitleLetters", "hide")
	
func _on_controls_pressed():
	controls_panel.show()
	hide()
	get_tree().call_group("TitleLetters", "hide")
