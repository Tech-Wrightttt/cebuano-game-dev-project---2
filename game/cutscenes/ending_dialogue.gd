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
	show_dialogue("Demon", "Adlaw na sa mga patay. Unsa ang imong ihalad?﻿")
	
	# Wait 10 seconds total from start
	await get_tree().create_timer(10.0).timeout
	
	# Show lola_talking at 8 seconds
	if lola_talking:
		await get_tree().create_timer(8.0).timeout
		lola_talking.show()
	
	show_dialogue("Lola Olet", "Ang akong kaugalingon— ang akong lawas. Ang akong apo.")
	
	# Wait 18 seconds total from start (8 more seconds)
	await get_tree().create_timer(8.0).timeout
	show_dialogue("Lola Olet", "Gusto na nako mahimong batan-on balik. Mana akong oras— karon, siya napud.")
	
	# Wait 27 seconds total from start (9 more seconds)
	await get_tree().create_timer(9.0).timeout
	
	# Show paulette_offered at 28 seconds (1 second after 27)
	if paulette_offered:
		await get_tree().create_timer(1.0).timeout
		paulette_offered.show()
	
	show_dialogue("Paulette", "So this is why I feel like I'm living two lives... Nahitabo na ni sauna, ug mahitabo pani usab.")
	
	# Wait 36 seconds total from start (9 more seconds)
	await get_tree().create_timer(9.0).timeout
	
	# Hide lola_talking at 30 seconds (should have already happened at 28)
	if lola_talking:
		lola_talking.hide()
	
	show_dialogue("Paulette", "Tanang gabii nga ni gawas ka, para diay to maka andam ani— para maka makig ilis kag kinabuhi nako lola?")
	
	# Wait 44 seconds total from start (8 more seconds)
	await get_tree().create_timer(8.0).timeout
	
	# Show lola_laugh at 44 seconds
	if lola_laugh:
		lola_laugh.show()
	
	# Wait 45 seconds total from start (1 more second)
	await get_tree().create_timer(1.0).timeout
	show_dialogue("Lola Olet", "Sakto ka apo......... Ikaw og ako, usa ra ta ka tawo. Magbalik balik ra ni na siklo hantod sa hantod...")
	
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
