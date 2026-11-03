class_name ConceptModel3D
extends RefCounted
## Loads an image-to-3D model (assets/models/ready/<id>/<id>_reduced.glb) and
## colours it with its concept image (assets/concepts/horror/<id>.png) through
## concept_projection.gdshader, scaled to `height` metres and standing on y = 0.

const SHADER := preload("res://scenes/world3d/concept_projection.gdshader")
const CONCEPTS := "res://assets/concepts/horror/"
const GEOMETRY := preload("res://assets/models/ready/horror_models.gd").DATA


static func geometry(id: String) -> Dictionary:
	return GEOMETRY.get(id, {})


## Uniformly fit an inferred prop inside its allotted space; gameplay colliders stay separate.
static func fit(parent: Node3D, id: String, at: Vector3, size: Vector3, yaw: float = 0.0) -> Node3D:
	var spec := geometry(id)
	var dims: Array = spec["size"]
	var factor := minf(size.x / dims[0], minf(size.y / dims[1], size.z / dims[2]))
	return spawn(parent, id, at, dims[1] * factor, yaw)


## Architectural shells must match the existing collision footprint / doorway layout.
static func sized(parent: Node3D, id: String, at: Vector3, size: Vector3, yaw: float = 0.0) -> Node3D:
	var dims: Array = geometry(id)["size"]
	var root := spawn(parent, id, at, size.y, yaw)
	root.scale = Vector3(size.x * dims[1] / (size.y * dims[0]), 1.0, size.z * dims[1] / (size.y * dims[2]))
	return root


## Align the principal length axis (fish / rod) without changing the source mesh or material mapping.
static func aligned(parent: Node3D, id: String, length: float, direction: Vector3, from_end: bool = false) -> Node3D:
	var root := spawn(parent, id, Vector3.ZERO, 1.0)
	var model := root.get_child(0) as Node3D
	var spec := geometry(id)
	var a: Array = spec["axis"]
	var axis := Vector3(a[0], a[1], a[2])
	var rotation := Basis(Quaternion(axis, direction.normalized()))
	var scale_factor := length / float(spec["length"])
	model.basis = rotation.scaled(Vector3.ONE * scale_factor)
	var origin := Vector3.ZERO
	if from_end:
		var p: Array = spec["anchor"]
		origin = Vector3(p[0], p[1], p[2])
	else:
		var box := (model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_aabb()
		origin = box.get_center()
	model.position = -(model.basis * origin)
	return root


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
	var spec := geometry(id)
	if spec.has("fallback"):
		var c: Array = spec["fallback"]
		material.set_shader_parameter("fallback_color", Color(c[0], c[1], c[2]))
		var dims: Array = spec["size"]
		if dims[2] > dims[0] * 1.25:
			material.set_shader_parameter("projection_u", Vector3(0, 0, 1))
		elif dims[1] < minf(dims[0], dims[2]) * 0.5:
			material.set_shader_parameter("projection_v", Vector3(0, 0, 1))
	if id in ["rin_house", "neighbour_house_a", "neighbour_house_b", "wooden_wardrobe"]:
		var wall := "blue_lime_wall" if id == "neighbour_house_a" else "wall_plaster_old"
		wall = "brick_wall_old" if id == "neighbour_house_b" else wall
		var roof := "roof_tin_rusty"
		if id == "wooden_wardrobe":
			wall = "floor_wood_planks"
			roof = wall
		material.set_shader_parameter("surface_textures", true)
		material.set_shader_parameter("wall_texture", load("res://assets/textures/horror/%s.png" % wall))
		material.set_shader_parameter("roof_texture", load("res://assets/textures/horror/%s.png" % roof))
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
	var spec := geometry(id)
	if spec.has("crop"):
		var c: Array = spec["crop"]
		return Vector4(c[0], c[1], c[2], c[3])
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
