class_name NeoScreenFx
extends Control
## Drawn over NEO's speech panel: faint CRT scanlines, a scan band rolling
## down, cyan HUD corner brackets and, for a moment after `play()`, glitch
## bars and a flicker (the panel blinks in like a machine screen). Red when
## NEO reports an error.

const CYAN := Color("5ff2e0")
const RED := Color("e0302b")
## Seconds of glitch after a new line.
const GLITCH_SECONDS := 0.28

var alarm: bool = false
var _time: float = 0.0
var _glitch: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## A new line: glitch bars and a flicker.
func play() -> void:
	_glitch = GLITCH_SECONDS


## Panel opacity for the blink-in (call from the owner's process).
func flicker() -> float:
	if _glitch <= 0.0:
		return 1.0
	return 0.35 if fmod(_glitch * 40.0, 2.0) < 0.7 else 1.0


func _process(delta: float) -> void:
	_time += delta
	_glitch = maxf(_glitch - delta, 0.0)
	if is_visible_in_tree():
		queue_redraw()


func _draw() -> void:
	var tint := RED if alarm else CYAN
	var rect := Rect2(Vector2(-4, -3), size + Vector2(8, 6))
	for y in range(int(rect.position.y), int(rect.end.y), 2):
		draw_rect(Rect2(rect.position.x, y, rect.size.x, 1), Color(0, 0, 0, 0.18))
	var band := rect.position.y + fmod(_time * 22.0, rect.size.y + 10.0) - 5.0
	draw_rect(Rect2(rect.position.x, band, rect.size.x, 2), Color(tint, 0.10))
	var arm := 5.0
	for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.position.x, rect.end.y), rect.end]:
		var sx := 1.0 if corner.x == rect.position.x else -1.0
		var sy := 1.0 if corner.y == rect.position.y else -1.0
		var at := corner + Vector2(-1.0 if sx < 0.0 else 0.0, -1.0 if sy < 0.0 else 0.0)
		draw_rect(Rect2(at, Vector2(arm * sx, 1)).abs(), Color(tint, 0.9))
		draw_rect(Rect2(at, Vector2(1, arm * sy)).abs(), Color(tint, 0.9))
	if _glitch > 0.0:
		for i in 3:
			var y := rect.position.y + fmod(_time * 157.0 + i * 37.0, rect.size.y)
			var shift := sin(_time * 90.0 + i) * 6.0
			draw_rect(Rect2(rect.position.x + shift, y, rect.size.x * (0.4 + 0.2 * i), 1), Color(tint, 0.45))
