class_name TensionGame
extends MinigameBase
## Line-tension fight. A green zone drifts up and down (the fish struggling).
## Hold `cast` to raise the needle, release to let it sink. Keeping the needle
## in the zone fills the reel bar; outside, the reel bar slips back and (after
## a grace time) the line wears. Full reel = caught. Line at zero = snapped.
##
## The fish fights in three phases and tires as the fight goes on (no
## stamina bar; the status text tells the phase):
##   STRONG -> small, fast zone with sudden dashes (warned by an orange flash)
##   FIGHT  -> normal
##   TIRED  -> big, slow zone and faster reeling

enum Phase { STRONG, FIGHT, TIRED }

@export var bar_size: Vector2 = Vector2(20, 150)
## Needle acceleration (bar heights/s²) while holding / falling.
@export var lift_acceleration: float = 3.0
@export var fall_acceleration: float = 2.5
@export var max_needle_speed: float = 1.2
## Green zone height as a fraction of the bar at difficulty 0 and 1.
@export var easy_zone_size: float = 0.35
@export var hard_zone_size: float = 0.15
## How fast the fish drags the zone (bar heights/s) at difficulty 0 and 1.
@export var easy_fish_speed: float = 0.15
@export var hard_fish_speed: float = 0.6
## Random seconds between fish direction changes (min, max).
@export var retarget_interval: Vector2 = Vector2(0.4, 1.2)
## Reel progress per second while inside the zone, at difficulty 0 and 1.
@export var easy_reel_rate: float = 0.16
@export var hard_reel_rate: float = 0.07
## Reel progress lost per second while outside the zone (after the grace time).
@export var reel_slip_rate: float = 0.06
## Line durability lost per second while outside (after the grace time).
@export var line_drain: float = 0.2
@export var outside_grace: float = 0.3
@export var start_progress: float = 0.1

@export_group("Phases")
## Fight seconds the fish stays strong / until it is tired, at difficulty 0 and 1.
@export var strong_seconds: Vector2 = Vector2(2.0, 5.0)
@export var tired_seconds: Vector2 = Vector2(4.5, 10.0)
## Multipliers per phase [STRONG, FIGHT, TIRED].
@export var phase_zone_scale: Array[float] = [0.8, 1.0, 1.35]
@export var phase_speed_scale: Array[float] = [1.4, 1.0, 0.55]
@export var phase_reel_scale: Array[float] = [0.8, 1.0, 1.6]

@export_group("Dashes")
## Seconds between dashes (min, max) while STRONG or FIGHT; shorter for hard fish.
@export var dash_interval: Vector2 = Vector2(2.5, 5.0)
@export var dash_warning: float = 0.5
@export var dash_seconds: float = 0.6
@export var dash_speed_scale: float = 3.5
## Dash speed never exceeds this fraction of max_needle_speed, so a quick
## player can always follow (otherwise hard fish become unwinnable).
@export var dash_speed_cap: float = 0.85

var _needle: float = 0.5
var _needle_velocity: float = 0.0
var _zone_center: float = 0.5
var _zone_target: float = 0.5
var _base_zone_size: float = 0.3
var _base_fish_speed: float = 0.3
var _reel_rate: float = 0.2
var _retarget_left: float = 0.0
var _progress: float = 0.0
var _durability: float = 1.0
var _outside_time: float = 0.0
var _strong_until: float = 3.0
var _tired_from: float = 7.0
var _ever_left_zone: bool = false
## Dash state: >0 counts down the warning, then the dash itself.
var _dash_cooldown: float = 0.0
var _dash_warning_left: float = 0.0
var _dash_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	_rng.randomize()
	var d := fish.difficulty
	_base_zone_size = lerpf(easy_zone_size, hard_zone_size, d) * zone_scale
	# A better rod also tires the fish out: slower struggling.
	_base_fish_speed = lerpf(easy_fish_speed, hard_fish_speed, d) / zone_scale
	_reel_rate = lerpf(easy_reel_rate, hard_reel_rate, d)
	_strong_until = lerpf(strong_seconds.x, strong_seconds.y, d)
	_tired_from = lerpf(tired_seconds.x, tired_seconds.y, d)
	_progress = start_progress
	_needle = _zone_center  # start fair: needle already inside the zone
	_dash_cooldown = _next_dash_time()
	custom_minimum_size = Vector2(150, bar_size.y + 20)


func get_hint() -> String:
	return "Giữ Space: kim lên · giữ trong vùng xanh · chớp cam: cá sắp lao"


func get_status_text() -> String:
	var phase_names := ["Cá đang vùng vẫy mạnh!", "Giằng co...", "Cá đuối sức rồi, kéo đi!"]
	return "%s   Kéo %d%%  Dây %d%%" % [phase_names[_phase()], roundi(_progress * 100),
		roundi(maxf(_durability, 0.0) * 100)]


func get_fail_text() -> String:
	return "Đứt dây!"


func _phase() -> Phase:
	if _time < _strong_until:
		return Phase.STRONG
	if _time < _tired_from:
		return Phase.FIGHT
	return Phase.TIRED


func _zone_size() -> float:
	return clampf(_base_zone_size * phase_zone_scale[_phase()], 0.05, 0.9)


func _update(delta: float) -> void:
	_move_needle(delta)
	_update_dash(delta)
	_move_fish(delta)
	var inside := absf(_needle - _zone_center) <= _zone_size() * 0.5
	if inside:
		_outside_time = 0.0
		_progress += _reel_rate * phase_reel_scale[_phase()] * delta
	else:
		_ever_left_zone = true
		_outside_time += delta
		if _outside_time > outside_grace:
			_progress = maxf(_progress - reel_slip_rate * delta, 0.0)
			_durability -= line_drain * delta
	if _progress >= 1.0:
		_finish(true, not _ever_left_zone)
	elif _durability <= 0.0:
		_finish(false, false)


func _move_needle(delta: float) -> void:
	var accel := lift_acceleration if _cast_held() else -fall_acceleration
	_needle_velocity = clampf(_needle_velocity + accel * delta, -max_needle_speed, max_needle_speed)
	_needle += _needle_velocity * delta
	# Hitting either end stops the needle dead (no bounce = easier to control).
	if _needle <= 0.0 or _needle >= 1.0:
		_needle = clampf(_needle, 0.0, 1.0)
		_needle_velocity = 0.0


## Tired fish don't dash. Otherwise: cooldown -> warning flash -> fast dash
## toward the far side of the bar.
func _update_dash(delta: float) -> void:
	if _dash_left > 0.0:
		_dash_left -= delta
		return
	if _dash_warning_left > 0.0:
		_dash_warning_left -= delta
		if _dash_warning_left <= 0.0:
			var half := _zone_size() * 0.5
			_zone_target = (1.0 - half) if _zone_center < 0.5 else half
			_dash_left = dash_seconds
		return
	if _phase() == Phase.TIRED:
		return
	_dash_cooldown -= delta
	if _dash_cooldown <= 0.0:
		_dash_warning_left = dash_warning
		_dash_cooldown = _next_dash_time()


func _next_dash_time() -> float:
	# Hard fish dash more often.
	return _rng.randf_range(dash_interval.x, dash_interval.y) * lerpf(1.3, 0.7, fish.difficulty)


func _move_fish(delta: float) -> void:
	var speed := _base_fish_speed * phase_speed_scale[_phase()]
	if _dash_left > 0.0:
		speed = minf(speed * dash_speed_scale, max_needle_speed * dash_speed_cap)
	else:
		_retarget_left -= delta
		if _retarget_left <= 0.0:
			var half := _zone_size() * 0.5
			_zone_target = _rng.randf_range(half, 1.0 - half)
			_retarget_left = _rng.randf_range(retarget_interval.x, retarget_interval.y)
	_zone_center = move_toward(_zone_center, _zone_target, speed * delta)


func _draw() -> void:
	var origin := _centered_origin(Vector2(bar_size.x + 60, bar_size.y))
	var bar := Rect2(origin, bar_size)
	draw_rect(bar, Color(0.12, 0.12, 0.18))
	# 0 = bottom of the bar, 1 = top.
	var zone_size := _zone_size()
	var zone_top := origin.y + (1.0 - _zone_center - zone_size * 0.5) * bar_size.y
	var zone_color := Color(0.3, 0.85, 0.4)
	if _dash_warning_left > 0.0 and fmod(_time * 12.0, 2.0) < 1.0:
		zone_color = Color(1.0, 0.6, 0.15)  # about to dash
	draw_rect(Rect2(origin.x, zone_top, bar_size.x, zone_size * bar_size.y), _tint(zone_color))
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
