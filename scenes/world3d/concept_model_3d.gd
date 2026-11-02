class_name ConceptModel3D
extends RefCounted
## Loads an image-to-3D model (assets/models/ready/<id>/<id>_reduced.glb) and
## colours it with its concept image (assets/concepts/horror/<id>.png) through
## concept_projection.gdshader, scaled to `height` metres and standing on y = 0.

const SHADER := preload("res://scenes/world3d/concept_projection.gdshader")
const CONCEPTS := "res://assets/concepts/horror/"


static func spawn(parent: Node3D, id: String, at: Vector3, height: float, yaw: float = 0.0) -> Node3D:
	var scene := load("res://assets/models/ready/%s/%s_reduced.glb" % [id, id]) as PackedScene
	var root := Node3D.new()
	root.name = "Model_" + id
	parent.add_child(root)
	if scene == null:
		return root
	var model := scene.instantiate() as Node3D
	root.add_child(model)
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	var bounds := AABB()
	for i in meshes.size():
		var box := (meshes[i] as MeshInstance3D).get_aabb()
		bounds = box if i == 0 else bounds.merge(box)
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("concept", load(CONCEPTS + id + ".png"))
	material.set_shader_parameter("bounds_min", bounds.position)
	material.set_shader_parameter("bounds_size", bounds.size)
	material.set_shader_parameter("crop", _crop(id))
	for mesh in meshes:
		(mesh as MeshInstance3D).material_override = material
		(mesh as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var s := height / maxf(bounds.size.y, 0.001)
	model.scale = Vector3.ONE * s
	model.position = Vector3(-bounds.get_center().x * s, -bounds.position.y * s, -bounds.get_center().z * s)
	root.position = at
	root.rotation.y = yaw
	return root


## Where the object sits in its 1024x1024 concept (measured on the art).
static func _crop(id: String) -> Vector4:
	match id:
		"offering_tray_normal", "offering_tray_eaten":
			return Vector4(0.05, 0.12, 0.9, 0.78)
		"joss_paper_bucket":
			return Vector4(0.1, 0.1, 0.8, 0.82)
		"hoa_dang_lantern":
			return Vector4(0.05, 0.22, 0.9, 0.55)
		"pier_lamp_post":
			return Vector4(0.3, 0.03, 0.4, 0.94)
		"drowned_figure":
			return Vector4(0.32, 0.03, 0.36, 0.94)
		"drowned_hand":
			return Vector4(0.25, 0.03, 0.5, 0.94)
		"bottle_letter":
			return Vector4(0.3, 0.03, 0.4, 0.94)
	return Vector4(0, 0, 1, 1)
