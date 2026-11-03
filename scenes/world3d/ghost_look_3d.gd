class_name GhostLook3D
extends RefCounted
## The dead's shared look (PLAN §10 "Đồng bộ style"): pale grey-blue-green
## skin, wet dark clothes, dithered see-through edges, a slow water wobble,
## drops falling off the body; no glow (ghost_look.gdshader, numbers in
## StyleGuide "Ghost"). `apply(rig)` on a PersonRig3D / PsxCharacterVisual
## (ông Tư, drowned_m / drowned_f) or a ConceptModel3D figure. The node is
## marked "style_skip" so StylePass3D leaves it alone.

const SHADER := preload("res://scenes/world3d/ghost_look.gdshader")
const DRIPS := "GhostDrips"
## Concept figures keep their shader: a cold pale tint instead.
const CONCEPT_TINT := Color(0.62, 0.74, 0.74)

static var _shared: Dictionary = {}  # body texture id -> ShaderMaterial


## Puts the dead look on every mesh under `root`. `unique`: a material of its
## own (to fade this one ghost with `set_opacity`). Returns the body material
## (null if `root` only had concept-model meshes).
static func apply(root: Node3D, unique: bool = false, opacity: float = 1.0) -> ShaderMaterial:
	root.set_meta(StylePass3D.SKIP, true)
	var body: ShaderMaterial = null
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh.name.begins_with("GhostDrop"):
			continue
		var concept := mesh.material_override as ShaderMaterial
		if concept and concept.shader and concept.shader.resource_path == StylePass3D.CONCEPT_SHADER:
			mesh.material_override = _concept(concept)
			continue
		if body == null:
			body = material(_texture(mesh), unique, _vertex_colour(mesh))
		mesh.material_override = body
	if body and unique:
		set_opacity(body, opacity)
	_drips(root)
	return body


## A ghost body material for `texture` (shared unless `unique`).
static func material(texture: Texture2D, unique: bool = false, vertex_colour: bool = false) -> ShaderMaterial:
	var key := texture.get_instance_id() if texture else 0
	if not unique and _shared.has(key):
		return _shared[key]
	var g := StylePass3D.get_guide()
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter("use_tex", texture != null)
	if texture:
		m.set_shader_parameter("body_tex", texture)
	m.set_shader_parameter("use_vertex_color", vertex_colour)
	m.set_shader_parameter("skin", g.ghost_skin)
	m.set_shader_parameter("cloth", g.ghost_cloth)
	m.set_shader_parameter("skin_from", g.ghost_skin_from)
	m.set_shader_parameter("edge_fade", g.ghost_edge_fade)
	m.set_shader_parameter("wobble", g.ghost_wobble)
	m.set_shader_parameter("wobble_speed", g.ghost_wobble_speed)
	m.set_shader_parameter("opacity", 1.0)
	m.set_meta(StylePass3D.SKIP, true)
	if not unique:
		_shared[key] = m
	return m


static func set_opacity(m: ShaderMaterial, opacity: float) -> void:
	m.set_shader_parameter("opacity", opacity)


static func opacity(m: ShaderMaterial) -> float:
	var value: Variant = m.get_shader_parameter("opacity")
	return float(value) if value != null else 1.0


static func is_ghost(m: Material) -> bool:
	var shader := m as ShaderMaterial
	return shader != null and shader.shader == SHADER


static func _texture(mesh: MeshInstance3D) -> Texture2D:
	if is_ghost(mesh.material_override):
		return (mesh.material_override as ShaderMaterial).get_shader_parameter("body_tex") as Texture2D
	var count := mesh.mesh.get_surface_count() if mesh.mesh else 0
	for i in count:
		var base := mesh.get_active_material(i) as BaseMaterial3D
		if base and base.albedo_texture:
			return base.albedo_texture
	return null


static func _vertex_colour(mesh: MeshInstance3D) -> bool:
	if is_ghost(mesh.material_override):
		return (mesh.material_override as ShaderMaterial).get_shader_parameter("use_vertex_color") == true
	if mesh.mesh == null or mesh.mesh.get_surface_count() == 0:
		return false
	var base := mesh.get_active_material(0) as BaseMaterial3D
	return base != null and base.vertex_color_use_as_albedo


static func _concept(source: ShaderMaterial) -> ShaderMaterial:
	var m := source.duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", CONCEPT_TINT)
	m.set_shader_parameter("glow", 0.0)
	m.set_meta(StylePass3D.SKIP, true)
	return m


## Water dripping off the body: tiny dark drops falling from torso height.
static func _drips(root: Node3D) -> void:
	var rate := StylePass3D.get_guide().ghost_drips
	if rate <= 0.0 or root.get_node_or_null(DRIPS):
		return
	var drops := CPUParticles3D.new()
	drops.name = DRIPS
	var shape := BoxMesh.new()
	shape.size = Vector3(0.012, 0.035, 0.012)
	var wet := StandardMaterial3D.new()
	wet.albedo_color = Color("4d6466")
	wet.roughness = 0.4
	wet.set_meta(StylePass3D.SKIP, true)
	shape.material = wet
	drops.mesh = shape
	drops.amount = maxi(2, int(rate))
	drops.lifetime = 0.7
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drops.emission_box_extents = Vector3(0.22, 0.45, 0.12)
	drops.position = Vector3(0, 1.0, 0)
	drops.direction = Vector3.DOWN
	drops.spread = 5.0
	drops.initial_velocity_min = 0.1
	drops.initial_velocity_max = 0.4
	drops.gravity = Vector3(0, -9.8, 0)
	drops.local_coords = false
	root.add_child(drops)
