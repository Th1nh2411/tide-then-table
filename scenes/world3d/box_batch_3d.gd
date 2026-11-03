class_name BoxBatch3D
extends RefCounted
## Collects many static boxes / roof wedges and commits them as one mesh per
## material (a whole street of houses = a handful of draw calls). Textured
## materials should be world-triplanar (HorrorMaterials.tiled): the boxes
## carry plain face UVs only.

## material -> SurfaceTool collecting its triangles.
var _parts: Dictionary = {}

static var _colors: Dictionary = {}


## A flat, rough colour material (cached per hex + glow).
static func color(hex: String, glow: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%s" % [hex, glow]
	if _colors.has(key):
		return _colors[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(hex)
	m.roughness = 0.9
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = Color(hex)
		m.emission_energy_multiplier = glow
	_colors[key] = m
	return m


func is_empty() -> bool:
	return _parts.is_empty()


## A box centred at `pos`, turned `yaw` around Y (and `tilt` around its local X).
func box(material: Material, pos: Vector3, size: Vector3, yaw: float = 0.0, tilt: float = 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt)
	add_box(material, Transform3D(basis, pos), size)


func add_box(material: Material, xform: Transform3D, size: Vector3) -> void:
	var h := size * 0.5
	var c := [Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	# Faces as corner indices, counter-clockwise seen from outside.
	var faces := [[4, 5, 6, 7, Vector3.BACK], [1, 0, 3, 2, Vector3.FORWARD], [5, 1, 2, 6, Vector3.RIGHT],
		[0, 4, 7, 3, Vector3.LEFT], [7, 6, 2, 3, Vector3.UP], [0, 1, 5, 4, Vector3.DOWN]]
	for f: Array in faces:
		var q: Array[Vector3] = [c[f[0]], c[f[1]], c[f[2]], c[f[3]]]
		_quad(material, xform, q, f[4])


## A gable roof: ridge along local X, `size.y` high, eaves `size.z` deep.
func gable(material: Material, pos: Vector3, size: Vector3, yaw: float = 0.0) -> void:
	var xform := Transform3D(Basis(Vector3.UP, yaw), pos)
	var h := size * 0.5
	var a := Vector3(-h.x, 0, -h.z)
	var b := Vector3(h.x, 0, -h.z)
	var r0 := Vector3(-h.x, size.y, 0)
	var r1 := Vector3(h.x, size.y, 0)
	var d := Vector3(-h.x, 0, h.z)
	var e := Vector3(h.x, 0, h.z)
	var front: Array[Vector3] = [d, e, r1, r0]
	var back: Array[Vector3] = [b, a, r0, r1]
	_quad(material, xform, front, Vector3(0, h.z, size.y).normalized())
	_quad(material, xform, back, Vector3(0, h.z, -size.y).normalized())
	_tri(material, xform, [a, d, r0], Vector3.LEFT)
	_tri(material, xform, [e, b, r1], Vector3.RIGHT)


## Commits everything under a new node `name` in `parent`.
func commit(parent: Node3D, name: String, shadows: bool = true) -> Node3D:
	var root := Node3D.new()
	root.name = name
	parent.add_child(root)
	for material: Material in _parts:
		var tool: SurfaceTool = _parts[material]
		var node := MeshInstance3D.new()
		node.mesh = tool.commit()
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	_parts.clear()
	return root


func _part(material: Material) -> SurfaceTool:
	if not _parts.has(material):
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		_parts[material] = tool
	return _parts[material]


func _quad(material: Material, xform: Transform3D, q: Array[Vector3], normal: Vector3) -> void:
	var tool := _part(material)
	var n := (xform.basis * normal).normalized()
	var uvs: Array[Vector2] = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	# Godot's front faces are clockwise: emit 0-2-1, 0-3-2.
	for i: int in [0, 2, 1, 0, 3, 2]:
		tool.set_normal(n)
		tool.set_uv(uvs[i])
		tool.add_vertex(xform * q[i])


func _tri(material: Material, xform: Transform3D, t: Array, normal: Vector3) -> void:
	var tool := _part(material)
	var n := (xform.basis * normal).normalized()
	for i: int in [0, 2, 1]:
		tool.set_normal(n)
		tool.set_uv(Vector2(0.5, 0.5))
		tool.add_vertex(xform * (t[i] as Vector3))
