extends CanvasLayer



@onready var night_label = $night

func _process(_delta):
	night_label.text = "Night: %d" % Global.current_night
