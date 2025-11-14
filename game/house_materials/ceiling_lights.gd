extends Node3D

@export var count := 48
@export var columns := 8
@export var light_energy := 6.0
@export var light_range := 8.0
@export var light_angle_deg := 45.0
@export var cast_shadows := false
@export var test_point := Vector3(0, 0, 0) # world point to test (e.g., center of the plane)

var lights: Array = []

func _ready() -> void:
	_spawn_plane()
	_spawn_lights()
	# wait one frame so everything has valid global transforms
	await get_tree().process_frame
	_run_affectivity_test()

func _spawn_plane() -> void:
	var plane := MeshInstance3D.new()
	plane.mesh = PlaneMesh.new()
	plane.scale = Vector3.ONE * 8.0

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.7)
	plane.set_surface_override_material(0, mat)

	add_child(plane)

func _spawn_lights() -> void:
	for i in count:
		var l := SpotLight3D.new()
		l.light_energy = light_energy
		l.spot_range = light_range
		l.spot_angle = light_angle_deg
		l.shadow_enabled = cast_shadows
		l.visible = true
		l.light_cull_mask = 1 # ensure object receives light_cull_mask = 1

		var x := (i % columns) - (columns / 2)
		var z := int(i / columns) * 1.8
		var pos := Vector3(x * 1.8, 3.0, z)

		l.transform.origin = pos
		l.look_at(Vector3(pos.x, 0.0, pos.z), Vector3.UP)

		add_child(l)
		lights.append(l)

func _run_affectivity_test() -> void:
	print("Testing how many lights SHOULD affect point ", test_point)

	var should_affect := []
	for i in lights.size():
		var l := lights[i]
		if _light_should_affect_point(l, test_point):
			should_affect.append(i)

	print("Lights that mathematically reach the point (indices): ", should_affect)
	print("Count that should affect: ", should_affect.size())

func _light_should_affect_point(l: SpotLight3D, point: Vector3) -> bool:
	if not l.visible or l.light_energy <= 0.0:
		return false

	var light_pos := l.global_transform.origin
	var to_point := point - light_pos
	var dist := to_point.length()

	if dist > l.spot_range:
		return false

	# Spot direction: -Z is local forward for lights
	var dir := -l.global_transform.basis.z
	var to_point_dir := to_point.normalized()

	var cos_angle := dir.dot(to_point_dir)
	var half_angle_rad := deg_to_rad(l.spot_angle * 0.5)

	if cos_angle < cos(half_angle_rad):
		return false

	return true
