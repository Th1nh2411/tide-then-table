class_name NeoAvatar
extends Control
## NEO, the assistant in Rin's Catch, as a little hologram (JARVIS style):
## a pulsing ring, a slowly turning arc and a voice wave while it talks.
## Art "ui/neo" replaces it when it exists.

@export var color: Color = Color(0.35, 0.95, 1.0)
## Seconds the voice wave moves after `speak()`.
@export var talk_seconds: float = 1.2

## Red while reporting errors ([WARN] / [ERR]).
var alarm: bool = false

var _time: float = 0.0
var _talk_left: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(22, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func speak() -> void:
	_talk_left = talk_seconds


func _process(delta: float) -> void:
	_time += delta
	_talk_left = maxf(_talk_left - delta, 0.0)
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if Art.draw(self, "ui/neo", rect):
		return
	var c := rect.get_center()
	var r := minf(size.x, size.y) * 0.5 - 1.0
	var tint := Color(1.0, 0.35, 0.3) if alarm else color
	draw_circle(c, r, Color(tint, 0.12))
	draw_arc(c, r, 0.0, TAU, 24, Color(tint, 0.5 + 0.3 * sin(_time * 3.0)), 1.0)
	draw_arc(c, r - 3.0, _time * 2.0, _time * 2.0 + PI * 1.2, 12, tint, 1.5)
	# Voice wave: 5 bars, tall while talking, a flat line when quiet.
	for i in 5:
		var x := c.x + (i - 2) * 2.5
		var h := 1.0
		if _talk_left > 0.0:
			h = 1.0 + absf(sin(_time * 14.0 + i * 1.3)) * 4.0 * minf(_talk_left * 3.0, 1.0)
		draw_line(Vector2(x, c.y - h), Vector2(x, c.y + h), tint, 1.0)
