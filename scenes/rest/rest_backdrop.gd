extends Control
## Behind the rest card: dawn over the sea in soft palette bands (dusk
## violet → warm brown → amber at the horizon), a low sun and its broken
## reflection. Art "rest/dawn" replaces it when it exists.

const SKY: Array[Color] = [Color("172038"), Color("402751"), Color("4d2b32"), Color("7a4841"), Color("ad7757"), Color("de9e41")]
## Share of the sky each band takes (the last one fills the rest).
const BANDS: Array[float] = [0.30, 0.24, 0.17, 0.13, 0.09]
const SEA: Array[Color] = [Color("2c4058"), Color("253a5e"), Color("172038")]
const SUN := Color("f2d98a")
const GLINT := Color("e8c170")
## Sea height in px from the bottom.
const SEA_HEIGHT := 110.0

var _time: float = 0.0
var _bands: ImageTexture


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_paint)
	_paint()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


## Sky and sea bands into one image, each edge dithered over 4 rows.
func _paint() -> void:
	var w := maxi(int(size.x), 1)
	var h := maxi(int(size.y), 1)
	var horizon := int(h - SEA_HEIGHT)
	var rows: Array[Color] = []
	var edges: Array[int] = []
	var y := 0
	for i in SKY.size():
		var band := roundi(horizon * BANDS[i]) if i < SKY.size() - 1 else horizon - y
		for r in band:
			rows.append(SKY[i])
		y += band
		edges.append(y)
	for i in SEA.size():
		var band := roundi(SEA_HEIGHT / SEA.size()) if i < SEA.size() - 1 else h - y
		for r in band:
			rows.append(SEA[i])
		y += band
		if i < SEA.size() - 1:
			edges.append(y)
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for row in mini(rows.size(), h):
		image.fill_rect(Rect2i(0, row, w, 1), rows[row])
	for edge in edges:
		if edge <= 2 or edge >= h - 2 or edge == horizon:
			continue
		# Checker of the lower colour reaching up, the upper reaching down.
		for row in range(edge - 2, edge + 2):
			var other := rows[edge] if row < edge else rows[edge - 1]
			var step := 2 if absi(row - edge) <= 1 else 4
			for x in range((row % 2) * (step / 2), w, step):
				image.set_pixel(x, row, other)
	_bands = ImageTexture.create_from_image(image)


func _draw() -> void:
	if Art.draw(self, "rest/dawn", Rect2(Vector2.ZERO, size)):
		return
	if _bands == null:
		return
	draw_texture(_bands, Vector2.ZERO)
	var horizon := size.y - SEA_HEIGHT
	var sun := Vector2(roundf(size.x * 0.76), horizon)
	draw_circle(sun, 22.0, Color(SUN, 0.18))
	draw_circle(sun, 16.0, SUN)
	# The sea covers the sun's lower half.
	var sea := Rect2(0, horizon, size.x, SEA_HEIGHT)
	draw_texture_rect_region(_bands, sea, sea)
	draw_rect(Rect2(0, horizon, size.x, 1), GLINT.darkened(0.3))
	# Broken reflection: short streaks under the sun, narrower further down.
	for row in 9:
		var depth := float(row + 1) / 9.0
		var wobble := sin(_time * 1.6 + row * 1.7) * 3.0 * depth
		var width := roundf(lerpf(26.0, 6.0, depth))
		var at := Vector2(roundf(sun.x - width * 0.5 + wobble), roundf(horizon + 3.0 + row * 7.0 * (0.6 + depth)))
		draw_rect(Rect2(at, Vector2(width, 1)), GLINT if row < 4 else Color("be772b"))
