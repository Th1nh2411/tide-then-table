class_name StylePass3D
extends RefCounted
## One shared look for every 3D model (StyleGuide, data/art/style_guide.tres).
## SceneRouter hooks `on_node_added`: each MeshInstance3D is styled once,
## deferred (builders set materials right after add_child), before PsxLook3D
## copies it (PsxLook3D._apply calls `apply_mesh` first). Opaque lit
## StandardMaterial3Ds -> graded psx_vertex (StyleMaterials); ConceptModel3D
## shaders -> a balanced tint. Opt out: meta "style_skip" on the node or any
## parent (lamps, omen lights, eyes, the ghost look) or on a material.
## Glowing, see-through and unshaded materials are kept as they are.

const SKIP := "style_skip"
const DONE := "style_done"
const STYLED := "style_graded"
const CONCEPT_SHADER := "res://scenes/world3d/concept_projection.gdshader"

static var guide: StyleGuide
## Off with `-- --no-style` (before / after comparisons).
static var enabled := not OS.get_cmdline_user_args().has("--no-style")
static var phase := "night"
static var _concepts: Array[WeakRef] = []


static func get_guide() -> StyleGuide:
	if guide == null:
		guide = StyleGuide.load_default()
	return guide


static func on_node_added(node: Node) -> void:
	if enabled and node is MeshInstance3D:
		_apply_later.call_deferred(node)


## Deferred: the node may be freed by then (a Variant, so that is no error).
static func _apply_later(node: Variant) -> void:
	if is_instance_valid(node):
		apply_mesh(node as MeshInstance3D)


static func apply_tree(root: Node) -> void:
	if root is MeshInstance3D:
		apply_mesh(root as MeshInstance3D)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		apply_mesh(node as MeshInstance3D)


static func skipped(node: Node) -> bool:
	while node:
		if node.has_meta(SKIP):
			return true
		node = node.get_parent()
	return false


static func apply_mesh(mesh: MeshInstance3D) -> void:
	if not enabled or not is_instance_valid(mesh) or mesh.mesh == null or mesh.has_meta(DONE):
		return
	if mesh.is_inside_tree() and skipped(mesh):
		return
	mesh.set_meta(DONE, true)
	if mesh.material_override:
		mesh.material_override = style(mesh.material_override, mesh)
		return
	for i in mesh.mesh.get_surface_count():
		var source := mesh.get_active_material(i)
		var styled := style(source, mesh)
		if styled != source:
			mesh.set_surface_override_material(i, styled)


## The styled version of `source` (itself when it is kept as it is).
static func style(source: Material, mesh: MeshInstance3D = null) -> Material:
	if source == null or source.has_meta(SKIP):
		return source
	var shader := source as ShaderMaterial
	if shader:
		if shader.shader and shader.shader.resource_path == CONCEPT_SHADER:
			_style_concept(shader)
		elif shader.shader == StyleMaterials.SHADER or shader.shader == StyleMaterials.SHADER_2S:
			if not shader.has_meta(STYLED):
				StyleMaterials.set_grade(shader, get_guide(), tint())
				shader.set_meta(STYLED, true)
		return source
	var base := source as BaseMaterial3D
	if base == null or StyleMaterials.keeps(base):
		return source
	return StyleMaterials.convert(base, mesh, get_guide(), tint())


static func tint() -> Color:
	return get_guide().phase_tint(phase)


## "morning" / "shift" / "night" / "sea": every styled material takes its tint.
static func set_phase(next: String) -> void:
	phase = next
	var t := tint()
	for m: ShaderMaterial in StyleMaterials.all():
		m.set_shader_parameter("tint", Vector3(t.r, t.g, t.b))
	var alive: Array[WeakRef] = []
	for ref in _concepts:
		var m := ref.get_ref() as ShaderMaterial
		if m:
			m.set_shader_parameter("tint", _concept_tint(m))
			alive.append(ref)
	_concepts = alive


## ConceptModel3D keeps its shader: only its tint (balanced towards grey,
## capped in value) and roughness are set.
static func _style_concept(m: ShaderMaterial) -> void:
	if m.has_meta(STYLED):
		return
	m.set_meta(STYLED, true)
	m.set_shader_parameter("roughness", get_guide().roughness_min + 0.1)
	m.set_shader_parameter("tint", _concept_tint(m))
	_concepts.append(weakref(m))


static func _concept_tint(m: ShaderMaterial) -> Color:
	var g := get_guide()
	var mean := concept_mean(m)
	var grey := (mean.r + mean.g + mean.b) / 3.0
	var t := Color(1, 1, 1)
	for c in 3:
		t[c] = lerpf(1.0, grey / maxf(mean[c], 0.02), g.concept_balance)
	var top := maxf(mean.r * t.r, maxf(mean.g * t.g, mean.b * t.b))
	var scale := minf(1.0, g.max_value / maxf(top, 0.001))
	var p := tint()
	return Color(t.r * scale * p.r, t.g * scale * p.g, t.b * scale * p.b)


## Mean colour of a concept material's image inside its crop (the object).
static func concept_mean(m: ShaderMaterial) -> Color:
	var texture := m.get_shader_parameter("concept") as Texture2D
	var crop: Variant = m.get_shader_parameter("crop")
	var rect := Rect2(0, 0, 1, 1)
	if crop is Vector4:
		var c := crop as Vector4
		rect = Rect2(c.x, c.y, c.z, c.w)
	return StyleColors.texture_mean(texture, rect)
