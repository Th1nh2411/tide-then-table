class_name RhythmChart
extends RefCounted
## Pure: the "tune" a hooked fish fights with in the rod rhythm game
## (RhythmGame). Each note is one tug on the line: {t, lane, hold} (seconds
## from the start, lane 0..3 = A S D F, hold = seconds to keep the key down,
## 0 = a tap). Harder fish: more lanes, more and denser notes; mackerel-like
## fish tug in bursts, hard ones pull and hold (long notes), aberrant fish
## change tempo without warning. `zone_scale` < 1 (big fish, harder fights)
## adds notes; > 1 (better rod) removes a few.

## Tuning, overridable per game (RhythmGame passes its @exports).
const DEFAULTS := {
	"notes_easy": 10, "notes_hard": 24,
	"gap_easy": 0.62, "gap_hard": 0.34,
	"lead_in": 1.0,
	"burst_chance": 0.45,  # at difficulty 1; scales with difficulty
	"hold_from": 0.6, "hold_chance": 0.3, "hold_seconds": Vector2(0.5, 1.0),
	"lanes_3_from": 0.35, "lanes_4_from": 0.65,
}


static func lane_count(difficulty: float, tuning: Dictionary = DEFAULTS) -> int:
	if difficulty >= float(tuning["lanes_4_from"]):
		return 4
	if difficulty >= float(tuning["lanes_3_from"]):
		return 3
	return 2


static func build(difficulty: float, aberrant: bool, zone_scale: float, rng: RandomNumberGenerator,
		tuning: Dictionary = DEFAULTS) -> Array[Dictionary]:
	var d := clampf(difficulty, 0.0, 1.0)
	var lanes := lane_count(d, tuning)
	var count := roundi(lerpf(float(tuning["notes_easy"]), float(tuning["notes_hard"]), d)
		/ clampf(zone_scale, 0.7, 1.5))
	var gap := lerpf(float(tuning["gap_easy"]), float(tuning["gap_hard"]), d)
	var notes: Array[Dictionary] = []
	var t: float = tuning["lead_in"]
	var lane := rng.randi_range(0, lanes - 1)
	while notes.size() < count:
		var burst := rng.randf() < float(tuning["burst_chance"]) * d and count - notes.size() >= 3
		var steps := 3 if burst else 1
		for i in steps:
			var hold := 0.0
			if not burst and d >= float(tuning["hold_from"]) and rng.randf() < float(tuning["hold_chance"]):
				var range_s: Vector2 = tuning["hold_seconds"]
				hold = rng.randf_range(range_s.x, range_s.y)
			notes.append({"t": t, "lane": lane, "hold": hold})
			lane = _next_lane(lane, lanes, rng, burst)
			t += (gap * 0.5 if burst else gap) + hold
		if aberrant:  # the tempo lurches
			t += gap * rng.randf_range(-0.4, 0.6)
		t += gap * 0.3 if burst else 0.0
	return notes


## Mostly a step to a neighbour (playable runs), sometimes a jump.
static func _next_lane(lane: int, lanes: int, rng: RandomNumberGenerator, burst: bool) -> int:
	if lanes <= 1:
		return 0
	var step := rng.randi_range(1, 1 if burst else lanes - 1)
	return (lane + step * (1 if rng.randf() < 0.5 else -1) + lanes * 2) % lanes


## Seconds until the last note is done.
static func length(notes: Array[Dictionary]) -> float:
	if notes.is_empty():
		return 0.0
	var last: Dictionary = notes[-1]
	return float(last["t"]) + float(last["hold"])
