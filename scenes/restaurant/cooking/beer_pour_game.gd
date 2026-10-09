class_name BeerPourGame
extends CookingGameBase
## Beer tower: hold `cast` to pour, the beer rises with a foam head on top.
## A long pour gets foamier and foamier; letting go makes the foam settle
## (a bit of it turns back into beer), so short bursts keep the head thin.
## Letting go with the top in the band ends the pour: in the green band with
## a thin head = PERFECT, otherwise OK. Letting go lower is just a pause.
## Over the rim = `spilled` (the kitchen takes some beer away) and the tower
## starts empty again. Time out = judged as is (short = BURNT, "vơi").

signal spilled

@export var tower_size: Vector2 = Vector2(22, 54)
## Fractions of the tower height per second.
@export var fill_rate: float = 0.35
@export var foam_growth: float = 0.06
## Extra foam per second for every second the tap stays open.
@export var foam_ramp: float = 0.15
@export var foam_settle: float = 0.25
## Share of the settled foam that turns back into beer.
@export var settle_to_beer: float = 0.3
@export var max_foam: float = 0.3
## Where the top (beer + foam) must stop, as (low, high) fractions.
@export var ok_zone: Vector2 = Vector2(0.78, 1.0)
@export var perfect_zone: Vector2 = Vector2(0.86, 0.96)
## Thickest head that still counts as perfect.
@export var perfect_max_foam: float = 0.14
@export var time_limit: float = 10.0

var spills: int = 0

var _beer: float = 0.0
var _foam: float = 0.0
var _hold: float = 0.0  # seconds the tap has been open in this burst
var _elapsed: float = 0.0
var _flash: float = 0.0  # "spilled" flash


func setup(p_dish: DishData) -> void:
	super(p_dish)
	custom_minimum_size = Vector2(120, tower_size.y + 8)


func get_hint() -> String:
	return "Giữ Space / chuột trái để rót, nhả từng nhịp cho ít bọt, nhả hẳn khi bọt chạm vạch xanh"


func get_status_text() -> String:
	if _flash > 0.0:
		return "Tràn rồi! Rót lại"
	if _foam > perfect_max_foam:
		return "Bọt nhiều quá"
	return ""


func top() -> float:
	return _beer + _foam


func foam() -> float:
	return _foam


## Pure judgement of a finished pour (also used by the test bot).
func judge_pour(top_level: float, foam_level: float) -> Result:
	if top_level >= perfect_zone.x and top_level <= perfect_zone.y and foam_level <= perfect_max_foam:
		return Result.PERFECT
	if top_level >= ok_zone.x and top_level <= ok_zone.y:
		return Result.OK
	return Result.BURNT


func _update(delta: float) -> void:
	_elapsed += delta
	_flash = maxf(_flash - delta, 0.0)
	if _accepts_input() and _pouring():
		_hold += delta
		_beer += fill_rate * delta
		_foam = minf(_foam + (foam_growth + foam_ramp * _hold) * delta, max_foam)
		if top() > 1.0:
			_spill()
	else:
		if _hold > 0.0 and top() >= ok_zone.x:
			_finish(judge_pour(top(), _foam))
			return
		_hold = 0.0
		var settled := minf(_foam, foam_settle * delta)
		_foam -= settled
		_beer += settled * settle_to_beer
	if _elapsed >= time_limit:
		_finish(judge_pour(top(), _foam))


## Overridable by the test bot.
func _pouring() -> bool:
	return Input.is_action_pressed("cast") and not get_viewport().gui_get_hovered_control() is BaseButton


func _spill() -> void:
	spills += 1
	_beer = 0.0
	_foam = 0.0
	_hold = 0.0
	_elapsed = 0.0
	_flash = 0.8
	spilled.emit()


func _draw() -> void:
	var origin := _centered_origin(tower_size) + Vector2(-10, 3)
	var glass := Rect2(origin, tower_size)
	var h := tower_size.y
	# Bands on the right: yellow = ok, green = perfect.
	var band_x := glass.end.x + 3
	draw_rect(Rect2(band_x, origin.y + (1.0 - ok_zone.y) * h, 4, (ok_zone.y - ok_zone.x) * h), Color(0.85, 0.7, 0.25))
	draw_rect(Rect2(band_x, origin.y + (1.0 - perfect_zone.y) * h, 4, (perfect_zone.y - perfect_zone.x) * h),
		Color(0.3, 0.85, 0.4))
	# Glass, beer, foam, the ice tube in the middle.
	draw_rect(glass, Color(0.75, 0.85, 0.95, 0.15))
	var beer_h := minf(_beer, 1.0) * h
	draw_rect(Rect2(origin.x, glass.end.y - beer_h, tower_size.x, beer_h), Color(0.95, 0.68, 0.15))
	var foam_h := minf(_foam, 1.0 - minf(_beer, 1.0)) * h
	draw_rect(Rect2(origin.x, glass.end.y - beer_h - foam_h, tower_size.x, foam_h), Color(1.0, 0.97, 0.88))
	draw_rect(Rect2(origin.x + tower_size.x * 0.5 - 2, origin.y + 4, 4, h - 4), Color(0.8, 0.95, 1.0, 0.45))
	draw_rect(glass, Color(1, 1, 1, 0.7), false, 1.0)
	# Perfect line across the glass.
	var line_y := origin.y + (1.0 - (perfect_zone.x + perfect_zone.y) * 0.5) * h
	draw_line(Vector2(origin.x - 2, line_y), Vector2(glass.end.x + 2, line_y), Color(0.3, 0.85, 0.4, 0.8), 1.0)
	# Tap and stream.
	var spout := Vector2(origin.x + 4, origin.y - 3)
	draw_rect(Rect2(spout.x - 2, spout.y - 2, 8, 3), Color(0.7, 0.7, 0.75))
	if _hold > 0.0:
		draw_line(spout + Vector2(1, 1), Vector2(spout.x + 1, glass.end.y - beer_h - foam_h), Color(0.95, 0.68, 0.15), 2.0)
	if _flash > 0.0:  # drips over the rim
		for k in 3:
			var drip := Vector2(origin.x - 3 + k * 13, origin.y + (0.8 - _flash) * 40.0)
			draw_circle(drip, 1.5, Color(0.95, 0.68, 0.15, _flash))
