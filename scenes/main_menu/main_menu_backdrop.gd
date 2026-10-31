extends Control
## Living night backdrop for the main menu, drawn in code: sky, far village
## lights across the water, a string of lanterns, a fishing boat with its
## lamp, slow wave lines, reflections and warm bokeh drifting up.

const SKY_TOP := Color("0d1020")
const SKY_LOW := Color("2b2a3f")
const HAZE := Color("6b3f3a")
const SEA_TOP := Color("1a2236")
const SEA_LOW := Color("0b0e18")
const SEA := Color("73bed3")
const GOLD := Color("f2d98a")
const AMBER := Color("de9e41")
const CHILI := Color("cf573c")
const BULB_COLORS: Array[Color] = [Color("f2d98a"), Color("de9e41"), Color("cf573c"), Color("f2d98a"), Color("73bed3")]
const HORIZON: float = 0.6  # share of the height
const BOKEH_COUNT: int = 26

## Where the title glow sits (set by the menu, local coordinates).
var title_glow_at: Vector2 = Vector2(150, 92)
var title_glow_strength: float = 1.0
var _time: float = 0.0
var _glow: GradientTexture2D
var _bokeh: Array[Vector4] = []  # x, y, radius, phase
var _stars: Array[Vector3] = []  # x, y, phase
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 7
	_glow = _make_glow()
	for i in BOKEH_COUNT:
		_bokeh.append(Vector4(_rng.randf(), _rng.randf(), _rng.randf_range(1.5, 5.5), _rng.randf() * TAU))
	for i in 40:
		_stars.append(Vector3(_rng.randf(), _rng.randf() * HORIZON * 0.8, _rng.randf() * TAU))


func _process(delta: float) -> void:
	_time += delta
	for i in _bokeh.size():
		var b := _bokeh[i]
		b.y -= delta * (0.012 + b.z * 0.004)
		b.x += sin(_time * 0.4 + b.w) * delta * 0.004
		if b.y < -0.05:
			b = Vector4(_rng.randf(), 1.05, _rng.randf_range(1.5, 5.5), _rng.randf() * TAU)
		_bokeh[i] = b
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var horizon := h * HORIZON
	_gradient_rect(Rect2(0, 0, w, horizon), SKY_TOP, SKY_LOW)
	_gradient_rect(Rect2(0, horizon - 40, w, 40), Color(HAZE, 0.0), Color(HAZE, 0.35))
	for s in _stars:
		var a := 0.25 + 0.35 * (0.5 + 0.5 * sin(_time * 1.3 + s.z))
		draw_rect(Rect2(s.x * w, s.y * h, 1, 1), Color(1, 0.95, 0.85, a))
	_glow_at(Vector2(w * 0.86, h * 0.16), 46.0, Color(0.95, 0.9, 0.75, 0.18))
	draw_circle(Vector2(w * 0.86, h * 0.16), 9.0, Color("efe3c4"))
	draw_circle(Vector2(w * 0.86 + 3, h * 0.16 - 2), 8.0, Color(SKY_TOP.lerp(SKY_LOW, 0.2), 0.95))
	_gradient_rect(Rect2(0, horizon, w, h - horizon), SEA_TOP, SEA_LOW)
	_draw_village(w, horizon)
	_draw_waves(w, h, horizon)
	_draw_boat(Vector2(w * 0.78, horizon + 58), horizon)
	_glow_at(title_glow_at, 150.0, Color(AMBER, 0.25 * title_glow_strength))
	_draw_lanterns(w)
	for b in _bokeh:
		var a := 0.12 + 0.12 * sin(_time * 0.9 + b.w)
		var c := AMBER if int(b.w * 10.0) % 3 != 0 else GOLD
		_glow_at(Vector2(b.x * w, b.y * h), b.z * 3.0, Color(c, a))
	# Vignette: darker corners pull the eye to the middle.
	_gradient_rect(Rect2(0, h - 50, w, 50), Color(0, 0, 0, 0), Color(0, 0, 0, 0.45))
	_gradient_rect(Rect2(0, 0, w, 30), Color(0, 0, 0, 0.35), Color(0, 0, 0, 0))


## Far shore: a low line of houses with warm windows that flicker.
func _draw_village(w: float, horizon: float) -> void:
	var x := w * 0.42
	var i := 0
	while x < w + 20:
		var bw := 14.0 + float((i * 37) % 11)
		var bh := 6.0 + float((i * 53) % 9)
		draw_rect(Rect2(x, horizon - bh, bw, bh + 1), Color("161827"))
		if (i * 7) % 3 != 0:
			var flick := 0.75 + 0.25 * sin(_time * (1.5 + i % 4) + i)
			var lit := Color(GOLD, 0.8 * flick)
			draw_rect(Rect2(x + 3, horizon - bh + 2, 2, 2), lit)
			_glow_at(Vector2(x + 4, horizon - bh + 3), 7.0, Color(AMBER, 0.25 * flick))
			# Its reflection, broken by the swell.
			var ry := horizon + 4.0 + float(i % 3)
			draw_line(Vector2(x + 2 + sin(_time + i) * 1.5, ry), Vector2(x + 6 + sin(_time + i) * 1.5, ry), Color(AMBER, 0.3 * flick), 1.0)
		x += bw + 2.0 + float((i * 13) % 6)
		i += 1


func _draw_waves(w: float, h: float, horizon: float) -> void:
	for row in 7:
		var t := float(row) / 6.0
		var y := lerpf(horizon + 8.0, h - 16.0, t * t)
		var amp := lerpf(0.6, 2.6, t)
		var speed := lerpf(0.25, 0.7, t) * (1.0 if row % 2 else -1.0)
		var points := PackedVector2Array()
		var step := 8.0
		var px := 0.0
		while px <= w + step:
			points.append(Vector2(px, y + sin(px * lerpf(0.05, 0.02, t) + _time * speed + row) * amp))
			px += step
		draw_polyline(points, Color(SEA, lerpf(0.08, 0.2, t)), 1.0)


func _draw_boat(at: Vector2, horizon: float) -> void:
	var bob := sin(_time * 1.1) * 1.6
	var tilt := sin(_time * 0.8) * 0.05
	var lamp := at + Vector2(10, -22 + bob)
	# Lamp reflection: a shimmering column on the water.
	for k in 9:
		var ry := at.y + 6.0 + k * 5.0
		var wob := sin(_time * 2.2 + k * 0.9) * (2.0 + k * 0.5)
		draw_line(Vector2(lamp.x - 4 + wob, ry), Vector2(lamp.x + 4 + wob, ry), Color(GOLD, 0.35 - k * 0.035), 1.5)
	_glow_at(lamp, 56.0, Color(AMBER, 0.55 + 0.08 * sin(_time * 5.0)))
	draw_set_transform(at + Vector2(0, bob), tilt, Vector2.ONE)
	var hull := PackedVector2Array([Vector2(-34, -6), Vector2(30, -6), Vector2(22, 4), Vector2(-26, 4)])
	draw_colored_polygon(hull, Color("0f111b"))
	draw_line(Vector2(-34, -6), Vector2(30, -6), Color(AMBER, 0.5), 1.0)
	# Rin in his nón lá, sitting at the stern.
	draw_rect(Rect2(-20, -16, 6, 10), Color("0f111b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-25, -16), Vector2(-9, -16), Vector2(-17, -22)]), Color("0f111b"))
	draw_line(Vector2(-12, -12), Vector2(8, -40), Color("0f111b"), 1.0)  # rod
	draw_line(Vector2(10, -6), Vector2(10, -22), Color("0f111b"), 1.0)  # lamp pole
	draw_set_transform(Vector2.ZERO)
	draw_circle(lamp, 2.5, Color(1.0, 0.95, 0.75))


## A sagging string of bulbs across the top, swaying in the night wind.
func _draw_lanterns(w: float) -> void:
	var left := Vector2(-10, 14)
	var right := Vector2(w + 10, 22)
	var sway := sin(_time * 0.7) * 3.0
	var points := PackedVector2Array()
	var count := 16
	for i in count + 1:
		var t := float(i) / count
		var p := left.lerp(right, t)
		p.y += sin(t * PI) * (26.0 + sway)
		points.append(p)
	draw_polyline(points, Color("0a0b12"), 1.0, true)
	for i in range(1, count):
		var p := points[i] + Vector2(0, 5)
		var c := BULB_COLORS[i % BULB_COLORS.size()]
		var flick := 0.85 + 0.15 * sin(_time * 3.0 + i * 1.7)
		_glow_at(p, 24.0, Color(c, 0.5 * flick))
		draw_line(points[i], p - Vector2(0, 2), Color("0a0b12"), 1.0)
		draw_circle(p, 2.6, c.lightened(0.3) * Color(1, 1, 1, flick))


func _glow_at(center: Vector2, radius: float, color: Color) -> void:
	draw_texture_rect(_glow, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, color)


func _gradient_rect(rect: Rect2, top: Color, bottom: Color) -> void:
	var pts := PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)])
	draw_polygon(pts, PackedColorArray([top, top, bottom, bottom]))


static func _make_glow() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	gradient.add_point(0.35, Color(1, 1, 1, 0.45))
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex
