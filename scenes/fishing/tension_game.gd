class_name TensionGame
extends MinigameBase
## Line-tension game. A green zone drifts up and down (the fish struggling).
## Hold `cast` to raise the needle, release to let it sink. Keeping the needle
## in the zone fills the reel bar; staying outside too long wears the line.
## Full reel = caught. Line durability at zero = line snaps.

@export var bar_size: Vector2 = Vector2(20, 180)
## Needle acceleration (bar heights/s²) while holding / falling.
@export var lift_acceleration: float = 3.0
@export var fall_acceleration: float = 2.5
@export var max_needle_speed: float = 1.2
## Green zone height as a fraction of the bar at difficulty 0 and 1.
@export var easy_zone_size: float = 0.35
@export var hard_zone_size: float = 0.15
## How fast the fish drags the zone (bar heights/s) at difficulty 0 and 1.
@export var easy_fish_speed: float = 0.15
@export var hard_fish_speed: float = 0.7
## Random seconds between fish direction changes (min, max).
@export var retarget_interval: Vector2 = Vector2(0.4, 1.2)
## Reel progress per second while inside the zone, at difficulty 0 and 1.
@export var easy_reel_rate: float = 0.3
@export var hard_reel_rate: float = 0.15
## Line durability lost per second while outside (after the grace time).
@export var line_drain: float = 0.35
@export var outside_grace: float = 0.2
@export var start_progress: float = 0.2

var _needle: float = 0.5
var _needle_velocity: float = 0.0
var _zone_center: float = 0.5
var _zone_target: float = 0.5
var _zone_size: float = 0.3
var _fish_speed: float = 0.3
var _reel_rate: float = 0.2
var _retarget_left: float = 0.0
var _progress: float = 0.0
var _durability: float = 1.0
var _outside_time: float = 0.0
var _ever_left_zone: bool = false
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	_rng.randomize()
	var d := fish.difficulty
	_zone_size = clampf(lerpf(easy_zone_size, hard_zone_size, d) * zone_scale, 0.05, 0.9)
	# A better rod also tires the fish out: slower struggling.
	_fish_speed = lerpf(easy_fish_speed, hard_fish_speed, d) / zone_scale
	_reel_rate = lerpf(easy_reel_rate, hard_reel_rate, d)
	_progress = start_progress
	# Start fair: needle already inside the zone.
	_needle = _zone_center
	custom_minimum_size = Vector2(140, bar_size.y + 20)


func get_hint() -> String:
	return "Giữ Space / chuột trái để kéo kim lên, giữ kim trong vùng xanh"


func get_status_text() -> String:
	return "Kéo cá %d%%    Dây %d%%" % [roundi(_progress * 100), roundi(maxf(_durability, 0.0) * 100)]


func get_fail_text() -> String:
	return "Đứt dây!"


func _update(delta: float) -> void:
	_move_needle(delta)
	_move_fish(delta)
	if absf(_needle - _zone_center) <= _zone_size * 0.5:
		_outside_time = 0.0
		_progress += _reel_rate * delta
	else:
		_ever_left_zone = true
		_outside_time += delta
		if _outside_time > outside_grace:
			_durability -= line_drain * delta
	if _progress >= 1.0:
		_finish(true, not _ever_left_zone)
	elif _durability <= 0.0:
		_finish(false, false)


func _move_needle(delta: float) -> void:
	var accel := lift_acceleration if Input.is_action_pressed("cast") else -fall_acceleration
	_needle_velocity = clampf(_needle_velocity + accel * delta, -max_needle_speed, max_needle_speed)
	_needle += _needle_velocity * delta
	# Hitting either end stops the needle dead (no bounce = easier to control).
	if _needle <= 0.0 or _needle >= 1.0:
		_needle = clampf(_needle, 0.0, 1.0)
		_needle_velocity = 0.0


func _move_fish(delta: float) -> void:
	_retarget_left -= delta
	if _retarget_left <= 0.0:
		var half := _zone_size * 0.5
		_zone_target = _rng.randf_range(half, 1.0 - half)
		_retarget_left = _rng.randf_range(retarget_interval.x, retarget_interval.y)
	_zone_center = move_toward(_zone_center, _zone_target, _fish_speed * delta)


func _draw() -> void:
	var origin := _centered_origin(Vector2(bar_size.x + 60, bar_size.y))
	var bar := Rect2(origin, bar_size)
	draw_rect(bar, Color(0.12, 0.12, 0.18))
	# 0 = bottom of the bar, 1 = top.
	var zone_top := origin.y + (1.0 - _zone_center - _zone_size * 0.5) * bar_size.y
	draw_rect(Rect2(origin.x, zone_top, bar_size.x, _zone_size * bar_size.y), _tint(Color(0.3, 0.85, 0.4)))
	var needle_y := origin.y + (1.0 - _needle) * bar_size.y
	draw_rect(Rect2(origin.x - 4, needle_y - 1, bar_size.x + 8, 3), _tint(Color.WHITE))
	draw_rect(bar, Color(1, 1, 1, 0.6), false, 1.0)

	_draw_meter(Vector2(origin.x + bar_size.x + 14, origin.y), _progress, _tint(fish.color), "Kéo")
	_draw_meter(Vector2(origin.x + bar_size.x + 40, origin.y), _durability, Color(1.0, 0.6, 0.2), "Dây")


## Vertical meter filling from the bottom, with a small label underneath.
func _draw_meter(pos: Vector2, value: float, color: Color, label: String) -> void:
	var meter_size := Vector2(10, bar_size.y)
	draw_rect(Rect2(pos, meter_size), Color(0.12, 0.12, 0.18))
	var fill := clampf(value, 0.0, 1.0) * meter_size.y
	draw_rect(Rect2(pos.x, pos.y + meter_size.y - fill, meter_size.x, fill), color)
	draw_rect(Rect2(pos, meter_size), Color(1, 1, 1, 0.6), false, 1.0)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-6, meter_size.y + 12), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
