class_name GrillGame
extends CookingGameBase
## Grill: a needle crosses the bar once per side. Press `cast` when it is in
## the "just cooked" zone. Two sides; both perfect = PERFECT, total score
## of at least 2 = OK, otherwise BURNT. Not pressing in time burns that side.
## Left of the bar the seafood sits big on the coals (GrillView): it drops
## onto the grate, the side underneath browns with the needle, and each
## press flips it so the side just grilled shows on top.

@export var bar_size: Vector2 = Vector2(240, 16)
## Seconds for the needle to cross the bar.
@export var side_seconds: float = 2.0
## Zones as (start, end) fractions of the bar.
@export var ok_zone: Vector2 = Vector2(0.55, 0.85)
@export var perfect_zone: Vector2 = Vector2(0.65, 0.75)
## Zones shift randomly by up to this much each side so it isn't rote.
@export var zone_jitter: float = 0.1
@export var sides: int = 2
## The grill picture left of the bar.
@export var view_size: Vector2 = Vector2(84, 60)
@export var flip_seconds: float = 0.2
@export var drop_seconds: float = 0.3
## Once Rin has Nhịp Sóng (WaveMark): dishes from this price grill faster
## with narrower zones.
@export var hard_from_price: int = 80
@export var hard_zone_scale: float = 0.7
@export var hard_speed_scale: float = 0.85

var _needle: float = 0.0
var _side: int = 0
var _scores: Array[int] = []
var _ok: Vector2
var _perfect: Vector2
var _rng := RandomNumberGenerator.new()
## Doneness of each side (0 raw .. 1 burnt); side `_side` is the one underneath.
var _done_by_side: Array[float] = []
var _flip_left: float = 0.0


func setup(p_dish: DishData) -> void:
	super(p_dish)
	_rng.randomize()
	if WaveMark.has_power() and dish.base_price >= hard_from_price:
		side_seconds *= hard_speed_scale
		ok_zone = _narrowed(ok_zone, hard_zone_scale)
		perfect_zone = _narrowed(perfect_zone, hard_zone_scale)
	custom_minimum_size = Vector2(view_size.x + 10 + bar_size.x, maxf(view_size.y, bar_size.y + 34))
	input_delay = maxf(input_delay, drop_seconds)  # it lands first
	_done_by_side.resize(sides)
	_done_by_side.fill(0.0)
	_start_side()


func get_hint() -> String:
	return "Space khi kim vào vùng xanh để lật · 2 mặt"


func get_status_text() -> String:
	return "Mặt %d/%d" % [mini(_side + 1, sides), sides]


func _update(delta: float) -> void:
	_flip_left = maxf(_flip_left - delta, 0.0)
	_needle += delta / side_seconds
	if _side < sides:
		_done_by_side[_side] = clampf(_needle, 0.0, 1.0)
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
	_flip_left = flip_seconds  # turn it over: this side comes up
	Sfx.play("flip")
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
	_draw_grill()
	var origin := Vector2(view_size.x + 10, floorf((size.y - bar_size.y) * 0.5) - 6)
	_draw_zone_bar(origin, bar_size, _ok, _perfect)
	var x := origin.x + clampf(_needle, 0.0, 1.0) * bar_size.x
	draw_rect(Rect2(x - 1, origin.y - 5, 2, bar_size.y + 10), Color.WHITE)
	# One marker per side: grey = pending, red/yellow/green = result.
	var colors := [Color(1, 0.3, 0.3), Color(0.85, 0.7, 0.25), Color(0.3, 0.85, 0.4)]
	for i in sides:
		var pos := Vector2(origin.x + bar_size.x * 0.5 + (i - (sides - 1) * 0.5) * 16, origin.y + bar_size.y + 14)
		draw_circle(pos, 5, colors[_scores[i]] if i < _scores.size() else Color(1, 1, 1, 0.25))


## The seafood on the coals: the top shows the last side grilled (or raw
## before the first flip), the rim shows the side cooking underneath.
func _draw_grill() -> void:
	var fish_id: String = dish.ingredients.keys()[0] if not dish.ingredients.is_empty() else ""
	var cooking := mini(_side, sides - 1)
	var shown := _side - 1  # the side that came up at the last flip
	var progress := 1.0 - _flip_left / flip_seconds
	if _flip_left > 0.0 and progress < 0.5:
		shown -= 1  # still turning: the old top until halfway
	var top := GrillView.RAW if shown < 0 else GrillView.cooked_color(_done_by_side[shown], _ok)
	var edge := GrillView.cooked_color(_done_by_side[cooking], _ok)
	var flip := cos(progress * PI) if _flip_left > 0.0 else 1.0
	var drop := clampf(1.0 - _time / drop_seconds, 0.0, 1.0)
	var smoke := clampf((_needle - _ok.x) / maxf(1.0 - _ok.x, 0.01), 0.0, 1.0) if _side < sides else 0.0
	var rect := Rect2(Vector2(0, floorf((size.y - view_size.y) * 0.5)), view_size)
	GrillView.draw(self, rect, fish_id, top, edge, flip, drop * drop, smoke, _time, shown >= 0)


static func _narrowed(zone: Vector2, factor: float) -> Vector2:
	var middle := (zone.x + zone.y) * 0.5
	var half := (zone.y - zone.x) * 0.5 * factor
	return Vector2(middle - half, middle + half)
