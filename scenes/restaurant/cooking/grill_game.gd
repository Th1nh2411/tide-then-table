class_name GrillGame
extends CookingGameBase
## Grill: a needle crosses the bar once per side. Press `cast` when it is in
## the "just cooked" zone. Two sides; both perfect = PERFECT, total score
## of at least 2 = OK, otherwise BURNT. Not pressing in time burns that side.

@export var bar_size: Vector2 = Vector2(240, 16)
## Seconds for the needle to cross the bar.
@export var side_seconds: float = 2.0
## Zones as (start, end) fractions of the bar.
@export var ok_zone: Vector2 = Vector2(0.55, 0.85)
@export var perfect_zone: Vector2 = Vector2(0.65, 0.75)
## Zones shift randomly by up to this much each side so it isn't rote.
@export var zone_jitter: float = 0.1
@export var sides: int = 2

var _needle: float = 0.0
var _side: int = 0
var _scores: Array[int] = []
var _ok: Vector2
var _perfect: Vector2
var _rng := RandomNumberGenerator.new()


func setup(p_dish: DishData) -> void:
	super(p_dish)
	_rng.randomize()
	custom_minimum_size = bar_size + Vector2(20, 40)
	_start_side()


func get_hint() -> String:
	return "Space / chuột trái khi kim vào vùng xanh (chín tới) — 2 mặt"


func get_status_text() -> String:
	return "Mặt %d/%d" % [mini(_side + 1, sides), sides]


func _update(delta: float) -> void:
	_needle += delta / side_seconds
	if _accepts_input() and Input.is_action_just_pressed("cast"):
		_end_side(CookingGameBase.judge(_needle, _ok, _perfect))
	elif _needle >= 1.0:
		_end_side(Result.BURNT)


func _start_side() -> void:
	_needle = 0.0
	var shift := _rng.randf_range(-zone_jitter, zone_jitter)
	_ok = ok_zone + Vector2(shift, shift)
	_perfect = perfect_zone + Vector2(shift, shift)


func _end_side(side_result: Result) -> void:
	_scores.append(int(side_result))  # BURNT=0, OK=1, PERFECT=2
	_side += 1
	if _side < sides:
		_start_side()
		return
	var total := 0
	for s in _scores:
		total += s
	if total == sides * 2:
		_finish(Result.PERFECT)
	elif total >= sides:
		_finish(Result.OK)
	else:
		_finish(Result.BURNT)


func _draw() -> void:
	var origin := _centered_origin(bar_size)
	_draw_zone_bar(origin, bar_size, _ok, _perfect)
	var x := origin.x + clampf(_needle, 0.0, 1.0) * bar_size.x
	draw_rect(Rect2(x - 1, origin.y - 5, 2, bar_size.y + 10), Color.WHITE)
	# One marker per side: grey = pending, red/yellow/green = result.
	var colors := [Color(1, 0.3, 0.3), Color(0.85, 0.7, 0.25), Color(0.3, 0.85, 0.4)]
	for i in sides:
		var pos := Vector2(size.x * 0.5 + (i - (sides - 1) * 0.5) * 16, origin.y + bar_size.y + 14)
		draw_circle(pos, 5, colors[_scores[i]] if i < _scores.size() else Color(1, 1, 1, 0.25))
