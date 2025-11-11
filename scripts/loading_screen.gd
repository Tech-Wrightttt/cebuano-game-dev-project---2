extends CanvasLayer

@onready var fade_rect: ColorRect = $ColorRect
@onready var loading_label: Label = $VBoxContainer/Label
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

var next_scene_path: String
var loading: bool = false
var dot_timer: float = 0.0
var dot_count: int = 0

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	loading_label.text = "Loading"
	progress_bar.value = 0
	loading_label.visible = false
	progress_bar.visible = false

func start_loading(scene_path: String) -> void:
	next_scene_path = scene_path
	_start_fade_in()

func _start_fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	await tween.finished
	loading_label.visible = true
	progress_bar.visible = true
	loading = true
	_load_scene_threaded()

func _process(delta: float) -> void:
	if loading:
		# Animate "Loading..."
		dot_timer += delta
		if dot_timer >= 0.4:
			dot_timer = 0.0
			dot_count = (dot_count + 1) % 4
			loading_label.text = "Loading" + ".".repeat(dot_count)

func _load_scene_threaded() -> void:
	ResourceLoader.load_threaded_request(next_scene_path)
	_monitor_loading()

func _monitor_loading() -> void:
	await get_tree().process_frame

	while ResourceLoader.load_threaded_get_status(next_scene_path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		var progress := ResourceLoader.load_threaded_get_status(next_scene_path, [])
		if progress_bar:
			progress_bar.value = clamp(progress[1] * 100.0, 0, 100)
		await get_tree().process_frame

	var status := ResourceLoader.load_threaded_get_status(next_scene_path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var scene: PackedScene = ResourceLoader.load_threaded_get(next_scene_path)
		if scene:
			get_tree().change_scene_to_packed(scene)

	# Fade out and remove loader
	loading = false
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()
