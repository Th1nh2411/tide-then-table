class_name CookingGameBase
extends Control
## Shared parts of the cooking minigames: setup, result signal, update loop
## and a short input delay so the click that opened the game doesn't count.

enum Result { BURNT, OK, PERFECT }

signal completed(result: Result)

## Seconds to ignore `cast` after the game opens.
@export var input_delay: float = 0.25

var dish: DishData
## Game speed (< 1 = slower = easier). Set from the kitchen upgrade.
var time_scale: float = 1.0

var _done: bool = false
var _time: float = 0.0


func setup(p_dish: DishData) -> void:
	dish = p_dish


func _process(delta: float) -> void:
	if _done or dish == null:
		return
	var scaled := delta * time_scale
	_time += scaled
	_update(scaled)
	queue_redraw()


## Per-frame game logic. Override in subclasses.
func _update(_delta: float) -> void:
	pass


func get_hint() -> String:
	return ""


func get_status_text() -> String:
	return ""


func _accepts_input() -> bool:
	return _time >= input_delay


func _finish(result: Result) -> void:
	if _done:
		return
	_done = true
	completed.emit(result)


func _centered_origin(area_size: Vector2) -> Vector2:
	return ((size - area_size) * 0.5).floor()


## Horizontal bar with an "ok" band and a narrower "perfect" band inside it.
func _draw_zone_bar(origin: Vector2, bar_size: Vector2, ok: Vector2, perfect: Vector2) -> void:
	draw_rect(Rect2(origin, bar_size), Color(0.12, 0.12, 0.18))
	draw_rect(Rect2(origin + Vector2(ok.x * bar_size.x, 0), Vector2((ok.y - ok.x) * bar_size.x, bar_size.y)), Color(0.85, 0.7, 0.25))
	draw_rect(Rect2(origin + Vector2(perfect.x * bar_size.x, 0), Vector2((perfect.y - perfect.x) * bar_size.x, bar_size.y)), Color(0.3, 0.85, 0.4))
	draw_rect(Rect2(origin, bar_size), Color(1, 1, 1, 0.6), false, 1.0)


## PERFECT inside `perfect`, OK inside `ok`, otherwise BURNT. Ranges are (start, end).
static func judge(value: float, ok: Vector2, perfect: Vector2) -> Result:
	if value >= perfect.x and value <= perfect.y:
		return Result.PERFECT
	if value >= ok.x and value <= ok.y:
		return Result.OK
	return Result.BURNT
