class_name ReelLogic
extends RefCounted
## Pure rules of the first-person rod (no nodes): when a bite comes, the
## hook window, and the reel fight. Holding the button reels: tension rises
## and the fish comes closer; releasing lets tension fall. The fish makes
## runs (stronger for big / rare fish) that pull tension up and, released,
## take line. Full tension for snap_seconds = the line snaps; distance 0 =
## landed. Numbers in ReelTuning.

enum Outcome { FIGHTING, LANDED, SNAPPED }

var tuning: ReelTuning
## 0..1, from the fish and its size.
var strength := 0.5
## Metres of line between Rin and the fish.
var distance := 8.0
var start_distance := 8.0
## 0..1.
var tension := 0.0
## Seconds spent at full tension.
var over := 0.0
## True while the fish makes a run.
var running := false
var _run_left := 0.0
var _gap := 1.0
var _rng: RandomNumberGenerator


func _init(tuning_: ReelTuning, strength_: float, distance_: float, rng: RandomNumberGenerator) -> void:
	tuning = tuning_
	strength = clampf(strength_, 0.0, 1.0)
	distance = maxf(distance_, 0.5)
	start_distance = distance
	_rng = rng
	_gap = _rng.randf_range(tuning.run_gap_min, tuning.run_gap_max) * 0.6


## How hard a fish fights: its species difficulty, bigger = harder, aberrant +.
static func strength_of(fish: FishData, size: float) -> float:
	if fish == null:
		return 0.5
	var s := fish.difficulty * (1.0 + (size - 1.0) * 0.6) + (0.15 if fish.is_aberrant else 0.0)
	return clampf(s, 0.05, 1.0)


## Seconds until the next bite; sooner at a shoal.
static func bite_delay(tuning_: ReelTuning, rng: RandomNumberGenerator, at_shoal: bool) -> float:
	var delay := rng.randf_range(tuning_.bite_min, tuning_.bite_max)
	return delay * (tuning_.shoal_bite_scale if at_shoal else 1.0)


## Whether a click `since_bite` seconds after the bite still hooks.
static func in_window(tuning_: ReelTuning, since_bite: float) -> bool:
	return since_bite >= 0.0 and since_bite <= tuning_.bite_window


## Fraction of the line already won back (0 at the hook, 1 landed).
func progress() -> float:
	return clampf(1.0 - distance / maxf(start_distance, 0.01), 0.0, 1.0)


## One step of the fight; `reeling` = the button is held.
func step(delta: float, reeling: bool) -> Outcome:
	_step_runs(delta)
	var pull := strength if running else 0.0
	if reeling:
		tension += (tuning.rise + tuning.rise_by_strength * strength + tuning.run_tension * pull) * delta
		distance -= tuning.reel_speed * (tuning.reel_speed_in_run if running else 1.0) * delta
	else:
		tension += (tuning.run_tension * tuning.run_tension_released * pull - tuning.fall) * delta
		distance += tuning.run_line * pull * delta
	tension = clampf(tension, 0.0, 1.0)
	distance = minf(distance, start_distance + tuning.extra_line)
	over = over + delta if tension >= 1.0 else 0.0
	if over > tuning.snap_seconds:
		return Outcome.SNAPPED
	if distance <= 0.0:
		distance = 0.0
		return Outcome.LANDED
	return Outcome.FIGHTING


func _step_runs(delta: float) -> void:
	if running:
		_run_left -= delta
		if _run_left <= 0.0:
			running = false
			_gap = _rng.randf_range(tuning.run_gap_min, tuning.run_gap_max) * lerpf(1.4, 0.7, strength)
		return
	_gap -= delta
	if _gap <= 0.0:
		running = true
		_run_left = _rng.randf_range(tuning.run_min, tuning.run_max) * lerpf(0.6, 1.3, strength)
