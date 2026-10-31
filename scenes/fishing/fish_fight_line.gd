class_name FishFightLine
extends RefCounted
## The fishing line as a soft rope (screen pixels): a chain of points with
## Verlet motion, pinned at the rod tip and the hook. Gravity pulls it down
## in the air, the water slows and lifts it; the rest length is longer than
## the gap while the line is slack, so it sags and sways, and shrinks to the
## gap as the tension rises, so it pulls straight.

const POINTS := 16
const ITERATIONS := 10
const AIR_GRAVITY := 340.0
const WATER_GRAVITY := 40.0
const AIR_DAMP := 0.97
const WATER_DAMP := 0.86
## Extra length while slack (1.18 = 18% longer than the gap) / under full tension.
const SLACK := 1.18
const TAUT := 1.0

var points := PackedVector2Array()
var _previous := PackedVector2Array()


## Moves the rope one step. `tension` 0..1, `surface` = water line y.
func step(tip: Vector2, hook: Vector2, tension: float, surface: float, delta: float) -> void:
	if points.size() != POINTS or points[0].distance_to(tip) > 120.0:
		_reset(tip, hook)
	var gap := maxf(tip.distance_to(hook), 1.0)
	var rest := gap * lerpf(SLACK, TAUT, clampf(tension * 1.4, 0.0, 1.0)) / (POINTS - 1)
	var dt := minf(delta, 1.0 / 30.0)
	for i in range(1, POINTS - 1):
		var p := points[i]
		var wet := p.y > surface
		var velocity := (p - _previous[i]) * (WATER_DAMP if wet else AIR_DAMP)
		_previous[i] = p
		points[i] = p + velocity + Vector2(0, WATER_GRAVITY if wet else AIR_GRAVITY) * dt * dt
	for k in ITERATIONS:
		points[0] = tip
		points[POINTS - 1] = hook
		for i in POINTS - 1:
			var a := points[i]
			var b := points[i + 1]
			var span := b - a
			var length := span.length()
			if length < 0.0001:
				continue
			var fix := span * (1.0 - rest / length) * 0.5
			if i > 0:
				points[i] = a + fix
			if i + 1 < POINTS - 1:
				points[i + 1] = b - fix
	points[0] = tip
	points[POINTS - 1] = hook


## Where the rope first dips under the water (for the bobber), or null.
func surface_crossing(surface: float) -> Variant:
	for i in points.size() - 1:
		if points[i].y < surface and points[i + 1].y >= surface:
			return Vector2(lerpf(points[i].x, points[i + 1].x, 0.5), surface)
	return null


func _reset(tip: Vector2, hook: Vector2) -> void:
	points.resize(POINTS)
	_previous.resize(POINTS)
	for i in POINTS:
		points[i] = tip.lerp(hook, float(i) / (POINTS - 1))
		_previous[i] = points[i]
