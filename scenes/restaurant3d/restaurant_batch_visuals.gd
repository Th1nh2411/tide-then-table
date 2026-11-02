class_name RestaurantBatchVisuals
extends Node3D
## Canonical Hunyuan batch meshes; interaction/collision stays with the host.

static func add(parent: Node3D, id: String, at: Vector3) -> Node3D:
	var scene := load("res://assets/models/ready/%s/%s.glb" % [id, id]) as PackedScene
	var visual := scene.instantiate() as Node3D
	visual.name = "Batch_" + id
	parent.add_child(visual)
	visual.position = at
	WorldPresentation3D.cast_shadows(visual)
	return visual

static func tint(root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for mesh: Node in root.find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).material_override = mat
