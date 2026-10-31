class_name StaminaBar3D
extends CanvasLayer
## Rin's stamina over his head while he runs (Shift); hides once it is full.
## Follows a 3D point through the camera, drawn in screen pixels.

const SIZE := Vector2(22, 4)
const HEAD_HEIGHT := 2.05
const INK := Color("090a14")
const BACK := Color("202e37")
const FULL := Color("a8ca58")
const LOW := Color("de9e41")
const EMPTY := Color("a53030")

var _bar := Control.new()
var _value: float = 1.0


func _init() -> void:
	layer = 5
	_bar.size = SIZE + Vector2(2, 2)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	visible = false


## value 0..1; full hides the bar.
func show_at(camera: Camera3D, head: Vector3, value: float) -> void:
	_value = value
	var point := head + Vector3.UP * HEAD_HEIGHT
	visible = value < 0.999 and camera != null and not camera.is_position_behind(point)
	if not visible:
		return
	var screen := camera.unproject_position(point)
	_bar.position = (screen - _bar.size * 0.5).round()
	_bar.queue_redraw()


func _draw_bar() -> void:
	_bar.draw_rect(Rect2(Vector2.ZERO, _bar.size), INK)
	_bar.draw_rect(Rect2(Vector2.ONE, SIZE), BACK)
	var colour := FULL if _value > 0.5 else LOW if _value > 0.2 else EMPTY
	_bar.draw_rect(Rect2(Vector2.ONE, Vector2(roundf(SIZE.x * _value), SIZE.y)), colour)
