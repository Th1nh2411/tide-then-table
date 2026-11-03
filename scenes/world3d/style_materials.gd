class_name StyleMaterials
extends RefCounted
## StylePass3D's material work: an opaque lit StandardMaterial3D becomes the
## shared psx_vertex shader with the StyleGuide grade on. Shared by look:
## same colour / texture / settings = one ShaderMaterial, whatever the source
## instance (builders make one StandardMaterial3D per box).

const SHADER := preload("res://scenes/world3d/psx_vertex.gdshader")
const SHADER_2S := preload("res://scenes/world3d/psx_vertex_2s.gdshader")
## Rough share of an atlas texture really used by the UVs.
const ATLAS_COVERAGE := 0.6

static var _shared: Dictionary = {}  # look key -> ShaderMaterial


## True if this material is left as it is: see-through, self-lit (lamps,
## bulbs, omen glows), unshaded (eyes, signs, UI quads) or billboards.
static func keeps(base: BaseMaterial3D) -> bool:
	return base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED \
		or base.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
		or glows(base) \
		or base.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED \
		or base.has_meta(StylePass3D.SKIP)


## Really self-lit (the PSX pack has emission on at energy 0).
static func glows(base: BaseMaterial3D) -> bool:
	if not base.emission_enabled:
		return false
	var e := base.emission * base.emission_energy_multiplier
	return base.emission_texture != null or e.r + e.g + e.b > 0.03


## The graded ShaderMaterial for `base` as drawn on `mesh` (texel density).
static func convert(base: BaseMaterial3D, mesh: MeshInstance3D, guide: StyleGuide, tint: Color) -> ShaderMaterial:
	var step := texel_step(base, mesh, guide)
	var albedo := worn(base, mesh, guide)
	var key := "%s|%s|%s|%s|%s|%s|%s|%s|%s|%s" % [albedo.to_html(), base.albedo_texture.get_instance_id() if base.albedo_texture else 0,
		base.vertex_color_use_as_albedo, base.uv1_scale, base.uv1_offset, base.uv1_triplanar, base.uv1_world_triplanar,
		base.cull_mode, snappedf(base.roughness, 0.05), step]
	key += "|%s" % (base.metallic >= guide.metal_threshold)
	if _shared.has(key):
		return _shared[key]
	var m := ShaderMaterial.new()
	m.shader = SHADER if base.cull_mode == BaseMaterial3D.CULL_BACK else SHADER_2S
	m.set_shader_parameter("albedo_color", albedo)
	m.set_shader_parameter("use_tex", base.albedo_texture != null)
	if base.albedo_texture:
		m.set_shader_parameter("albedo_tex", base.albedo_texture)
	m.set_shader_parameter("use_vertex_color", base.vertex_color_use_as_albedo)
	m.set_shader_parameter("uv_scale_offset", Vector4(base.uv1_scale.x, base.uv1_scale.y, base.uv1_offset.x, base.uv1_offset.y))
	m.set_shader_parameter("triplanar", base.uv1_triplanar)
	m.set_shader_parameter("triplanar_world", base.uv1_world_triplanar)
	m.set_shader_parameter("roughness", clampf(base.roughness, guide.roughness_min, guide.roughness_max))
	m.set_shader_parameter("metallic", base.metallic if base.metallic >= guide.metal_threshold else 0.0)
	m.set_shader_parameter("texel_step", step)
	set_grade(m, guide, tint)
	m.set_meta(StylePass3D.STYLED, true)
	_shared[key] = m
	return m


## The albedo after the guide's `recolor` (worn props), else the source's.
static func worn(base: BaseMaterial3D, mesh: Node, guide: StyleGuide) -> Color:
	if guide.recolor.is_empty():
		return base.albedo_color
	var hex := base.albedo_color.to_html(false)
	var node := mesh
	while node:
		for key: String in guide.recolor:
			var parts := key.split("|")
			if parts[1] == hex and String(node.name).begins_with(parts[0]):
				var c: Color = guide.recolor[key]
				return Color(c.r, c.g, c.b, base.albedo_color.a)
		node = node.get_parent()
	return base.albedo_color


## The grade uniforms (also turns the grade on for a PsxLook3D-made material).
static func set_grade(m: ShaderMaterial, guide: StyleGuide, tint: Color) -> void:
	m.set_shader_parameter("style_on", true)
	m.set_shader_parameter("saturation", guide.saturation)
	m.set_shader_parameter("max_saturation", guide.max_saturation)
	m.set_shader_parameter("max_value", guide.max_value)
	m.set_shader_parameter("black_lift", guide.black_lift)
	m.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("palette_pull", guide.palette_pull)
	var colours: Array[Vector3] = []
	for c: Color in guide.palette:
		colours.append(Vector3(c.r, c.g, c.b))
	colours.resize(mini(colours.size(), 48))
	m.set_shader_parameter("palette", colours)
	m.set_shader_parameter("palette_size", colours.size())
	m.set_shader_parameter("grime_scale", guide.grime_scale)
	m.set_shader_parameter("grime_amount", guide.grime_amount)
	m.set_shader_parameter("speckle_cells", guide.speckle_cells)
	m.set_shader_parameter("speckle_amount", guide.speckle_amount)
	m.set_shader_parameter("base_height", guide.base_height)
	m.set_shader_parameter("base_dark", guide.base_dark)


## Source texels per metre of `base` on `mesh` (0 = untextured).
static func texel_density(base: BaseMaterial3D, mesh: MeshInstance3D) -> float:
	var texture := base.albedo_texture
	if texture == null:
		return 0.0
	var size := Vector2(texture.get_width(), texture.get_height())
	if base.uv1_triplanar:
		return size.x * base.uv1_scale.x
	if mesh == null or mesh.mesh == null:
		return 0.0
	var scale := mesh.global_transform.basis.get_scale() if mesh.is_inside_tree() else mesh.scale
	var box := mesh.get_aabb().size * scale.abs()
	var area := 2.0 * (box.x * box.y + box.y * box.z + box.x * box.z)
	return sqrt(size.x * size.y * ATLAS_COVERAGE / maxf(area, 0.0001))


## Source texels blocked into one so every model lands near the guide's density.
static func texel_step(base: BaseMaterial3D, mesh: MeshInstance3D, guide: StyleGuide) -> float:
	var density := texel_density(base, mesh)
	if density <= 0.0:
		return 1.0
	var ratio := density / guide.texels_per_metre
	# Atlases (characters, props) only when far too sharp: blocks bleed across UV islands.
	if not base.uv1_triplanar and ratio < 3.0:
		return 1.0
	return clampf(floorf(ratio), 1.0, guide.max_texel_step)


## Every ShaderMaterial this made (phase tint updates).
static func all() -> Array:
	return _shared.values()
