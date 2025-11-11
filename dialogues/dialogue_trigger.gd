extends Node3D


@onready var first_dialogue = get_tree().current_scene.get_node("first_dialogue/canvas")
@onready var speaker_name: RichTextLabel = get_tree().current_scene.get_node("first_dialogue/canvas/speaker_name")
@onready var dialogue: RichTextLabel = get_tree().current_scene.get_node("first_dialogue/canvas/dialogue")
@onready var text_animation: AnimationPlayer = get_tree().current_scene.get_node("first_dialogue/canvas/text_animation")
@onready var player: CharacterBody3D = get_tree().current_scene.get_node("Player")

@export var dialogues: Array[String]
@export var speaker_names: Array[String]
@export var speaker: Node3D

signal dialogue_finished(dialogue_name)

var current_dialogue = -1
var started = false

func _ready() -> void:
	# Make sure dialogue is hidden at start
	first_dialogue.visible = false
	
	# Connect continue button
	var continue_button = first_dialogue.get_node("continue")
	continue_button.pressed.connect(continue_dialogue)

func start_dialogue(body):
	# Add player.dialogue_active check to prevent overlapping dialogues
	if body == player and !started and !player.dialogue_active:
		started = true
		player.dialogue_active = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.SPEED = 0.0
		player.MOUSE_SENS = 0.0
		first_dialogue.visible = true
		
		# Hide player UI and crosshair
		hide_player_ui()
		
		continue_dialogue()

func end_dialogue():
	player.dialogue_active = false
	player.SPEED = 4.5
	player.MOUSE_SENS = 0.0005
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	first_dialogue.visible = false
	
	# Show player UI and crosshair again
	show_player_ui()
	
	# Reset ALL dialogue state variables
	started = false
	current_dialogue = -1  # Reset so next trigger starts from beginning
	
	# Stop any ongoing animation
	if text_animation.is_playing():
		text_animation.stop()
		
	print("FIRST GRANDMA CONVO ENDED!")	
	emit_signal("dialogue_finished", "dialogue_trigger1")
	
func continue_dialogue():
	current_dialogue += 1
	if current_dialogue < dialogues.size():
		dialogue.text = dialogues[current_dialogue]
		speaker_name.text = speaker_names[current_dialogue]
		
		
		# Play text animation
		text_animation.play("RESET")
		text_animation.play("typewriter")
		first_dialogue.get_node("continue").disabled = false
	else:
		end_dialogue()

func hide_player_ui():
	# Hide crosshair
	if player.has_node("PlayerScreenUI/crosshair"):
		var crosshair = player.get_node("PlayerScreenUI/crosshair")
		crosshair.visible = false
	
	if player.has_node("PlayerScreenUI/TaskToDoLabel"):
		var TaskToDoLabel = player.get_node("PlayerScreenUI/TaskToDoLabel")
		TaskToDoLabel.visible = false
		
	# Hide other UI elements
	if player.has_node("CanvasLayer2/SanityBar"):
		var sanity_bar = player.get_node("CanvasLayer2/SanityBar")
		sanity_bar.visible = false
	
	if player.has_node("CanvasLayer2/SprintBar"):
		var sprint_bar = player.get_node("CanvasLayer2/SprintBar")
		sprint_bar.visible = false
	
	# Hide eye UI elements
	if player.has_node("PlayerScreenUI/Open eyes"):
		var open_eyes = player.get_node("PlayerScreenUI/Open eyes")
		open_eyes.visible = false
	
	if player.has_node("PlayerScreenUI/Close eyes"):
		var close_eyes = player.get_node("PlayerScreenUI/Close eyes")
		close_eyes.visible = false

func show_player_ui():
	# Show crosshair
	if player.has_node("PlayerScreenUI/crosshair"):
		var crosshair = player.get_node("PlayerScreenUI/crosshair")
		crosshair.visible = true
	
	# Show other UI elements
	if player.has_node("CanvasLayer2/SanityBar"):
		var sanity_bar = player.get_node("CanvasLayer2/SanityBar")
		sanity_bar.visible = true
	
	if player.has_node("CanvasLayer2/SprintBar"):
		var sprint_bar = player.get_node("CanvasLayer2/SprintBar")
		sprint_bar.visible = true
		
	if player.has_node("PlayerScreenUI/TaskToDoLabel"):
		var TaskToDoLabel = player.get_node("PlayerScreenUI/TaskToDoLabel")
		TaskToDoLabel.visible = true
	
	# Show eye UI elements based on third_eye_active state
	if player.has_node("PlayerScreenUI/Open eyes"):
		var open_eyes = player.get_node("PlayerScreenUI/Open eyes")
		open_eyes.visible = player.third_eye_active
	
	if player.has_node("PlayerScreenUI/Close eyes"):
		var close_eyes = player.get_node("PlayerScreenUI/Close eyes")
		close_eyes.visible = !player.third_eye_active
