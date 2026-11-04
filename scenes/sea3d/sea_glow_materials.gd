class_name SeaGlowMaterials
extends RefCounted
## Materials for lights seen across the night sea (SeaLandmarks3D): unshaded,
## additive, untouched by the fog and StylePass3D. Each call makes a new one
## (lamps animate their own alpha).

static var _soft: GradientTexture2D


## A bulb: solid over-bright colour.
static func bulb(hex: String) -> StandardMaterial3D:
	var m := _base(hex, 1.0)
	m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
	m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	m.albedo_color = Color(hex) * 1.6
	return m


## A soft round glow that keeps its size on screen (a point of light far off).
static func halo(hex: String, alpha: float) -> StandardMaterial3D:
	var m := _base(hex, alpha)
	m.albedo_texture = _soft_texture()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.fixed_size = true
	return m


## A lighthouse beam: faint, fading out by vertex alpha (SeaLandmarks3D).
static func beam(hex: String) -> StandardMaterial3D:
	var m := _base(hex, 0.22)
	m.vertex_color_use_as_albedo = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _base(hex: String, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	m.disable_fog = true
	m.disable_receive_shadows = true
	var color := Color(hex)
	color.a = alpha
	m.albedo_color = color
	m.set_meta("style_skip", true)
	return m


static func _soft_texture() -> GradientTexture2D:
	if _soft == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0))
		g.add_point(0.25, Color(1, 1, 1, 0.55))
		_soft = GradientTexture2D.new()
		_soft.gradient = g
		_soft.fill = GradientTexture2D.FILL_RADIAL
		_soft.fill_from = Vector2(0.5, 0.5)
		_soft.fill_to = Vector2(0.5, 0.0)
		_soft.width = 32
		_soft.height = 32
	return _soft
