extends CanvasLayer

@onready var speaker_label: RichTextLabel = $speaker
@onready var text_label: RichTextLabel = $text
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# References to the sub-nodes
@onready var lola_talking: Node = $lola_talking  # Assuming these are direct children
@onready var paulette_offered: Node = $paulette_offered
@onready var lola_laugh: Node = $lola_laugh

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide everything at start
	speaker_label.text = ""
	text_label.text = ""
	
	# Hide all sub-nodes initially
	if lola_talking:
		lola_talking.hide()
	if paulette_offered:
		paulette_offered.hide()
	if lola_laugh:
		lola_laugh.hide()
	
	# Start the dialogue sequence
	start_dialogue_sequence()

func start_dialogue_sequence() -> void:
	# First dialogue starts immediately (at 0 seconds)
	show_dialogue("Demon", "Araw na ng mga kaluluwa. Ano ang iyong ihahandog?﻿")
	
	# Wait 10 seconds total from start
	await get_tree().create_timer(10.0).timeout
	
	# Show lola_talking at 8 seconds
	if lola_talking:
		await get_tree().create_timer(8.0).timeout
		lola_talking.show()
	
	show_dialogue("Lola Olet", "Ang aking sarili—ang aking katawan, sa madaling salita, ang aking apo.")
	
	# Wait 18 seconds total from start (8 more seconds)
	await get_tree().create_timer(8.0).timeout
	show_dialogue("Lola Olet", "Tapos na ang aking oras; ngayon, siya naman. Gusto ko nang maging bata muli.")
	
	# Wait 27 seconds total from start (9 more seconds)
	await get_tree().create_timer(9.0).timeout
	
	# Show paulette_offered at 28 seconds (1 second after 27)
	if paulette_offered:
		await get_tree().create_timer(1.0).timeout
		paulette_offered.show()
	
	show_dialogue("Paulette", "Kaya pala parang nabibiyak ang isipan ko... nangyari na ito dati, at mangyayari pa ulit.")
	
	# Wait 36 seconds total from start (9 more seconds)
	await get_tree().create_timer(9.0).timeout
	
	# Hide lola_talking at 30 seconds (should have already happened at 28)
	if lola_talking:
		lola_talking.hide()
	
	show_dialogue("Paulette", "Lahat ng gabing lumalabas ka, paghahanda pala 'yon para muli mong ipagpalit ang buhay mo sa akin.")
	
	# Wait 44 seconds total from start (8 more seconds)
	await get_tree().create_timer(8.0).timeout
	
	# Show lola_laugh at 44 seconds
	if lola_laugh:
		lola_laugh.show()
	
	# Wait 45 seconds total from start (1 more second)
	await get_tree().create_timer(1.0).timeout
	show_dialogue("Lola Olet", "Tama............... Ikaw at ako, apo, ay iisa lamang...... Ang siklo na ito'y magpapatuloy—hanggang sa susunod.")
	
	# Wait 52 seconds total from start (7 more seconds)
	await get_tree().create_timer(1.0).timeout
	show_dialogue("Demon", "(laughs)")
	
	# Wait until the end (around 60 seconds total)
	await get_tree().create_timer(14.0).timeout
	
	# Hide everything when done
	hide_all()

func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	text_label.visible_ratio = 0  # Reset typewriter effect
	
	# Play typewriter animation if it exists
	if animation_player.has_animation("typewriter"):
		animation_player.play("typewriter")
	else:
		# Fallback: manually show text if animation doesn't exist
		text_label.visible_ratio = 1

func hide_all() -> void:
	# Hide the main dialogue
	speaker_label.text = ""
	text_label.text = ""
	
	# Hide all sub-nodes
	if lola_talking:
		lola_talking.hide()
	if paulette_offered:
		paulette_offered.hide()
	if lola_laugh:
		lola_laugh.hide()
