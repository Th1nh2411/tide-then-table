class_name MiniChart
extends Control
## Tiny bar / line chart drawn in code, grows in when values change.
## `chart.set_values([120.0, 80.0], ["Cua", "Tôm"])`; labels may be empty.
## Used by the menu panel (takings per dish), later the scoreboard / social tab.

enum Mode { BAR, LINE }

const INK := Color("090a14")

@export var mode: Mode = Mode.BAR
@export var bar_color: Color = Color("e8c170")
@export var highlight_color: Color = Color("cf573c")
@export var label_color: Color = Color(0.91, 0.84, 0.7, 0.8)
@export var font_size: int = 8
## Fixed top of the scale; 0 = the largest value.
@export var max_value: float = 0.0
## Index drawn in highlight_color (e.g. today's HOT dish), -1 = none.
var highlight: int = -1
var values: Array[float] = []
var labels: Array[String] = []
var _grow: float = 1.0
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_values(new_values: Array[float], new_labels: Array[String] = []) -> void:
	var same := new_values == values and new_labels == labels
	values = new_values.duplicate()
	labels = new_labels.duplicate()
	if same:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	_grow = 0.0
	_tween = create_tween()
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "_grow", 1.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(queue_redraw)


func _process(_delta: float) -> void:
	if _grow < 1.0 or (_tween and _tween.is_running()):
		queue_redraw()


func _draw() -> void:
	if values.is_empty():
		return
	var font := get_theme_font("font", "Label")
	var label_h := float(font_size) + 2.0 if not labels.is_empty() else 0.0
	var area := Rect2(Vector2.ZERO, Vector2(size.x, size.y - label_h))
	var largest: float = values.max()
	var top := max_value if max_value > 0.0 else largest
	top = maxf(top, 0.001)
	var step := area.size.x / values.size()
	draw_line(Vector2(0, area.end.y), Vector2(size.x, area.end.y), Color(label_color, 0.4), 1.0)
	var points := PackedVector2Array()
	for i in values.size():
		var h := area.size.y * clampf(values[i] / top, 0.0, 1.0) * _grow
		var color := highlight_color if i == highlight else bar_color
		var x := step * i
		if mode == Mode.BAR:
			var bar := Rect2(roundf(x + step * 0.18), roundf(area.end.y - h), roundf(step * 0.64), roundf(h))
			if bar.size.y >= 1.0:
				draw_rect(bar.grow(1.0), INK)  # pixel outline
				draw_rect(bar, color)
				draw_rect(Rect2(bar.position, Vector2(1, bar.size.y)), color.lightened(0.3))
		else:
			points.append(Vector2(x + step * 0.5, area.end.y - h))
		if i < labels.size() and labels[i] != "":
			draw_string(font, Vector2(x, size.y - 1.0), labels[i], HORIZONTAL_ALIGNMENT_CENTER, step,
				font_size, label_color)
	if mode == Mode.LINE and points.size() > 1:
		draw_polyline(points, bar_color, 1.0)
		for i in points.size():
			var dot := Rect2(points[i].round() - Vector2(2, 2), Vector2(4, 4))
			draw_rect(dot.grow(1.0), INK)
			draw_rect(dot, highlight_color if i == highlight else bar_color)
