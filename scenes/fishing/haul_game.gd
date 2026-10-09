class_name HaulGame
extends MinigameBase
## Hauling a net up from the sea floor. Hold `cast` to pull the rope in.
## Now and then the net snags on rocks: the rope shakes yellow as a warning,
## then turns red. Pulling while red tips the net and shellfish fall out.
## Reaching the surface ends the haul; `catch_count` is what is left.

@export var shaft_size: Vector2 = Vector2(40, 170)
## Seconds of continuous pulling to bring the net up.
@export var pull_seconds: float = 4.0
## Seconds between snags at difficulty 0 and 1 (random within ±30%).
@export var easy_snag_interval: float = 2.2
@export var hard_snag_interval: float = 1.0
@export var warning_seconds: float = 0.35
## How long a snag lasts (min, max).
@export var snag_duration: Vector2 = Vector2(0.5, 0.9)
## One shellfish falls out per this many seconds of pulling while snagged.
@export var drop_every: float = 0.25

enum SnagState { CLEAR, WARNING, SNAGGED }

## 1 = sea floor, 0 = surface.
var _depth: float = 1.0
var _state: SnagState = SnagState.CLEAR
var _state_left: float = 0.0
var _snag_interval: float = 2.0
var _drop_timer: float = 0.0
var _start_count: int = 0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	_rng.randomize()
	_start_count = catch_count
	# A better net/rod (zone_scale) means fewer snags.
	_snag_interval = lerpf(easy_snag_interval, hard_snag_interval, fish.difficulty) * zone_scale
	_state_left = _next_clear_time()
	custom_minimum_size = Vector2(160, shaft_size.y + 20)


func get_hint() -> String:
	return "Giữ Space: kéo · dây đỏ: NHẢ"


func get_status_text() -> String:
	return "Ốc trong lưới: %d/%d" % [catch_count, _start_count]


func get_fail_text() -> String:
	return "Ốc rơi hết khỏi lưới..."


func _update(delta: float) -> void:
	_update_snag(delta)
	var pulling := _cast_held()
	if not pulling:
		return
	if _state == SnagState.SNAGGED:
		# Yanking a snagged net spills the catch.
		_drop_timer += delta
		if _drop_timer >= drop_every:
			_drop_timer = 0.0
			catch_count = maxi(catch_count - 1, 0)
			if catch_count == 0:
				_finish(false, false)
		return
	_depth = maxf(_depth - delta / pull_seconds, 0.0)
	if _depth <= 0.0:
		_finish(catch_count > 0, catch_count == _start_count)


func _update_snag(delta: float) -> void:
	_state_left -= delta
	if _state_left > 0.0:
		return
	match _state:
		SnagState.CLEAR:
			_state = SnagState.WARNING
			_state_left = warning_seconds
		SnagState.WARNING:
			_state = SnagState.SNAGGED
			_state_left = _rng.randf_range(snag_duration.x, snag_duration.y)
			_drop_timer = 0.0
		SnagState.SNAGGED:
			_state = SnagState.CLEAR
			_state_left = _next_clear_time()


func _next_clear_time() -> float:
	return _snag_interval * _rng.randf_range(0.7, 1.3)


func _draw() -> void:
	var origin := _centered_origin(shaft_size + Vector2(60, 0))
	var water := Rect2(origin, shaft_size)
	draw_rect(water, Color(0.1, 0.3, 0.5))
	draw_rect(Rect2(origin.x, origin.y + shaft_size.y - 6, shaft_size.x, 6), Color(0.6, 0.55, 0.4))  # sand

	var rope_color := Color.WHITE
	var shake := 0.0
	if _state == SnagState.WARNING:
		rope_color = Color(1.0, 0.85, 0.3)
		shake = 1.0
	elif _state == SnagState.SNAGGED:
		rope_color = Color(1.0, 0.3, 0.3)
		shake = 2.0
	var x := origin.x + shaft_size.x * 0.5 + sin(_time * 60.0) * shake
	var net_y := origin.y + 8 + _depth * (shaft_size.y - 22)
	draw_line(Vector2(x, origin.y - 6), Vector2(x, net_y), rope_color, 2.0)

	# Net with one dot per shellfish still inside.
	var net := Rect2(x - 12, net_y, 24, 14)
	draw_rect(net, Color(0.75, 0.65, 0.45))
	draw_rect(net, Color(0.3, 0.2, 0.1), false, 1.0)
	for i in catch_count:
		var dot := net.position + Vector2(4 + (i % 5) * 4, 4 + (i / 5) * 5)
		draw_circle(dot, 1.5, _tint(fish.color))

	# Depth meter on the side.
	var meter := Rect2(origin.x + shaft_size.x + 14, origin.y, 8, shaft_size.y)
	draw_rect(meter, Color(0.12, 0.12, 0.18))
	var progress := 1.0 - _depth
	draw_rect(Rect2(meter.position.x, meter.end.y - progress * meter.size.y, meter.size.x, progress * meter.size.y),
		Color(0.3, 0.85, 0.4))
	draw_rect(meter, Color(1, 1, 1, 0.6), false, 1.0)
