class_name PipBar
extends Control
## A row of small dots for a count (servings, stock): filled up to `value`,
## hollow up to `capacity`. Past `max_pips` it becomes a filled bar.
## New dots pop in when the value grows.

const INK := Color("090a14")

@export var pip_color: Color = Color("f2d98a")
@export var empty_color: Color = Color(0.91, 0.84, 0.7, 0.25)
@export var max_pips: int = 10
@export var pip_size: float = 4.0
@export var gap: float = 2.0
var value: int = 0
var capacity: int = 0
var _pop: float = 1.0  # 0..1 growth of the newest dot
var _tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fit()


func set_count(new_value: int, new_capacity: int = -1) -> void:
	var grew := new_value > value
	value = maxi(new_value, 0)
	capacity = maxi(new_capacity, value) if new_capacity >= 0 else value
	_fit()
	if grew and is_inside_tree():
		if _tween and _tween.is_valid():
			_tween.kill()
		_pop = 0.0
		_tween = create_tween()
		_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_tween.tween_method(func(v: float) -> void:
			_pop = v
			queue_redraw(), 0.0, 1.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _fit() -> void:
	var shown := mini(maxi(capacity, 1), max_pips)
	custom_minimum_size = Vector2(shown * (pip_size + gap) - gap + 2.0, pip_size + 2.0)


func _draw() -> void:
	var y := size.y * 0.5
	if capacity > max_pips:
		# Too many for dots: a bar with the filled share.
		var width := size.x
		draw_rect(Rect2(0, y - pip_size * 0.5, width, pip_size).grow(1.0), INK)
		draw_rect(Rect2(0, y - pip_size * 0.5, width, pip_size), empty_color)
		draw_rect(Rect2(0, y - pip_size * 0.5, width * float(value) / capacity, pip_size), pip_color)
		return
	# Square pixel pips with an ink outline (filled) or a hollow box (empty).
	for i in capacity:
		var cell := Rect2(1.0 + i * (pip_size + gap), roundf(y - pip_size * 0.5), pip_size, pip_size)
		if i < value:
			var grow := _pop if i == value - 1 else 1.0
			var r := Rect2(cell.get_center() - cell.size * grow * 0.5, cell.size * grow)
			draw_rect(r.grow(1.0), INK)
			draw_rect(r, pip_color)
		else:
			draw_rect(cell, empty_color, false, 1.0)
