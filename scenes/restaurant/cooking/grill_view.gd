class_name GrillView
extends RefCounted
## Draws the charcoal grill of the grill minigame (GrillGame) with the
## seafood big on it: glowing coals, the grate, the fish / shrimp / squid /
## snails browning, char lines, smoke, and the flip (squash through the
## middle). Art: "grill/<fish_id>" (raw look, tinted as it cooks) replaces
## the code drawing. Static helpers, no state.

const RAW := Color(0.92, 0.88, 0.85)
const GOLDEN := Color(0.85, 0.55, 0.25)
const CHARRED := Color(0.18, 0.12, 0.1)


## Cooked colour for doneness `d` (0 raw .. 1 burnt), golden inside `ok`.
static func cooked_color(d: float, ok: Vector2) -> Color:
	if d <= ok.x:
		return RAW.lerp(GOLDEN, clampf(d / maxf(ok.x, 0.01), 0.0, 1.0) * 0.8)
	if d <= ok.y:
		return GOLDEN
	return GOLDEN.lerp(CHARRED, clampf((d - ok.y) / maxf(1.0 - ok.y, 0.01), 0.0, 1.0))


## The grill in `r`: coals, grate, then the seafood at `drop` (0..1 height
## above the grate while it falls in), squashed by `flip` (-1..1 scale y),
## `top_color` = the side facing up, `edge_color` = the side cooking below
## (shows at the rim), `smoke` 0..1.
static func draw(canvas: CanvasItem, r: Rect2, fish_id: String, top_color: Color, edge_color: Color,
		flip: float, drop: float, smoke: float, time: float, grill_marks: bool) -> void:
	canvas.draw_rect(r, Color(0.35, 0.2, 0.14))  # clay brazier
	var bed := r.grow(-4)
	canvas.draw_rect(bed, Color(0.12, 0.08, 0.07))
	for i in int(bed.size.x / 6.0):  # coals
		for j in 2:
			var glow := 0.55 + 0.45 * sin(time * 4.0 + i * 1.7 + j * 2.3)
			canvas.draw_circle(bed.position + Vector2(4 + i * 6, bed.size.y - 5 - j * 6), 2.4,
				Color(1.0, 0.35 * glow + 0.1, 0.05, glow))
	var center := bed.get_center() + Vector2(0, -drop * r.size.y * 1.2)
	var size := Vector2(bed.size.x * 0.7, bed.size.y * 0.55)
	if Art.has("grill/" + fish_id):
		var squash := Vector2(1.0, absf(flip))
		canvas.draw_set_transform(center, 0.0, squash)
		Art.draw(canvas, "grill/" + fish_id, Rect2(-size * 0.5, size), false, Color.WHITE.lerp(top_color, 0.6))
		canvas.draw_set_transform(Vector2.ZERO)
	else:
		_draw_seafood(canvas, fish_id, center, size, top_color, edge_color, absf(flip), grill_marks)
	for x in range(int(bed.position.x) + 3, int(bed.end.x), 7):  # grate over the coals
		canvas.draw_line(Vector2(x, bed.position.y + 2), Vector2(x, bed.end.y - 2), Color(0.6, 0.6, 0.62, 0.55), 1.0)
	for k in int(1 + smoke * 4.0):  # smoke, thicker when it's about to burn
		var t := fmod(time * 0.8 + k * 0.27, 1.0)
		var grey := lerpf(0.85, 0.35, smoke)
		canvas.draw_circle(center + Vector2(sin(time * 2.0 + k) * 6.0 + (k - 2) * 5.0, -t * r.size.y * 0.8),
			3.0 + t * 5.0, Color(grey, grey, grey, (0.25 + smoke * 0.35) * (1.0 - t)))


static func _draw_seafood(canvas: CanvasItem, fish_id: String, c: Vector2, s: Vector2, top: Color, edge: Color,
		squash: float, marks: bool) -> void:
	var h := s.y * squash * 0.5
	var w := s.x * 0.5
	if fish_id.begins_with("ca_"):  # fish: body, tail, eye
		var body := PackedVector2Array()
		for i in 16:
			var a := TAU * i / 16.0
			body.append(c + Vector2(cos(a) * w * 0.8, sin(a) * h))
		canvas.draw_colored_polygon(body, edge)
		canvas.draw_colored_polygon(_scaled(body, c, 0.88), top)
		canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.7, 0), c + Vector2(w, -h),
			c + Vector2(w, h)]), top.darkened(0.15))
		canvas.draw_circle(c + Vector2(-w * 0.55, -h * 0.2), maxf(h * 0.15, 0.8), Color(0.1, 0.1, 0.1))
	elif fish_id == "tom":  # shrimp: curled segments + tail fan
		for i in 7:
			var a := PI * 0.15 + PI * 1.1 * i / 6.0
			var p := c + Vector2(cos(a) * w * 0.6, sin(a) * h * 0.9)
			canvas.draw_circle(p, h * 0.42 + 1.0, edge)
			canvas.draw_circle(p, h * 0.36 + 0.5, top)
		canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.55, -h * 0.4), c + Vector2(w, -h),
			c + Vector2(w, h * 0.2)]), top.darkened(0.15))
	elif fish_id == "muc":  # squid: mantle, fins, tentacles
		canvas.draw_rect(Rect2(c + Vector2(-w * 0.8, -h * 0.55), Vector2(w * 1.1, h * 1.1)), edge)
		canvas.draw_rect(Rect2(c + Vector2(-w * 0.75, -h * 0.45), Vector2(w, h * 0.9)), top)
		canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.8, 0), c + Vector2(-w, -h),
			c + Vector2(-w, h)]), top.darkened(0.1))
		for k in 4:
			var y := c.y + (k - 1.5) * h * 0.3
			canvas.draw_line(Vector2(c.x + w * 0.3, y), Vector2(c.x + w, y + sin(k * 1.3) * h * 0.2), top.darkened(0.2), 1.5)
	else:  # snails / anything else: a few round shells
		for k in 3:
			var p := c + Vector2((k - 1) * w * 0.6, 0)
			canvas.draw_circle(p, h * 0.75 + 1.0, edge)
			canvas.draw_circle(p, h * 0.65 + 0.5, top)
			canvas.draw_arc(p, h * 0.35 + 0.5, 0.0, TAU * 0.8, 10, top.darkened(0.3), 1.0)
	if marks and squash > 0.5:  # char lines from the grate on a cooked side
		for k in 3:
			var x := c.x + (k - 1) * w * 0.4
			canvas.draw_line(Vector2(x - 2, c.y - h * 0.6), Vector2(x + 2, c.y + h * 0.6), Color(0.15, 0.08, 0.05, 0.7), 1.5)


static func _scaled(points: PackedVector2Array, center: Vector2, factor: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(center + (p - center) * factor)
	return result
