class_name FishFightBackdrop
extends RefCounted
## The fishing screen's sea cut-away: night sky, far shore, water bands that
## darken with depth and the seabed, per zone. The still part is baked into
## a texture once per zone + size; waves, kelp, light and drifting specks are
## drawn every frame on top. Art layers (640x360, drawn stretched) replace
## the baked parts when they exist: "fishing/bg_<zone>_sky" (sky + far
## shore, transparent below the surface), "fishing/bg_<zone>_water",
## "fishing/bg_<zone>_bed" (seabed, transparent above).

const ZONE_SLUGS := ["near", "reef", "open", "fog"]
## Water bands top -> bottom per zone (palette Xóm Đèn).
const WATER := {
	"near": ["3c5e8b", "2c4058", "253a5e", "172038"],
	"reef": ["3c5e8b", "2c4058", "202e37", "151d28"],
	"open": ["2c4058", "253a5e", "172038", "090a14"],
	"fog": ["577277", "394a50", "202e37", "151d28"],
}
const SKY := ["090a14", "151d28", "172038", "253a5e"]
const SAND := {"near": ["c09473", "ad7757"], "reef": ["7a4841", "4d2b32"],
	"open": ["394a50", "202e37"], "fog": ["577277", "394a50"]}
const KELP := ["25562e", "468232"]

## Surface line (y) for a screen of `size`.
static func surface_y(size: Vector2) -> float:
	return roundf(size.y * 0.28)


## Top of the seabed at x (same curve the bake uses).
static func bed_y(size: Vector2, x: float, slug: String) -> float:
	var base := size.y - (30.0 if slug == "near" else 24.0 if slug == "reef" else 16.0)
	var wave := sin(x * 0.021) * 5.0 + sin(x * 0.067 + 1.3) * 2.0
	if slug == "reef":
		wave -= maxf(0.0, sin(x * 0.012 + 0.4)) * 22.0
	return roundf(base + wave)


static func slug(zone: int) -> String:
	return ZONE_SLUGS[clampi(zone, 0, ZONE_SLUGS.size() - 1)]


## `cache`: the caller's dictionary for the baked texture (one per fishing game).
static func draw(canvas: CanvasItem, size: Vector2, zone: int, time: float, lamp_x: float, cache: Dictionary) -> void:
	var s := slug(zone)
	var rect := Rect2(Vector2.ZERO, size)
	canvas.draw_texture(_texture(s, size, cache), Vector2.ZERO)
	for layer: String in ["sky", "water", "bed"]:
		Art.draw(canvas, "fishing/bg_%s_%s" % [s, layer], rect)
	var surface := surface_y(size)
	_draw_stars(canvas, size, time)
	_draw_light(canvas, size, surface, lamp_x)
	if s != "open":
		_draw_kelp(canvas, size, s, time)
	_draw_specks(canvas, size, surface, time, lamp_x)
	if s == "fog":
		for i in 5:
			var x := fmod(i * 157.0 + time * (6.0 + i), size.x + 120.0) - 60.0
			canvas.draw_rect(Rect2(x, surface - 30.0 + i * 9.0, 90.0, 6.0), Color(0.78, 0.81, 0.8, 0.10))
	_draw_waves(canvas, size, surface, time)


static func _texture(s: String, size: Vector2, cache: Dictionary) -> Texture2D:
	var key := "%s_%dx%d" % [s, int(size.x), int(size.y)]
	if not cache.has(key):
		cache.clear()
		cache[key] = ImageTexture.create_from_image(_bake(s, Vector2i(size)))
	return cache[key]


static func _bake(s: String, size: Vector2i) -> Image:
	var image := Image.create(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	var surface := int(surface_y(Vector2(size)))
	_bands(image, 0, surface, SKY)
	var water: Array = WATER[s]
	_bands(image, surface, size.y, water)
	_far_shore(image, s, surface)
	var sand: Array = SAND[s]
	for x in size.x:
		var top := int(bed_y(Vector2(size), x, s))
		image.fill_rect(Rect2i(x, top, 1, size.y - top), Color(sand[1]))
		image.fill_rect(Rect2i(x, top, 1, 2), Color(sand[0]))
	# Rocks on the bed, a few per screen.
	for i in 6:
		var cx := int(fmod(i * 113.0 + 37.0, float(size.x)))
		var r := 6 + (i * 7) % 9
		var top := int(bed_y(Vector2(size), cx, s))
		for dx in range(-r, r + 1):
			var h := int(sqrt(float(r * r - dx * dx)) * 0.7)
			image.fill_rect(Rect2i(cx + dx, top - h, 1, h + 2), Color("394a50") if dx < r / 3 else Color("202e37"))
		image.fill_rect(Rect2i(cx - r / 2, top - int(r * 0.7), r / 2, 1), Color("577277"))
	# Stars in the sky.
	for i in 40:
		var at := Vector2i(int(fmod(i * 97.31, float(size.x))), int(fmod(i * 53.7, float(surface - 24))) + 2)
		image.set_pixelv(at, Color("c7cfcc") if i % 3 else Color("e6f6ff"))
	return image


## Horizontal bands from y0 to y1 with a checker dither between them.
static func _bands(image: Image, y0: int, y1: int, colors: Array) -> void:
	var step := float(y1 - y0) / colors.size()
	for i in colors.size():
		var top := y0 + int(i * step)
		image.fill_rect(Rect2i(0, top, image.get_width(), int(step) + 2), Color(colors[i]))
		if i == 0:
			continue
		for row in 2:
			for x in range(row, image.get_width(), 2):
				image.set_pixel(x, top - 1 - row * 2, Color(colors[i]))
				image.set_pixel(x, top + row * 2, Color(colors[i - 1]))


## Islands / the village on the horizon; nothing far out at sea.
static func _far_shore(image: Image, s: String, surface: int) -> void:
	var color := Color("202e37")
	match s:
		"near":
			for x in image.get_width():
				var h := int(10.0 + sin(x * 0.03) * 4.0 + sin(x * 0.11) * 2.0)
				image.fill_rect(Rect2i(x, surface - h, 1, h), color)
			for i in 9:  # house lights of Xóm Đèn
				image.fill_rect(Rect2i(60 + i * 61 % 560, surface - 6 - i % 3, 2, 2), Color("e8c170"))
		"reef":
			for x in image.get_width():
				var h := int(maxf(0.0, sin(x * 0.015 + 2.0)) * 26.0 + maxf(0.0, sin(x * 0.04)) * 8.0)
				image.fill_rect(Rect2i(x, surface - h, 1, h), color)
		"fog":
			image.fill_rect(Rect2i(0, surface - 20, image.get_width(), 20), Color("394a50"))


static func _draw_stars(canvas: CanvasItem, size: Vector2, time: float) -> void:
	var moon := Vector2(size.x * 0.12, 26.0)
	canvas.draw_circle(moon, 11.0, Color("e6f6ff"))
	canvas.draw_circle(moon + Vector2(5, -3), 10.0, Color("151d28"))
	for i in 6:  # a few twinkle
		var on := sin(time * (1.3 + i * 0.4) + i) > 0.6
		if on:
			var at := Vector2(fmod(i * 211.0 + 90.0, size.x), 8.0 + fmod(i * 41.0, 50.0))
			canvas.draw_rect(Rect2(at - Vector2(1, 0), Vector2(3, 1)), Color("f2d98a"))
			canvas.draw_rect(Rect2(at - Vector2(0, 1), Vector2(1, 3)), Color("f2d98a"))


## The boat lamp's cone into the water.
static func _draw_light(canvas: CanvasItem, size: Vector2, surface: float, lamp_x: float) -> void:
	for i in 3:
		var spread := 46.0 + i * 34.0
		var cone := PackedVector2Array([Vector2(lamp_x - 10, surface), Vector2(lamp_x + 10, surface),
			Vector2(lamp_x + spread, size.y), Vector2(lamp_x - spread, size.y)])
		canvas.draw_colored_polygon(cone, Color(0.95, 0.85, 0.54, 0.05))


static func _draw_kelp(canvas: CanvasItem, size: Vector2, s: String, time: float) -> void:
	var count := 9 if s == "reef" else 5
	for i in count:
		var x := fmod(i * 73.0 + 21.0, size.x)
		var base := Vector2(x, bed_y(size, x, s) + 1.0)
		var height := 26.0 + fmod(i * 17.0, 30.0)
		var points := PackedVector2Array()
		for k in 7:
			var t := k / 6.0
			points.append(base + Vector2(sin(time * 1.4 + i + t * 3.0) * 5.0 * t, -height * t))
		canvas.draw_polyline(points, Color(KELP[i % 2]), 2.0)


## Plankton specks drifting up, bright inside the lamp light.
static func _draw_specks(canvas: CanvasItem, size: Vector2, surface: float, time: float, lamp_x: float) -> void:
	for i in 28:
		var x := fmod(i * 59.0 + sin(time * 0.5 + i) * 8.0, size.x)
		var span := size.y - surface - 20.0
		var y := size.y - 20.0 - fmod(i * 37.0 + time * (4.0 + i % 5), span)
		var lit := absf(x - lamp_x) < 30.0 + (y - surface) * 0.6
		canvas.draw_rect(Rect2(roundf(x), roundf(y), 1, 1), Color(0.95, 0.9, 0.6, 0.8) if lit else Color(0.45, 0.75, 0.8, 0.35))


static func _draw_waves(canvas: CanvasItem, size: Vector2, surface: float, time: float) -> void:
	var points := PackedVector2Array()
	for x in range(0, int(size.x) + 9, 8):
		points.append(Vector2(x, surface + roundf(sin(x * 0.05 + time * 1.8) * 1.5)))
	canvas.draw_polyline(points, Color(0.65, 0.87, 0.86, 0.75), 1.0)
	for i in 10:  # glints
		var x := fmod(i * 67.0 + time * 9.0, size.x)
		canvas.draw_rect(Rect2(roundf(x), surface + 2.0 + (i % 3) * 3.0, 4.0 + i % 3 * 2.0, 1.0), Color(0.9, 0.96, 1.0, 0.35))
