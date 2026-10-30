class_name RowStroke
extends RefCounted
## Paddle strokes of a rowed boat (BoatData.rowed). Pure: no nodes.
## A stroke starts when any of W/S/A/D is held and always runs to its end;
## the boat is only pushed during the pull window, then it glides.
## phase 0..1 also drives Rin's "Row" clip (same PULL window, make_rin_row.py).

const PULL_START: float = 0.15
const PULL_END: float = 0.6
## Mean of sin over the pull window, so one stroke adds exactly `push`.
const PULL_AREA: float = (PULL_END - PULL_START) * 2.0 / PI

var phase: float = 0.0
var active: bool = false
var _forward: float = 0.0
var _turn: float = 0.0


## Advances by `delta` seconds. Returns Vector2(forward speed gained, spin gained).
func step(delta: float, throttle: float, steer: float, data: BoatData) -> Vector2:
	if not active:
		if is_zero_approx(throttle) and is_zero_approx(steer):
			return Vector2.ZERO
		_start(throttle, steer)
	var before := phase
	phase = minf(phase + delta / maxf(data.stroke_seconds, 0.1), 1.0)
	var pulled := _pull_amount(before, phase)
	if phase >= 1.0 - 0.0001:
		phase = 0.0
		active = false
		# Holding keeps rowing: next stroke picks up the current keys.
		if not (is_zero_approx(throttle) and is_zero_approx(steer)):
			_start(throttle, steer)
	return Vector2(_forward * data.stroke_push, _turn * data.stroke_turn) * pulled


func _start(throttle: float, steer: float) -> void:
	active = true
	phase = 0.0
	# Backstrokes are weaker; a pure side stroke still nudges forward.
	_forward = throttle if throttle >= 0.0 else throttle * 0.6
	if is_zero_approx(throttle):
		_forward = 0.25
	_turn = steer


## Share of the stroke's push between two phases (integral of the pull curve).
static func _pull_amount(from: float, to: float) -> float:
	var a := clampf(from, PULL_START, PULL_END)
	var b := clampf(to, PULL_START, PULL_END)
	if b <= a:
		return 0.0
	var k := PI / (PULL_END - PULL_START)
	return ((cos((a - PULL_START) * k) - cos((b - PULL_START) * k)) / k) / PULL_AREA
