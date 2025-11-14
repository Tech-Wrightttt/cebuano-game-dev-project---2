extends MeshInstance3D
# Advanced version - forces stencil re-rendering and prevents culling

@onready var camera: Camera3D = get_tree().get_first_node_in_group("player").get_node("Head/Camera3D")
var stencil_objects: Array = []

func _ready() -> void:
	extra_cull_margin = 100000.0
	visible = true
	print("✅ PostProcessEffect2 initialized with large cull margin")
	
	# Find all objects with stencil materials (the ones being x-rayed)
	find_stencil_objects(get_tree().root)

func _process(_delta: float) -> void:
	if camera:
		global_position = camera.global_position
		#visible = true
		
		# Force stencil objects to stay visible and not culled
		for obj in stencil_objects:
			if is_instance_valid(obj):
				obj.visible = true

func find_stencil_objects(node: Node) -> void:
	if node is MeshInstance3D:
		if node.material_override:
			var mat = node.material_override
			if mat is StandardMaterial3D and mat.stencil_mode != 0:
				stencil_objects.append(node)
	
	for child in node.get_children():
		find_stencil_objects(child)
