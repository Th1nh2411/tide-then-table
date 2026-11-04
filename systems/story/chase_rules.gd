class_name ChaseRules
extends RefCounted
## "Too close to a phenomenon" and the chase it may start (pure, numbers in
## ProximityTuning): the warning band, the notice distance, what a noticed
## phenomenon does, how long a chase lasts, and the chaser's step: it moves
## only while Rin is not looking (weeping angel) and dashes when he turns away.

const TUNING: ProximityTuning = preload("res://data/story/proximity_tuning.tres")
const SALT := "xom_den_chase"
const SKIP_META := "uncanny_skip"

enum Reaction { CHASE, SCARE, VANISH }


## 0 outside the band, rising to 1 at the notice distance.
static func warning(distance: float, t: ProximityTuning = TUNING) -> float:
	if distance >= t.warn_distance:
		return 0.0
	return clampf((t.warn_distance - distance) / maxf(t.warn_distance - t.notice_distance, 0.01), 0.0, 1.0)


static func notices(distance: float, t: ProximityTuning = TUNING) -> bool:
	return distance <= t.notice_distance


## `can_chase`: a chaser kind that may chase tonight, where a chase makes
## sense; `safe`: Rin already stands somewhere safe (it only shows its face).
static func reaction(can_chase: bool, scare_ok: bool, safe: bool) -> Reaction:
	if can_chase and not safe:
		return Reaction.CHASE
	return Reaction.SCARE if scare_ok else Reaction.VANISH


## Ghosts warn: a chase only ever drives Rin away from the water. Near the
## shore (`near_water`) the chaser must come from the sea side (village -Z
## is the sea), so he runs landward, home / to the lamps. Elsewhere any side.
static func pushes_landward(chaser_z: float, rin_z: float, near_water: bool, margin: float = 0.5) -> bool:
	return not near_water or chaser_z <= rin_z + margin


## Uncanny effects never touch a node marked `uncanny_skip` (or under one):
## e.g. chú Bảy, the dead regular, who must never be a phenomenon.
static func skipped(node: Node) -> bool:
	while node:
		if node.get_meta(SKIP_META, false) == true:
			return true
		node = node.get_parent()
	return false


## Seconds to outlast this chase (same loop + day = same length).
static func chase_seconds(loop: int, day: int, t: ProximityTuning = TUNING) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([SALT, loop, day])
	return rng.randf_range(t.chase_seconds_min, t.chase_seconds_max)


## The chaser's motion, one frame at a time.
class Runner:
	var tuning: ProximityTuning
	var unseen_for := 0.0
	var since_dash := 999.0

	func _init(t: ProximityTuning = TUNING) -> void:
		tuning = t

	## {"move": metres towards Rin this frame, "dash": true when it is a dash}.
	func step(seen: bool, delta: float) -> Dictionary:
		since_dash += delta
		if seen:
			unseen_for = 0.0
			return {"move": 0.0, "dash": false}
		unseen_for += delta
		if unseen_for >= tuning.dash_after_unseen and since_dash >= tuning.dash_cooldown:
			since_dash = 0.0
			return {"move": tuning.dash_distance, "dash": true}
		return {"move": tuning.unseen_speed * delta, "dash": false}
