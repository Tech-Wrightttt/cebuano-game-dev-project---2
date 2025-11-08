extends Node3D

@onready var second_dialogue = get_tree().current_scene.get_node("second_dialogue/canvas")
@onready var speaker_name: RichTextLabel = get_tree().current_scene.get_node("second_dialogue/canvas/speaker_name")
@onready var dialogue: RichTextLabel = get_tree().current_scene.get_node("second_dialogue/canvas/dialogue")
@onready var text_animation: AnimationPlayer = get_tree().current_scene.get_node("second_dialogue/canvas/text_animation")
@onready var player: CharacterBody3D = get_tree().current_scene.get_node("Player")

@export var dialogues: Array[String]
@export var speaker_names: Array[String]
@export var speaker: Node3D

var current_dialogue = -1
var started = false

func _ready() -> void:
	# Make sure dialogue is hidden at start
	second_dialogue.visible = false
	
	# Connect continue button
	var continue_button = second_dialogue.get_node("continue")
	continue_button.pressed.connect(continue_dialogue)

func start_dialogue(body):
	# Add player.dialogue_active check to prevent overlapping dialogues
	if body == player and !started and !player.dialogue_active:
		started = true
		player.dialogue_active = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		player.SPEED = 0.0
		player.MOUSE_SENS = 0.0
		second_dialogue.visible = true
		
		continue_dialogue()

func end_dialogue():
	player.dialogue_active = false
	player.SPEED = 4.5
	player.MOUSE_SENS = 0.0005
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	second_dialogue.visible = false
	
	# Reset ALL dialogue state variables
	started = false
	current_dialogue = -1  # Reset so next trigger starts from beginning
	
	# Stop any ongoing animation
	if text_animation.is_playing():
		text_animation.stop()

func continue_dialogue():
	current_dialogue += 1
	if current_dialogue < dialogues.size():
		dialogue.text = dialogues[current_dialogue]
		speaker_name.text = speaker_names[current_dialogue]
		
		# Handle speaker animation
		if speaker:
			if "You" not in speaker_name.text:
				speaker.get_node("AnimationPlayer").play("talk")
			else:
				speaker.get_node("AnimationPlayer").play("RESET")
		
		# Play text animation
		text_animation.play("RESET")
		text_animation.play("typewriter")
		second_dialogue.get_node("continue").disabled = false
	else:
		end_dialogue()
