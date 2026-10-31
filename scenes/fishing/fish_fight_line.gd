class_name FishFightLine
extends RefCounted
## The fishing line as soft ropes (screen pixels), Verlet chains pinned at
## both ends. While the bait hangs free, the line is two ropes: rod tip →
## bobber (sags in a soft curve through the air) and bobber → hook (the
## sinker keeps it almost straight, a slow current curls it a little). The
## bobber floats on the surface and drifts after the hook with some lag.
## Once a fish bites, it is one rope from the tip to the hook that sags while
## the tension is low and pulls straight as it rises.

const AIR_POINTS := 10
const WATER_POINTS := 8
const TAUT_POINTS := 16
const AIR_GRAVITY := 340.0
const WATER_GRAVITY := 40.0
## Extra length of each rope (1.06 = 6% longer than the gap between its ends).
const AIR_SLACK := 1.06
const WATER_SLACK := 1.015
const BITE_SLACK := 1.18
## Bobber: spring towards its spot above the hook, water drag, bob height.
const BOBBER_SPRING := 40.0
const BOBBER_DRAG := 10.0
const BOBBER_BOB := 1.0
## Sideways push of the slow current on the line under water (px/s²).
const CURRENT := 14.0

## The line to draw, tip to hook.
var points := PackedVector2Array()
## Where the bobber floats (Vector2), or null while a fish is on / the hook is up.
var bobber: Variant = null
var _air := Rope.new(AIR_POINTS)
var _water := Rope.new(WATER_POINTS)
var _taut := Rope.new(TAUT_POINTS)
var _bobber_x: float = 0.0
var _bobber_velocity: float = 0.0
var _slack := false


## Free bait: rod tip → bobber → hook. `time` drives the bob and the current.
func step_slack(tip: Vector2, hook: Vector2, surface: float, time: float, delta: float) -> void:
	if hook.y < surface + 6.0:  # bait at the surface: no bobber to float
		step_taut(tip, hook, 0.15, surface, delta)
		return
	var dt := minf(delta, 1.0 / 30.0)
	if not _slack:
		_slack = true
		_bobber_x = lerpf(hook.x, tip.x, 0.15)
		_bobber_velocity = 0.0
		_air.reset(tip, Vector2(_bobber_x, surface))
		_water.reset(Vector2(_bobber_x, surface), hook)
	# The sinker pulls the bobber over the hook, leaning a bit towards the rod.
	var target := lerpf(hook.x, tip.x, 0.15)
	_bobber_velocity += (target - _bobber_x) * BOBBER_SPRING * dt
	_bobber_velocity *= exp(-BOBBER_DRAG * dt)
	_bobber_x += _bobber_velocity * dt
	# The line holds it: never far outside the gap between the rod and the hook.
	_bobber_x = clampf(_bobber_x, minf(hook.x, tip.x) - 10.0, maxf(hook.x, tip.x) + 10.0)
	var float_at := Vector2(_bobber_x, surface + sin(time * 3.0) * BOBBER_BOB)
	_air.step(tip, float_at, AIR_SLACK, surface, dt, 0.0)
	_water.step(float_at, hook, WATER_SLACK, surface, dt, sin(time * 0.9) * CURRENT)
	bobber = float_at
	points = _air.points.duplicate()
	points.append_array(_water.points.slice(1))


## A fish on (or the bait at the surface): one rope, straighter as `tension` rises.
func step_taut(tip: Vector2, hook: Vector2, tension: float, surface: float, delta: float) -> void:
	if _slack or _taut.points.size() != TAUT_POINTS:
		_taut.resample(points if points.size() > 1 else PackedVector2Array([tip, hook]))
	_slack = false
	bobber = null
	var slack := lerpf(BITE_SLACK, 1.0, clampf(tension * 1.4, 0.0, 1.0))
	_taut.step(tip, hook, slack, surface, minf(delta, 1.0 / 30.0), 0.0)
	points = _taut.points


## One Verlet chain: air gravity above the surface, slow heavy water below.
class Rope:
	extends RefCounted
	const ITERATIONS := 10
	const AIR_DAMP := 0.97
	const WATER_DAMP := 0.86

	var points := PackedVector2Array()
	var _previous := PackedVector2Array()
	var _count: int

	func _init(count: int) -> void:
		_count = count

	func reset(a: Vector2, b: Vector2) -> void:
		points.resize(_count)
		_previous.resize(_count)
		for i in _count:
			points[i] = a.lerp(b, float(i) / (_count - 1))
		_previous = points.duplicate()

	## Takes the shape of another polyline (no jump when the line changes mode).
	func resample(line: PackedVector2Array) -> void:
		var total := 0.0
		for i in line.size() - 1:
			total += line[i].distance_to(line[i + 1])
		points.resize(_count)
		var seg := 0
		var walked := 0.0
		for i in _count:
			var want := total * float(i) / (_count - 1)
			while seg < line.size() - 2 and walked + line[seg].distance_to(line[seg + 1]) < want:
				walked += line[seg].distance_to(line[seg + 1])
				seg += 1
			var span := maxf(line[seg].distance_to(line[seg + 1]), 0.0001)
			points[i] = line[seg].lerp(line[seg + 1], clampf((want - walked) / span, 0.0, 1.0))
		_previous = points.duplicate()

	func step(a: Vector2, b: Vector2, slack: float, surface: float, dt: float, current: float) -> void:
		if points.size() != _count or points[0].distance_to(a) > 120.0:
			reset(a, b)
		var rest := maxf(a.distance_to(b), 1.0) * slack / (_count - 1)
		for i in range(1, _count - 1):
			var p := points[i]
			var wet := p.y > surface
			var velocity := (p - _previous[i]) * (WATER_DAMP if wet else AIR_DAMP)
			_previous[i] = p
			var force := Vector2(current, WATER_GRAVITY) if wet else Vector2(0, AIR_GRAVITY)
			points[i] = p + velocity + force * dt * dt
		for k in ITERATIONS:
			points[0] = a
			points[_count - 1] = b
			for i in _count - 1:
				var span := points[i + 1] - points[i]
				var length := span.length()
				if length < 0.0001:
					continue
				var fix := span * (1.0 - rest / length) * 0.5
				if i > 0:
					points[i] += fix
				if i + 1 < _count - 1:
					points[i + 1] -= fix
		points[0] = a
		points[_count - 1] = b
