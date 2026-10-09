class_name TimingGame
extends MinigameBase
## A needle sweeps back and forth across a bar. Press `cast` while it is
## inside the green zone. Enough hits = caught; too many misses = fish escapes.

@export var bar_size: Vector2 = Vector2(240, 16)
## Needle speed in bar widths per second at difficulty 0 and 1.
@export var easy_needle_speed: float = 0.6
@export var hard_needle_speed: float = 1.8
## Green zone width as a fraction of the bar at difficulty 0 and 1.
@export var easy_zone_width: float = 0.25
@export var hard_zone_width: float = 0.08
## At or above this difficulty, 3 hits are needed instead of 2.
@export var three_hit_difficulty: float = 0.5
@export var max_misses: int = 2
@export var flash_seconds: float = 0.25

var _needle: float = 0.0
var _direction: float = 1.0
var _speed: float = 1.0
var _zone_start: float = 0.0
var _zone_width: float = 0.2
var _hits: int = 0
var _hits_needed: int = 2
var _misses: int = 0
var _flash_color: Color = Color.TRANSPARENT
var _flash_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	_rng.randomize()
	var d := fish.difficulty
	_speed = lerpf(easy_needle_speed, hard_needle_speed, d)
	_zone_width = clampf(lerpf(easy_zone_width, hard_zone_width, d) * zone_scale, 0.03, 0.9)
	_hits_needed = 3 if d >= three_hit_difficulty else 2
	custom_minimum_size = bar_size + Vector2(20, 40)
	_move_zone()


func get_hint() -> String:
	return "Space khi kim vào vùng xanh"


func get_status_text() -> String:
	return "Trúng %d/%d    Trượt %d/%d" % [_hits, _hits_needed, _misses, max_misses]


func _update(delta: float) -> void:
	_flash_left -= delta
	_needle += _direction * _speed * delta
	if _needle >= 1.0:
		_needle = 1.0
		_direction = -1.0
	elif _needle <= 0.0:
		_needle = 0.0
		_direction = 1.0
	if _cast_just_pressed():
		_on_cast()


func _on_cast() -> void:
	var inside := _needle >= _zone_start and _needle <= _zone_start + _zone_width
	if inside:
		_hits += 1
		_flash(Color(0.4, 1.0, 0.5))
		if _hits >= _hits_needed:
			_finish(true, _misses == 0)
		else:
			_move_zone()
	else:
		_misses += 1
		_flash(Color(1.0, 0.3, 0.3))
		if _misses >= max_misses:
			_finish(false, false)


func _move_zone() -> void:
	_zone_start = _rng.randf_range(0.0, 1.0 - _zone_width)


func _flash(color: Color) -> void:
	_flash_color = color
	_flash_left = flash_seconds


func _draw() -> void:
	var origin := _centered_origin(bar_size)
	var bar := Rect2(origin, bar_size)
	draw_rect(bar, Color(0.12, 0.12, 0.18))
	var zone := Rect2(origin + Vector2(_zone_start * bar_size.x, 0), Vector2(_zone_width * bar_size.x, bar_size.y))
	draw_rect(zone, _tint(Color(0.3, 0.85, 0.4)))
	if _flash_left > 0.0:
		var flash := _flash_color
		flash.a = 0.4 * (_flash_left / flash_seconds)
		draw_rect(bar, flash)
	var needle_x := origin.x + _needle * bar_size.x
	draw_rect(Rect2(needle_x - 1, origin.y - 5, 2, bar_size.y + 10), _tint(Color.WHITE))
	draw_rect(bar, Color(1, 1, 1, 0.6), false, 1.0)
	# Hit pips below the bar.
	for i in _hits_needed:
		var pip_pos := Vector2(size.x * 0.5 + (i - (_hits_needed - 1) * 0.5) * 14, origin.y + bar_size.y + 14)
		draw_circle(pip_pos, 4, _tint(fish.color) if i < _hits else Color(1, 1, 1, 0.25))
