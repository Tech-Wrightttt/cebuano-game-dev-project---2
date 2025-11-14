extends CanvasLayer

@onready var speaker_label: RichTextLabel = $speaker
@onready var text_label: RichTextLabel = $text
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Hide everything at start
	speaker_label.text = ""
	text_label.text = ""
	
	# Start the dialogue sequence
	start_dialogue_sequence()

func start_dialogue_sequence() -> void:
	# First dialogue immediately
	show_dialogue("", "I can hear voices, but I don't understand.")
	await get_tree().create_timer(7.0).timeout
	
	# Phone ring flashes briefly
	show_dialogue("", "*telephone rings*")
	await get_tree().create_timer(2.0).timeout
	hide_all()
	await get_tree().create_timer(1.0).timeout
	
	show_dialogue("Paulette (You)", "*picks up* Lola? Asa ka la? Nganong murag duha kabuok gatabi sa telepono?")
	await get_tree().create_timer(7.0).timeout
	
	show_dialogue("Lola Olet", "Dugay na na sila naminaw. Di na sila mo usab, pero basin kaya nimo sila hatagan ug kalinaw.")
	await get_tree().create_timer(7.0).timeout
	
	show_dialogue("Lola Olet", "Paulette, kahibalo ba ka kung ngano naa ka diri?")
	await get_tree().create_timer(7.0).timeout
	
	show_dialogue("Paulette (You)", "Para bantayan ang balay mintras wala ka.")
	await get_tree().create_timer(8.0).timeout
	
	show_dialogue("Lola Olet", "…O basin para pulihan ko...")
	await get_tree().create_timer(8.0).timeout
	
	# Final pause before hiding everything
	await get_tree().create_timer(2.0).timeout
	hide_all()


func show_dialogue(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	text_label.text = text
	text_label.visible_ratio = 0  # Reset typewriter effect
	
	# Play typewriter animation if it exists
	if animation_player and animation_player.has_animation("typewriter"):
		animation_player.play("typewriter")
	else:
		# Fallback: manually show text if animation doesn't exist
		text_label.visible_ratio = 1

func hide_all() -> void:
	# Hide the main dialogue
	speaker_label.text = ""
	text_label.text = ""
