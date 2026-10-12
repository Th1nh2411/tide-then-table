class_name FishPortrait
extends Control
## A picture of one species, side view (fish / shrimp / squid / snail / crab
## drawn in code, or its Art "fish/<id>" image). `silhouette` 0..1 blends it
## to a black shadow; `mystery` adds a big "?" in the middle (a species not
## in the Dex yet). Used by the fishing minigame and the new-species card.

@export var shadow_color: Color = Color(0.03, 0.04, 0.07)

var fish: FishData
var silhouette: float = 0.0
var mystery: bool = false
## White glow while revealing (0..1).
var flash: float = 0.0

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	if fish == null:
		return
	var rect := Rect2(Vector2.ZERO, size).grow(-2)
	if flash > 0.0:
		draw_circle(rect.get_center(), rect.size.y * (0.4 + flash * 0.4), Color(1, 1, 1, flash * 0.4))
	var color := fish.color.lerp(shadow_color, silhouette)
	if not _draw_art(rect, color):
		draw_shape(self, fish.id, rect, color, Color(color.darkened(0.3), 1.0))
	if fish.is_aberrant and silhouette < 0.5:  # it glows a little
		draw_circle(rect.get_center(), rect.size.y * 0.45, Color(0.5, 1.0, 0.9, 0.12 + 0.08 * sin(_time * 3.0)))
	if mystery:
		var font := ThemeDB.fallback_font
		var font_size := int(rect.size.y * 0.55)
		var text_size := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var at := rect.get_center() + Vector2(-text_size.x * 0.5, font_size * 0.35)
		var bob := sin(_time * 3.0) * 1.5
		draw_string_outline(font, at + Vector2(0, bob), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color.BLACK)
		draw_string(font, at + Vector2(0, bob), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1, 0.9, 0.5))


## The hold picture (Art "fish/<id>"), fitted into `rect` keeping its shape.
func _draw_art(rect: Rect2, color: Color) -> bool:
	var tex := Art.texture("fish/" + fish.id)
	if tex == null:
		return false
	var scale := minf(rect.size.x / tex.get_width(), rect.size.y / tex.get_height())
	var fit := Vector2(tex.get_size()) * scale
	var tint := Color.WHITE.lerp(shadow_color, silhouette)
	draw_texture_rect(tex, Rect2(rect.get_center() - fit * 0.5, fit), false, tint if silhouette > 0.0 else Color.WHITE)
	return true


## Code drawing of a species in `r` (head to the left), filled with `body`.
static func draw_shape(canvas: CanvasItem, fish_id: String, r: Rect2, body: Color, dark: Color) -> void:
	var c := r.get_center()
	var w := r.size.x * 0.5
	var h := r.size.y * 0.5
	match fish_id:
		"tom":  # curled shrimp: segments, tail fan, feelers
			for i in 8:
				var a := PI * 0.1 + PI * 1.15 * i / 7.0
				canvas.draw_circle(c + Vector2(cos(a) * w * 0.55, sin(a) * h * 0.7 - h * 0.1), h * 0.28, body)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.5, -h * 0.4), c + Vector2(w * 0.95, -h * 0.85),
				c + Vector2(w * 0.95, h * 0.05)]), dark)
			canvas.draw_line(c + Vector2(-w * 0.55, -h * 0.2), c + Vector2(-w * 0.95, -h * 0.9), dark, 1.0)
		"muc":  # squid: mantle, fins, tentacles
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.95, 0), c + Vector2(w * 0.1, -h * 0.45),
				c + Vector2(-w * 0.25, -h * 0.35), c + Vector2(-w * 0.25, h * 0.35), c + Vector2(w * 0.1, h * 0.45)]), body)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.6, 0), c + Vector2(w * 0.95, -h * 0.6),
				c + Vector2(w * 0.95, h * 0.6)]), dark)
			for k in 5:
				var y := c.y + (k - 2) * h * 0.18
				canvas.draw_line(Vector2(c.x - w * 0.25, y), Vector2(c.x - w * 0.95, y + sin(k * 1.7) * h * 0.25), body, 2.0)
			canvas.draw_circle(c + Vector2(-w * 0.15, -h * 0.12), maxf(h * 0.09, 1.0), Color.BLACK)
		"oc_huong":  # spiral shell
			canvas.draw_circle(c, h * 0.75, body)
			for k in 3:
				canvas.draw_arc(c + Vector2(k * h * 0.08, 0), h * (0.6 - k * 0.18), 0.0, TAU * 0.85, 16, dark, 2.0)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(h * 0.5, h * 0.4), c + Vector2(w * 0.9, h * 0.7),
				c + Vector2(h * 0.2, h * 0.75)]), body)
		"cua":  # crab: shell, claws, legs
			for k in 3:
				for side: float in [-1.0, 1.0]:
					canvas.draw_line(c + Vector2(side * w * 0.3, (k - 1) * h * 0.25), c + Vector2(side * w * 0.85,
						(k - 1) * h * 0.35 + h * 0.3), dark, 2.0)
			canvas.draw_circle(c + Vector2(-w * 0.6, -h * 0.55), h * 0.25, body)
			canvas.draw_circle(c + Vector2(w * 0.6, -h * 0.55), h * 0.25, body)
			var shell := PackedVector2Array()
			for i in 16:
				var a := TAU * i / 16.0
				shell.append(c + Vector2(cos(a) * w * 0.5, sin(a) * h * 0.55))
			canvas.draw_colored_polygon(shell, body)
		_:  # fish: body, tail, fin, eye
			var outline := PackedVector2Array()
			for i in 20:
				var a := TAU * i / 20.0
				outline.append(c + Vector2(cos(a) * w * 0.68 - w * 0.12, sin(a) * h * 0.55))
			canvas.draw_colored_polygon(outline, body)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(w * 0.5, 0), c + Vector2(w * 0.95, -h * 0.6),
				c + Vector2(w * 0.95, h * 0.6)]), dark)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-w * 0.1, -h * 0.5), c + Vector2(w * 0.25, -h * 0.85),
				c + Vector2(w * 0.3, -h * 0.45)]), dark)
			canvas.draw_circle(c + Vector2(-w * 0.55, -h * 0.12), maxf(h * 0.1, 1.0), Color.BLACK)
