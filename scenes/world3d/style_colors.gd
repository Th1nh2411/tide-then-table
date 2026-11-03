class_name StyleColors
extends RefCounted
## Colour maths for the style pass, its test and the review table: texture
## means and a CPU copy of the shader grade (psx_style.gdshaderinc). All sRGB.

static var _means: Dictionary = {}  # texture id + rect -> Color


## Mean colour of `texture` inside `rect` (uv), ignoring the concepts'
## plain light-grey background. Grey 0.5 when the pixels can't be read.
static func texture_mean(texture: Texture2D, rect: Rect2 = Rect2(0, 0, 1, 1)) -> Color:
	if texture == null:
		return Color.WHITE
	var key := "%d|%s" % [texture.get_instance_id(), rect]
	if _means.has(key):
		return _means[key]
	var mean := Color(0.5, 0.5, 0.5)
	var image := texture.get_image()
	if image and not image.is_empty():
		image = image.duplicate() as Image
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		image.resize(32, 32, Image.INTERPOLATE_NEAREST)
		var sum := Vector3.ZERO
		var count := 0
		for y in range(int(rect.position.y * 32), int(rect.end.y * 32)):
			for x in range(int(rect.position.x * 32), int(rect.end.x * 32)):
				var c := image.get_pixel(x, y)
				if c.a < 0.5 or is_background(c):
					continue
				sum += Vector3(c.r, c.g, c.b)
				count += 1
		if count > 0:
			sum /= count
			mean = Color(sum.x, sum.y, sum.z)
	_means[key] = mean
	return mean


static func is_background(c: Color) -> bool:
	return absf(c.r - c.g) < 0.035 and absf(c.g - c.b) < 0.035 and c.r > 0.55


static func saturation(c: Color) -> float:
	var hi := maxf(c.r, maxf(c.g, c.b))
	var lo := minf(c.r, minf(c.g, c.b))
	return (hi - lo) / maxf(hi, 0.0001)


static func value(c: Color) -> float:
	return maxf(c.r, maxf(c.g, c.b))


## The shader's grade (without grime / palette pull) on one colour.
static func grade(c: Color, guide: StyleGuide, tint: Color) -> Color:
	var l := c.r * 0.299 + c.g * 0.587 + c.b * 0.114
	var out := Color(lerpf(l, c.r, guide.saturation), lerpf(l, c.g, guide.saturation), lerpf(l, c.b, guide.saturation))
	var hi := value(out)
	var s := saturation(out)
	if s > guide.max_saturation:
		var k := guide.max_saturation / s
		out = Color(hi - (hi - out.r) * k, hi - (hi - out.g) * k, hi - (hi - out.b) * k)
	out = Color(out.r * tint.r, out.g * tint.g, out.b * tint.b)
	hi = value(out)
	if hi > guide.max_value:
		out = out * (guide.max_value / hi)
	var lift := guide.black_lift
	return Color(out.r * (1.0 - lift) + lift, out.g * (1.0 - lift) + lift, out.b * (1.0 - lift) + lift)


## What a material looks like on average before / after the pass (albedo x
## texture mean, graded if it is a styled shader). `ok` false = can't tell.
static func material_mean(material: Material) -> Dictionary:
	var base := material as BaseMaterial3D
	if base:
		var tex := texture_mean(base.albedo_texture) if base.albedo_texture else Color.WHITE
		return {"ok": true, "color": base.albedo_color * tex, "graded": false}
	var shader := material as ShaderMaterial
	if shader == null or shader.shader == null:
		return {"ok": false}
	if shader.shader == StyleMaterials.SHADER or shader.shader == StyleMaterials.SHADER_2S:
		var albedo: Color = shader.get_shader_parameter("albedo_color")
		var texture := shader.get_shader_parameter("albedo_tex") as Texture2D
		var raw := albedo * (texture_mean(texture) if shader.get_shader_parameter("use_tex") == true else Color.WHITE)
		if shader.get_shader_parameter("style_on") != true:
			return {"ok": true, "color": raw, "graded": false}
		var t: Vector3 = shader.get_shader_parameter("tint")
		return {"ok": true, "color": grade(raw, StylePass3D.get_guide(), Color(t.x, t.y, t.z)), "graded": true}
	if shader.shader.resource_path == StylePass3D.CONCEPT_SHADER:
		var mean := StylePass3D.concept_mean(shader)
		var tint: Variant = shader.get_shader_parameter("tint")
		var tc: Color = Color.WHITE
		if tint is Color:
			tc = tint
		elif tint is Vector3:
			var v: Vector3 = tint
			tc = Color(v.x, v.y, v.z)
		return {"ok": true, "color": Color(mean.r * tc.r, mean.g * tc.g, mean.b * tc.b), "graded": shader.has_meta(StylePass3D.STYLED)}
	return {"ok": false}
