extends CanvasLayer

<<<<<<< Updated upstream
@onready var fade_rect: ColorRect = get_node("ColorRect")
@onready var loading_label: Label = get_node("ColorRect/VBoxContainer/Label")
@onready var progress_bar: ProgressBar = get_node("ColorRect/VBoxContainer/ProgressBar")
=======
@onready var fade_rect: ColorRect = $ColorRect2/ColorRect
@onready var loading_label: Label = $ColorRect2/ColorRect/VBoxContainer/Label
@onready var progress_bar: ProgressBar = $ColorRect2/ColorRect/VBoxContainer/ProgressBar
>>>>>>> Stashed changes

var next_scene_path: String
var loading: bool = false
var dot_timer: float = 0.0
var dot_count: int = 0

func _ready() -> void:
	# Verify nodes exist before using them
	if not _validate_nodes():
		return
	
	# Start fully transparent
	fade_rect.modulate.a = 0.0
	loading_label.text = "Loading"
	progress_bar.value = 0
	loading_label.visible = false
	progress_bar.visible = false
	
	# Make sure this layer is on top
	layer = 100

func _validate_nodes() -> bool:
	if not fade_rect:
		push_error("❌ Fade_rect (ColorRect) node not found!")
		return false
	if not loading_label:
		push_error("❌ Loading_label node not found!")
		return false
	if not progress_bar:
		push_error("❌ Progress_bar node not found!")
		return false
	print("✅ All loading screen nodes validated")
	return true

func start_loading(scene_path: String) -> void:
	if not fade_rect:
		push_error("❌ Cannot start loading - fade_rect is null")
		return
	
	print("🔄 Starting loading screen for: ", scene_path)
	next_scene_path = scene_path
	visible = true  # Make sure the loading screen is visible
	_start_fade_in()

func _start_fade_in() -> void:
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 0.8)
	await tween.finished
	
	# Show loading UI
	loading_label.visible = true
	progress_bar.visible = true
	loading = true
	
	# Start loading the scene
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
	var error = ResourceLoader.load_threaded_request(next_scene_path)
	if error != OK:
		push_error("Failed to start loading scene: " + next_scene_path)
		loading = false
		return
	
	_monitor_loading()

func _monitor_loading() -> void:
	await get_tree().process_frame
	
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if progress.size() > 0:
			progress_bar.value = clamp(progress[0] * 100.0, 0, 100)
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(next_scene_path, progress)
	
	# Loading finished
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		progress_bar.value = 100
		var scene: PackedScene = ResourceLoader.load_threaded_get(next_scene_path)
		if scene:
			print("✅ Scene loaded successfully, changing scene...")
			get_tree().change_scene_to_packed(scene)
			# Wait a frame before fading out
			await get_tree().process_frame
			_fade_out()
		else:
			push_error("Failed to get loaded scene")
			loading = false
	else:
		push_error("Failed to load scene: " + next_scene_path)
		loading = false

func _fade_out() -> void:
	loading = false
	loading_label.visible = false
	progress_bar.visible = false
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await tween.finished
	
	# Don't queue_free if this is an autoload singleton
	visible = false
	print("✅ Loading screen hidden")
