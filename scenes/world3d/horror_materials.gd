class_name HorrorMaterials
extends RefCounted
## Textured materials for the horror build's places (assets/textures/horror/,
## docs/HORROR_ART_BRIEF.md). Boxes have no useful UVs, so tiling textures are
## projected world-triplanar at `metres` per tile; nearest filtering keeps the
## PS1 look. Materials are cached per texture + scale.

const DIR := "res://assets/textures/horror/"

static var _cache: Dictionary = {}


## A tiling surface (wall, floor, ground, roof): one tile per `metres`.
static func tiled(texture_name: String, metres: float = 1.0, tint: Color = Color.WHITE) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [texture_name, metres, tint.to_html()]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(DIR + texture_name + ".png") as Texture2D
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / maxf(metres, 0.01)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 0.95
	_cache[key] = m
	return m


## A single picture on one face (a door, a calendar page): a quad facing +Z.
static func picture(parent: Node3D, texture_name: String, at: Vector3, size: Vector2, yaw: float = 0.0) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	var mesh := MeshInstance3D.new()
	mesh.mesh = quad
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(DIR + texture_name + ".png") as Texture2D
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.roughness = 0.95
	mesh.material_override = m
	parent.add_child(mesh)
	mesh.position = at
	mesh.rotation.y = yaw
	return mesh
