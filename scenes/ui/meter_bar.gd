class_name MeterBar
extends Control
## Small pixel meter (lamp oil, hull, hold, a guest's patience): 1 px ink
## outline, dark well, flat fill with a 1 px highlight. Below `low` it turns
## `low_color` and blinks. Eases to new values. Drawn in code; final art can
## replace it with assets/sprites/ui/frames/meter_<style>.png (via Art).

const INK := Color("090a14")

@export var color: Color = Color("de9e41")
@export var low_color: Color = Color("cf573c")
@export var well: Color = Color("151d28")
## Fraction under which the meter warns (0 = never).
@export var low: float = 0.25
## > 0: ink notches dividing the bar (2 nets, 4 hull plates...).
@export var segments: int = 0
## Art name under ui/frames/ for the empty meter (drawn under the fill).
@export var art: String = ""
var value: float = 1.0
var _shown: float = 1.0
var _blink: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(28, 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_value(fraction: float, instant: bool = false) -> void:
	value = clampf(fraction, 0.0, 1.0)
	if instant:
		_shown = value
	queue_redraw()


func _process(delta: float) -> void:
	if absf(_shown - value) > 0.002:
		_shown = move_toward(_shown, value, delta * 1.2)
		queue_redraw()
	elif value < low:
		_blink += delta
		queue_redraw()


func _draw() -> void:
	var outer := Rect2(Vector2.ZERO, size.floor())
	var inner := outer.grow(-1.0)
	if art == "" or not Art.draw(self, "ui/frames/" + art, outer):
		draw_rect(outer, INK)
		draw_rect(inner, well)
	var fill := color
	if value < low:
		fill = low_color if fmod(_blink, 0.8) < 0.5 else low_color.darkened(0.35)
	var w := roundf(inner.size.x * _shown)
	if w >= 1.0:
		draw_rect(Rect2(inner.position, Vector2(w, inner.size.y)), fill)
		draw_rect(Rect2(inner.position, Vector2(w, 1.0)), fill.lightened(0.35))
	for i in range(1, segments):
		var x := roundf(inner.position.x + inner.size.x * float(i) / segments)
		draw_rect(Rect2(x, inner.position.y, 1.0, inner.size.y), INK)
