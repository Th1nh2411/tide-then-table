class_name BiteGame
extends MinigameBase
## Waiting for a bite, before the real fight. The bobber floats; the fish
## nibbles a few times (small dips) before really biting (bobber sinks).
## Press `cast` to strike only when it sinks. Striking early spooks the fish
## (once is forgiven, it comes back); missing the bite loses the bait.
## Success with no early strike counts as "clean" (keeps a perfect catch).

enum State { WAIT, NIBBLE, BITE }

## Seconds before the first event (min, max).
@export var first_wait: Vector2 = Vector2(1.0, 2.5)
## Seconds between nibbles (min, max).
@export var gap_between: Vector2 = Vector2(0.6, 1.4)
@export var nibble_seconds: float = 0.25
## Nibbles before the bite: (min, max) at difficulty 0 and at difficulty 1.
@export var easy_nibbles: Vector2i = Vector2i(0, 1)
@export var hard_nibbles: Vector2i = Vector2i(2, 4)
## Time to react once the bobber sinks, at difficulty 0 and 1.
@export var easy_bite_window: float = 0.8
@export var hard_bite_window: float = 0.4
## Early strikes forgiven before the fish leaves for good.
@export var max_spooks: int = 1

var _state: State = State.WAIT
var _state_left: float = 0.0
var _nibbles_left: int = 0
var _bite_window: float = 0.5
var _spooks: int = 0
var _fail_text: String = ""
var _flash_text: String = ""
var _flash_left: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_fish: FishData, p_zone_scale: float) -> void:
	super(p_fish, p_zone_scale)
	_rng.randomize()
	# A better rod gives a little more time to react.
	_bite_window = lerpf(easy_bite_window, hard_bite_window, fish.difficulty) * zone_scale
	custom_minimum_size = Vector2(200, 120)
	_restart_sequence()


func get_hint() -> String:
	return "Phao CHÌM HẲN mới giật (Space) · nhấp nhẹ: chờ"


func get_status_text() -> String:
	return _flash_text if _flash_left > 0.0 else "Đang chờ cá cắn..."


func get_fail_text() -> String:
	return _fail_text


func _update(delta: float) -> void:
	_flash_left -= delta
	_state_left -= delta
	var struck := _cast_just_pressed()
	match _state:
		State.WAIT:
			if struck:
				_spook()
			elif _state_left <= 0.0:
				if _nibbles_left > 0:
					_nibbles_left -= 1
					_set_state(State.NIBBLE, nibble_seconds)
				else:
					_set_state(State.BITE, _bite_window)
		State.NIBBLE:
			if struck:
				_spook()
			elif _state_left <= 0.0:
				_set_state(State.WAIT, _rng.randf_range(gap_between.x, gap_between.y))
		State.BITE:
			if struck:
				_finish(true, _spooks == 0)
			elif _state_left <= 0.0:
				_fail_text = "Cá ăn mồi rồi chạy mất..."
				_finish(false, false)


func _spook() -> void:
	_spooks += 1
	if _spooks > max_spooks:
		_fail_text = "Giật hụt lần nữa, cá sợ bỏ đi mất."
		_finish(false, false)
		return
	_flash_text = "Giật hụt! Cá hoảng, chờ nó quay lại..."
	_flash_left = 1.5
	_restart_sequence(1.0)


## New nibble pattern; `extra_wait` makes a spooked fish take longer to return.
func _restart_sequence(extra_wait: float = 0.0) -> void:
	var d := fish.difficulty
	var low := roundi(lerpf(easy_nibbles.x, hard_nibbles.x, d))
	var high := roundi(lerpf(easy_nibbles.y, hard_nibbles.y, d))
	_nibbles_left = _rng.randi_range(low, maxi(low, high))
	_set_state(State.WAIT, _rng.randf_range(first_wait.x, first_wait.y) + extra_wait)


func _set_state(state: State, seconds: float) -> void:
	if state == State.NIBBLE:
		Sfx.play("nibble")
	elif state == State.BITE:
		Sfx.play("bite")
	_state = state
	_state_left = seconds


func _draw() -> void:
	var center := size * 0.5
	var water_y := center.y
	draw_rect(Rect2(0, water_y, size.x, size.y - water_y), Color(0.12, 0.32, 0.5))
	draw_line(Vector2(0, water_y), Vector2(size.x, water_y), Color(0.7, 0.85, 1.0), 1.0)
	# Fishing line from the top.
	var bob_y := water_y - 4 + sin(_time * 2.0) * 1.5
	var ripple := 0.0
	match _state:
		State.NIBBLE:
			bob_y = water_y + 2
			ripple = 1.0
		State.BITE:
			bob_y = water_y + 14  # sinks right under
			ripple = 2.0
	draw_line(Vector2(center.x, 0), Vector2(center.x, bob_y - 5), Color(1, 1, 1, 0.6), 1.0)
	if ripple > 0.0:
		for i in int(ripple) + 1:
			draw_arc(Vector2(center.x, water_y), 8 + i * 7 + fmod(_time * 30.0, 6.0), PI, TAU, 16,
				Color(1, 1, 1, 0.5 - i * 0.15), 1.0)
	# Bobber: red top, white bottom.
	draw_circle(Vector2(center.x, bob_y), 5, _tint(Color(0.9, 0.2, 0.2)))
	draw_circle(Vector2(center.x, bob_y + 3), 3.5, Color.WHITE)
