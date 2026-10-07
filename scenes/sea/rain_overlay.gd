class_name RainOverlay
extends Control
## Screen-space rain streaks (on its own CanvasLayer, so the night tint
## doesn't hide it). Shown by WeatherController on rainy nights.

@export var drop_count: int = 90
@export var fall_speed: float = 260.0
@export var slant: Vector2 = Vector2(-0.25, 1.0)
@export var drop_length: float = 7.0
@export var color: Color = Color(0.7, 0.8, 1.0, 0.35)

var _drops: PackedVector2Array = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	for i in drop_count:
		_drops.append(Vector2(_rng.randf() * 640.0, _rng.randf() * 360.0))


func _process(delta: float) -> void:
	if not visible:
		return
	var view := get_viewport_rect().size
	var step := slant.normalized() * fall_speed * delta
	for i in _drops.size():
		var drop := _drops[i] + step
		if drop.y > view.y:
			drop = Vector2(_rng.randf() * (view.x + 100.0), -drop_length)
		_drops[i] = drop
	queue_redraw()


func _draw() -> void:
	var tail := slant.normalized() * drop_length
	for drop in _drops:
		draw_line(drop, drop - tail, color, 1.0)
