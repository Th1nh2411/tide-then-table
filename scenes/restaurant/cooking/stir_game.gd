class_name StirGame
extends CookingGameBase
## Stir-fry: mash `cast` to fill the bar before time runs out (it slowly
## drains). Filled quickly = PERFECT, filled in time = OK, too slow = BURNT.

@export var bar_size: Vector2 = Vector2(240, 16)
@export var time_limit: float = 5.0
## Fill gained per press.
@export var per_press: float = 0.1
## Fill lost per second.
@export var drain_per_second: float = 0.1
## Finish within this fraction of time_limit for PERFECT.
@export var perfect_time_ratio: float = 0.6

var _fill: float = 0.0
var _elapsed: float = 0.0


func setup(p_dish: DishData) -> void:
	super(p_dish)
	custom_minimum_size = bar_size + Vector2(20, 40)


func get_hint() -> String:
	return "Bấm Space liên tục: đảo cho đầy"


func get_status_text() -> String:
	return "Còn %.1f giây" % maxf(time_limit - _elapsed, 0.0)


func _update(delta: float) -> void:
	if not _accepts_input():
		return
	_elapsed += delta
	if Input.is_action_just_pressed("cast"):
		_fill += per_press
	_fill = maxf(_fill - drain_per_second * delta, 0.0)
	if _fill >= 1.0:
		_finish(Result.PERFECT if _elapsed <= time_limit * perfect_time_ratio else Result.OK)
	elif _elapsed >= time_limit:
		_finish(Result.BURNT)


func _draw() -> void:
	var origin := _centered_origin(bar_size)
	draw_rect(Rect2(origin, bar_size), Color(0.12, 0.12, 0.18))
	var color := Color(0.3, 0.85, 0.4) if _elapsed <= time_limit * perfect_time_ratio else Color(0.85, 0.7, 0.25)
	draw_rect(Rect2(origin, Vector2(clampf(_fill, 0.0, 1.0) * bar_size.x, bar_size.y)), color)
	draw_rect(Rect2(origin, bar_size), Color(1, 1, 1, 0.6), false, 1.0)
	# Time remaining as a thin bar underneath.
	var time_left := clampf(1.0 - _elapsed / time_limit, 0.0, 1.0)
	draw_rect(Rect2(origin + Vector2(0, bar_size.y + 6), Vector2(time_left * bar_size.x, 3)), Color(1, 1, 1, 0.6))
