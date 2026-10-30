class_name EarnSparkline
extends Control
## Tiny pixel line chart of Rin's earned per day (oldest -> today): a stepped
## 2 px red line with square dots, today's dot bigger. `play()` draws it in.

var values: Array[int] = []
var grow: float = 1.0:
	set(value):
		grow = value
		queue_redraw()


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(90, 26)


func set_values(daily: Array[int]) -> void:
	values = daily
	queue_redraw()


func play(delay: float = 0.0) -> void:
	grow = 0.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "grow", 1.0, 0.6).set_delay(delay)


func _draw() -> void:
	draw_rect(Rect2(0, size.y - 2.0, size.x, 2.0), SocialStyle.MUTED)  # baseline
	if values.size() < 2:
		return
	var top := 1
	for value in values:
		top = maxi(top, value)
	var points: Array[Vector2] = []
	for i in values.size():
		var x := roundf(3.0 + (size.x - 8.0) * i / (values.size() - 1))
		var y := roundf(size.y - 5.0 - (size.y - 9.0) * float(values[i]) / top)
		points.append(Vector2(x, y))
	var shown := maxi(roundi(grow * (points.size() - 1)), 0)
	for i in shown:
		var a := points[i]
		var b := points[i + 1]
		# Stepped pixel line: across, then up/down.
		draw_rect(Rect2(a.x, a.y, b.x - a.x, 2.0), SocialStyle.SIGN_RED)
		draw_rect(Rect2(b.x, minf(a.y, b.y), 2.0, absf(b.y - a.y) + 2.0), SocialStyle.SIGN_RED)
	for i in shown + 1:
		var big := i == points.size() - 1
		var s := 5.0 if big else 3.0
		var dot := Rect2(points[i] - Vector2(s, s) * 0.5 + Vector2(1, 1), Vector2(s, s))
		draw_rect(dot.grow(1.0), SocialStyle.INK)
		draw_rect(dot, SocialStyle.GOLD if big else SocialStyle.SIGN_RED)
