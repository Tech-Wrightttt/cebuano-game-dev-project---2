extends Node3D
# Attach this script to any 3D node that uses stencil for x-ray effect
# It automatically expands the AABB for ALL mesh instances to prevent culling

@export var aabb_size: float = 100.0  # Adjustable in the inspector

func _ready() -> void:
	expand_all_aabbs()

func expand_all_aabbs() -> void:
	# Get ALL MeshInstance3D children (recursive)
	var mesh_instances = find_all_mesh_instances(self)
	
	if mesh_instances.is_empty():
		push_warning("⚠️ No MeshInstance3D found for x-ray culling fix on: ", name)
		return
	
	var half_size = aabb_size / 2.0
	var new_aabb = AABB(
		Vector3(-half_size, -half_size, -half_size),
		Vector3(aabb_size, aabb_size, aabb_size)
	)
	
	for mesh_instance in mesh_instances:
		mesh_instance.custom_aabb = new_aabb
		print("✅ X-ray AABB expanded for: ", mesh_instance.name)
	
	print("✅ Total meshes fixed for ", name, ": ", mesh_instances.size())

# Helper function to find ALL MeshInstance3D recursively
func find_all_mesh_instances(node: Node3D) -> Array:
	var result: Array = []
	
	if node is MeshInstance3D:
		result.append(node)
	
	for child in node.get_children():
		if child is Node3D:
			result.append_array(find_all_mesh_instances(child))
	
	return result
