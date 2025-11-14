extends CanvasLayer

func _ready():
	# Hide everything at start
	hide_subtitle()
	
	# Show subtitle after 10.5 seconds
	await get_tree().create_timer(10.5).timeout
	show_subtitle("What? what happened last night and why’d lola just gave me chores and leave today too??", 5.0)

func show_subtitle(text: String, duration: float = 3.0):
	$ColorRect/RichTextLabel.text = text
	$ColorRect.visible = true
	$ColorRect/RichTextLabel.visible = true
	
	# If you have text animation, trigger it here
	$ColorRect/RichTextLabel/AnimationPlayer.play("text")
	
	await get_tree().create_timer(duration).timeout
	hide_subtitle()

func hide_subtitle():
	$ColorRect.visible = false
	$ColorRect/RichTextLabel.visible = false

# Optional: Public function to show subtitle from other scripts
func show_custom_subtitle(text: String, duration: float = 3.0):
	show_subtitle(text, duration)
